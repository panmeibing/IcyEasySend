import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../models/transfer_history.dart';
import '../../utils/constants.dart';
import '../../utils/disk_space_error.dart';
import '../../utils/error_messages.dart';
import '../../utils/log_util.dart';
import '../../utils/transfer_status_provider.dart';
import '../batch_receive_manager.dart';
import '../disk_full_notifier.dart';
import '../file_transfer_service.dart';
import '../identity_service.dart';
import '../paired_device_store.dart';
import '../preferences_service.dart';
import '../transfer/transfer_history_manager.dart';
import 'relay_client.dart';
import 'relay_crypto.dart';
import 'relay_crypto_worker.dart';
import 'relay_frame_codec.dart';
import 'relay_protocol.dart';
import '../transfer/transfer_http.dart';
import 'resume_store.dart';

/// Machine-readable reasons a manifest can be turned down.
///
/// Codes rather than sentences, because the message is shown on the *sender's*
/// screen and has to be rendered in the sender's language.
class RelayRejectReason {
  static const String notPaired = 'not_paired';
  static const String noUi = 'no_ui';
  static const String busy = 'busy';
  static const String declined = 'declined';
  static const String badIdentity = 'bad_identity';

  const RelayRejectReason._();
}

/// The inbound half of relayed transfers.
///
/// Mirrors what `FileTransferHandler` does for the LAN — decide, confirm with
/// the user, write the bytes, record history — but driven by relay messages
/// instead of HTTP requests. The user-facing parts are deliberately the same
/// objects: the same confirmation dialog, the same [FileReceiver] save logic,
/// the same history store, so a relayed transfer is indistinguishable from a
/// local one once it is accepted.
///
/// The order of events is what keeps an unauthenticated peer from reaching the
/// user: a session offer only becomes a session if the sender is paired, and
/// the session only becomes a dialog if the manifest carries a signature over
/// the handshake made by the key that was paired with. Everything after the
/// offer is encrypted, so a relay that forwards the messages learns neither
/// the file names nor the decision.
///
/// One policy still differs from the LAN: `PairedDevice.autoAccept` is not
/// honoured. Signatures now make it safe in principle, but nothing in the app
/// can turn it on yet, so reading it would only add an untested path.
class RelayReceiveCoordinator {
  final RelayClient _client;
  final BatchReceiveManager _batchReceiveManager;
  final FileTransferService _fileTransferService;
  final TransferHistoryManager _historyManager;
  final PairedDeviceStore _pairedDevices;
  final PreferencesService _preferencesService;
  final IdentityService _identity;
  final ResumeStore _resumeStore;
  final Dio Function(int fileSize)? _dioFactory;

  /// Supplied by `HTTPServerManager`, exactly as for the LAN handlers.
  final BuildContext? Function()? contextGetter;
  final bool Function()? isInBackgroundGetter;
  final VoidCallback? Function()? historyRefreshCallbackGetter;

  final String logTag = LogTags.transfer;

  final Map<String, _ReceiveSession> _sessions = {};
  final Map<String, Future<void>> _offerChains = {};
  StreamSubscription<RelayInboundPayload>? _subscription;

  RelayReceiveCoordinator({
    required RelayClient client,
    this.contextGetter,
    this.isInBackgroundGetter,
    this.historyRefreshCallbackGetter,
    BatchReceiveManager? batchReceiveManager,
    FileTransferService? fileTransferService,
    TransferHistoryManager? historyManager,
    PairedDeviceStore? pairedDevices,
    PreferencesService? preferencesService,
    IdentityService? identity,
    ResumeStore? resumeStore,
    Dio Function(int fileSize)? dioFactory,
  }) : _client = client,
       _batchReceiveManager = batchReceiveManager ?? BatchReceiveManager(),
       _fileTransferService = fileTransferService ?? FileTransferService(),
       _historyManager = historyManager ?? TransferHistoryManager(),
       _pairedDevices = pairedDevices ?? PairedDeviceStore.instance,
       _preferencesService = preferencesService ?? PreferencesService(),
       _identity = identity ?? IdentityService.instance,
       _resumeStore = resumeStore ?? ResumeStore(),
       _dioFactory = dioFactory;

  void start() {
    if (_subscription != null) {
      return;
    }
    _subscription = _client.payloads.listen(_onPayload);

    // Leftovers from transfers nobody retried. Swept here rather than on a
    // timer because this is the only moment the app is known to care about
    // relayed files at all.
    unawaited(_resumeStore.sweep());
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    for (final session in _sessions.values.toList()) {
      await _abandon(session, '中转连接已断开');
    }
    _sessions.clear();
  }

  void _onPayload(RelayInboundPayload inbound) {
    switch (inbound.payload['type']) {
      case RelayPayloadType.transferOffer:
        _enqueueOffer(inbound);
      case RelayPayloadType.transferManifest:
        unawaited(_onManifest(inbound));
      case RelayPayloadType.fileBegin:
        unawaited(_onFileBegin(inbound));
      case RelayPayloadType.transferCancel:
        unawaited(_onCancel(inbound));
    }
  }

  /// Serializes offers from the same peer so two rapid requests cannot both
  /// pass the busy check before either registers a session.
  void _enqueueOffer(RelayInboundPayload inbound) {
    final peer = inbound.fromDeviceId;
    final previous = _offerChains[peer] ?? Future<void>.value();
    final current = previous.then((_) => _onOffer(inbound));
    _offerChains[peer] = current;
    unawaited(
      current
          .catchError((Object error, StackTrace stack) {
            LogUtil.eTag(logTag, '处理中转传输请求失败: $error', error, stack);
          })
          .whenComplete(() {
            if (identical(_offerChains[peer], current)) {
              _offerChains.remove(peer);
            }
          }),
    );
  }

  // -- handshake ------------------------------------------------------------

  /// Answers a session offer, or turns it down in the clear.
  ///
  /// Everything that could refuse the transfer is checked here, before any key
  /// agreement: an unpaired device gets a refusal rather than a session, and a
  /// device that arrives while another batch is on screen is told to wait
  /// instead of silently queueing behind it.
  Future<void> _onOffer(RelayInboundPayload inbound) async {
    final offer = TransferOffer.tryParse(inbound.payload);
    if (offer == null) {
      LogUtil.wTag(logTag, '收到无法解析的中转会话请求');
      return;
    }

    final peerDeviceId = inbound.fromDeviceId;
    final paired = await _pairedDevices.find(peerDeviceId);
    final peerPublicKey = paired == null
        ? null
        : IdentityService.decodePublicKey(paired.publicKey);
    if (paired == null || peerPublicKey == null) {
      LogUtil.wTag(logTag, '拒绝未配对设备的中转传输: ${_short(peerDeviceId)}');
      await _reject(
        peerDeviceId,
        offer.sessionId,
        RelayRejectReason.notPaired,
      );
      return;
    }

    // One batch at a time per peer, matching the pairing dialog's rule: two
    // stacked confirmation dialogs for the same sender cannot be reasoned
    // about by the user.
    if (_sessions.values.any((s) => s.peerDeviceId == peerDeviceId)) {
      await _reject(peerDeviceId, offer.sessionId, RelayRejectReason.busy);
      return;
    }

    // On iOS the app not being in front is the normal state, which decision
    // D1 accepts for v1.
    if (!_hasUsableUi()) {
      LogUtil.wTag(logTag, '无可用界面，拒绝中转传输: ${_short(peerDeviceId)}');
      await _reject(peerDeviceId, offer.sessionId, RelayRejectReason.noUi);
      return;
    }

    final answered = await RelayCrypto.answerOffer(
      offer: offer,
      senderDeviceId: peerDeviceId,
      receiverDeviceId: await _identity.getDeviceId(),
      identity: _identity,
    );
    if (!answered.isSuccess) {
      await _reject(
        peerDeviceId,
        offer.sessionId,
        RelayRejectReason.badIdentity,
      );
      return;
    }

    final session = _ReceiveSession(
      sessionId: offer.sessionId,
      peerDeviceId: peerDeviceId,
      senderKey: '${AppConstants.relayHistoryPeerIp}:${_short(peerDeviceId)}',
      senderDeviceName: paired.deviceName,
      secure: answered.data!.session,
      senderPublicKey: peerPublicKey,
    );

    // A handshake that never turns into a manifest would otherwise hold the
    // peer's slot until the connection drops.
    session.watchdog = Timer(
      AppConstants.relayManifestTimeout,
      () => unawaited(_abandon(session, '对方没有发送文件清单')),
    );

    _sessions[session.sessionId] = session;
    _client.sessions.add(answered.data!.session);

    await _client.sendPayload(
      toDeviceId: peerDeviceId,
      payload: answered.data!.answer.toJson(),
    );
  }

  // -- manifest -------------------------------------------------------------

  Future<void> _onManifest(RelayInboundPayload inbound) async {
    final manifest = TransferManifest.tryParse(inbound.payload);
    if (manifest == null) {
      LogUtil.wTag(logTag, '收到无法解析的中转文件清单');
      return;
    }

    final peerDeviceId = inbound.fromDeviceId;
    final session = _sessions[manifest.sessionId];
    if (session == null || session.peerDeviceId != peerDeviceId) {
      LogUtil.wTag(logTag, '收到与会话不匹配的中转文件清单');
      return;
    }
    if (session.pending.isNotEmpty) {
      // A second manifest on a live session would replace the list the user
      // is looking at with one they never saw.
      LogUtil.wTag(logTag, '忽略重复的中转文件清单: ${_short(peerDeviceId)}');
      return;
    }

    // The signature is what ties the encrypted session to a known device. The
    // relay chose the `from` on the envelope; only the paired key could have
    // signed this transcript.
    final authentic = await RelayCrypto.verifySenderSignature(
      transcript: session.secure.transcript,
      signature: manifest.signature,
      senderPublicKey: session.senderPublicKey,
    );
    if (!authentic) {
      LogUtil.wTag(logTag, '中转文件清单签名无效，中止会话: ${_short(peerDeviceId)}');
      await _rejectSession(session, RelayRejectReason.badIdentity);
      return;
    }

    // The relay never learns device names (decision D3), so the only way a
    // rename propagates is by riding along with a transfer.
    if (manifest.senderDeviceName.isNotEmpty) {
      await _pairedDevices.touch(
        peerDeviceId,
        deviceName: manifest.senderDeviceName,
      );
    }

    // Read late, so the decision is made on the freshest possible view of
    // whether there is anyone to ask.
    final context = (isInBackgroundGetter?.call() ?? false)
        ? null
        : contextGetter?.call();
    if (context == null || !context.mounted) {
      LogUtil.wTag(logTag, '无可用界面，拒绝中转传输: ${_short(peerDeviceId)}');
      await _rejectSession(session, RelayRejectReason.noUi);
      return;
    }

    final senderName = manifest.senderDeviceName.isNotEmpty
        ? manifest.senderDeviceName
        : session.senderDeviceName ?? '';
    session.senderDeviceName = senderName;

    for (final file in manifest.files) {
      session.pending[file.fileId] = PendingFileInfo(
        fileName: file.name,
        fileSize: file.size,
        senderIP: session.senderKey,
        senderDeviceName: senderName,
        completer: Completer<bool>(),
        transferId: '${manifest.sessionId}_${file.fileId}',
      );
    }

    // The user is being asked about a specific list of files; anything that
    // arrives later must be checked against it rather than the other way
    // round, so the watchdog covers the dialog too.
    session.restartWatchdog(
      () => unawaited(_abandon(session, '对方长时间没有发送文件')),
    );

    final accepted = await _batchReceiveManager.requestBatchReceiveConfirmation(
      context: context,
      files: session.pending.values.toList(),
      senderIP: session.senderKey,
      senderDeviceName: senderName,
      onComplete: () => _finish(session),
    );

    if (!accepted) {
      await _rejectSession(session, RelayRejectReason.declined);
      return;
    }

    // Files that never show up would otherwise leave the progress dialog open
    // forever, which on a flaky public path is a matter of when, not if.
    session.restartWatchdog(
      () => unawaited(_abandon(session, '对方长时间没有发送文件')),
    );

    await _send(
      session,
      TransferAccept(
        sessionId: session.sessionId,
        accepted: true,
        receiverDeviceName: await _localDeviceName(),
        files: await _resumePoints(manifest.files),
      ).toJson(),
    );
  }

  /// Looks up what an earlier attempt at each file left behind.
  ///
  /// Only ever a hint: the sender re-reads its own copy of the chunk the hash
  /// describes before it agrees to skip anything.
  Future<List<AcceptedFile>> _resumePoints(List<ManifestFile> files) async {
    final accepted = <AcceptedFile>[];

    for (final file in files) {
      final point = await _resumeStore.inspect(
        fileId: file.fileId,
        size: file.size,
        chunkCount: FileBegin.chunkCountFor(file.size),
      );
      accepted.add(
        AcceptedFile(
          fileId: file.fileId,
          resumeFromChunk: point.isUsable ? point.resumeFromChunk : 0,
          lastChunkHash: point.isUsable ? point.lastChunkHash : null,
        ),
      );
    }

    return accepted;
  }

  /// Turns down an offer before any keys exist, so this one goes in the clear.
  ///
  /// It says only which of a handful of fixed reasons applied, which is what
  /// the sender needs to show a useful message and nothing more than the relay
  /// could already infer from the traffic.
  Future<void> _reject(
    String peerDeviceId,
    String sessionId,
    String reason,
  ) async {
    await _client.sendPayload(
      toDeviceId: peerDeviceId,
      payload: TransferAccept(
        sessionId: sessionId,
        accepted: false,
        reason: reason,
      ).toJson(),
    );
  }

  /// Turns down an established session and tears it down.
  Future<void> _rejectSession(_ReceiveSession session, String reason) async {
    _forget(session);
    await _send(
      session,
      TransferAccept(
        sessionId: session.sessionId,
        accepted: false,
        reason: reason,
      ).toJson(),
    );
  }

  /// Sends an application message under the session's keys.
  Future<void> _send(
    _ReceiveSession session,
    Map<String, dynamic> payload,
  ) async {
    await _client.sendPayload(
      toDeviceId: session.peerDeviceId,
      payload: await session.secure.seal(payload),
    );
  }

  bool _hasUsableUi() {
    if (isInBackgroundGetter?.call() ?? false) {
      return false;
    }
    final context = contextGetter?.call();
    return context != null && context.mounted;
  }

  // -- file transfer --------------------------------------------------------

  Future<void> _onFileBegin(RelayInboundPayload inbound) async {
    final begin = FileBegin.tryParse(inbound.payload);
    if (begin == null) {
      return;
    }

    final session = _sessions[begin.sessionId];
    if (session == null || session.peerDeviceId != inbound.fromDeviceId) {
      // Nothing to answer with: without the session there are no keys, and a
      // plaintext failure here would be one the peer could not trust anyway.
      LogUtil.wTag(logTag, '收到与会话不匹配的中转文件开始消息');
      return;
    }
    if (session.pending.isEmpty) {
      LogUtil.wTag(logTag, '收到清单确认之前的中转文件开始消息');
      return;
    }

    final info = session.pending[begin.fileId];
    if (info == null) {
      await _reportDone(
        session,
        begin.fileId,
        ok: false,
        error: '该文件不在已确认的清单中',
      );
      return;
    }
    // The size was shown to the user in the confirmation dialog, so a stream
    // that claims a different one is not the file they agreed to.
    if (begin.size != info.fileSize) {
      await _reportDone(
        session,
        begin.fileId,
        ok: false,
        error: '文件大小与已确认的清单不一致',
      );
      return;
    }

    // A retry arrives as a second `file.begin` for the same file. Two at once
    // would have both attempts writing the same partial file.
    if (!session.receiving.add(begin.fileId)) {
      LogUtil.wTag(logTag, '忽略重复到达的中转文件开始消息: ${begin.fileId}');
      return;
    }

    session.restartWatchdog(() => unawaited(_abandon(session, '接收超时')));

    final _ReceiveOutcome result;
    try {
      result = await _download(session, begin, info);
    } finally {
      session.receiving.remove(begin.fileId);
    }

    // Keyed by file, so a retry replaces the failed attempt's entry instead of
    // leaving the user with one line per attempt.
    session.histories[begin.fileId] = _historyManager.createTransferHistory(
      fileName: info.fileName,
      fileSize: info.fileSize,
      targetIP: AppConstants.relayHistoryPeerIp,
      success: result.ok,
      isReceived: true,
      deviceName: session.senderDeviceName,
      savedPath: result.savedPath,
    );

    if (result.ok) {
      _batchReceiveManager.updateProgress(
        info.transferId,
        1.0,
        info.fileSize,
        info.fileSize,
      );
    } else if (result.resumeFromChunk == null) {
      _batchReceiveManager.markTransferFailed(
        info.transferId,
        result.error ?? '接收失败',
      );
    }
    // A failure that kept its bytes leaves the progress bar where it stopped:
    // the sender is about to retry, and showing "failed" in between would be
    // contradicted a second later. If no retry comes, the watchdog ends it.

    await _reportDone(
      session,
      begin.fileId,
      ok: result.ok,
      bytes: result.ok ? info.fileSize : 0,
      resumeFromChunk: result.resumeFromChunk,
      error: result.error,
    );
  }

  /// Pulls one file off the relay and writes it to its partial file.
  ///
  /// The bytes are decrypted on the way to disk, so what gets written is the
  /// plaintext of exactly the length the manifest promised. A stream that has
  /// been cut short, padded or altered fails here rather than becoming a
  /// damaged file in the user's downloads.
  ///
  /// Writing is done here rather than through
  /// [FileTransferService.receiveFileDirectly] because resuming needs to count
  /// in chunks, and only this side of the codec knows where chunks end. Once
  /// the last one lands, the finished file is handed to the ordinary save path
  /// so it ends up where any other transfer would have put it.
  Future<_ReceiveOutcome> _download(
    _ReceiveSession session,
    FileBegin begin,
    PendingFileInfo info,
  ) async {
    final uri = _client.streamUri(begin.streamId);
    if (uri == null) {
      return const _ReceiveOutcome.failure('中转服务器地址无效');
    }

    final writer = await _resumeStore.openAt(
      fileId: begin.fileId,
      size: info.fileSize,
      startChunk: begin.startChunk,
    );
    if (writer == null) {
      // Either there is nowhere to write, or the sender is resuming from
      // further along than this device ever got. Both are worth restating
      // from the beginning rather than failing outright, but the sender is
      // the one that decides that, so say what happened and let it choose.
      return const _ReceiveOutcome.failure('无法从该断点继续接收');
    }

    final dio =
        _dioFactory?.call(info.fileSize) ??
        TransferHttp.createForDownload(info.fileSize);
    try {
      final response = await dio.get<ResponseBody>(
        uri.toString(),
        options: Options(
          headers: await _client.streamHeaders(begin.streamId),
          responseType: ResponseType.stream,
          validateStatus: (status) => status != null,
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        return _ReceiveOutcome.retryable(
          '无法读取中转数据流\n状态码: ${response.statusCode}',
          await writer.abandon(),
        );
      }

      final codec = await session.codec;
      final plaintext = codec.decrypt(
        response.data!.stream,
        await session.secure.keys.fileKey(
          begin.fileId,
          attempt: begin.attempt,
        ),
        chunkCount: begin.chunkCount,
        startChunk: begin.startChunk,
      );

      await for (final chunk in plaintext) {
        await writer.add(chunk);
        _batchReceiveManager.updateProgress(
          info.transferId,
          info.fileSize == 0 ? 1.0 : writer.bytesWritten / info.fileSize,
          writer.bytesWritten,
          info.fileSize,
        );
        session.restartWatchdog(() => unawaited(_abandon(session, '接收超时')));
      }

      if (writer.bytesWritten != info.fileSize) {
        await writer.discard();
        return _ReceiveOutcome.failure(
          '接收到的字节数与清单不一致: ${writer.bytesWritten}/${info.fileSize}',
        );
      }

      final saved = await _fileTransferService.adoptReceivedFile(
        source: await writer.complete(),
        fileName: info.fileName,
        fileSize: info.fileSize,
      );
      if (!saved.isSuccess) {
        await writer.discard();
        if (saved.isDiskFull) {
          unawaited(DiskFullNotifier().notify(contextGetter?.call()));
        }
        return _ReceiveOutcome.failure(saved.errorMessage ?? '接收失败');
      }

      await _resumeStore.discard(begin.fileId);
      return _ReceiveOutcome.success(saved.data?.savedPath);
    } on DioException catch (e) {
      LogUtil.wTag(logTag, '中转下载失败 ${info.fileName}: ${e.message}');
      return _ReceiveOutcome.retryable(
        TransferHttp.describeFailure(
          e,
          transport: TransferTransport.relay,
          verb: '下载',
        ),
        await writer.abandon(),
      );
    } on RelayCryptoException catch (e) {
      // Not resumable: what is on disk was written under keys that produced a
      // stream this device could not verify, so none of it can be vouched for.
      LogUtil.wTag(logTag, '中转数据流校验失败 ${info.fileName}: $e');
      await writer.discard();
      return _ReceiveOutcome.failure('文件在传输中被改动或截断，已丢弃: $e');
    } on FileSystemException catch (e) {
      LogUtil.wTag(logTag, '中转接收写入失败 ${info.fileName}: ${e.message}');
      await writer.discard();
      // Not retryable: retrying into a disk that is still full only burns the
      // sender's attempts, so say why and stop.
      if (DiskSpaceError.isDiskFull(e)) {
        LogUtil.eTag(logTag, '磁盘空间不足，已中止中转接收: ${info.fileName}');
        unawaited(DiskFullNotifier().notify(contextGetter?.call()));
        return _ReceiveOutcome.failure(ErrorMessages.storageInsufficient);
      }
      return _ReceiveOutcome.failure('文件保存失败\n错误: ${e.message}');
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '中转下载异常 ${info.fileName}: $e', e, stackTrace);
      return _ReceiveOutcome.retryable(
        '中转下载异常: $e',
        await writer.abandon(),
      );
    } finally {
      dio.close();
    }
  }

  Future<void> _reportDone(
    _ReceiveSession session,
    String fileId, {
    required bool ok,
    int bytes = 0,
    int? resumeFromChunk,
    String? error,
  }) async {
    await _send(
      session,
      FileDone(
        sessionId: session.sessionId,
        fileId: fileId,
        ok: ok,
        bytes: bytes,
        resumeFromChunk: resumeFromChunk,
        error: error,
      ).toJson(),
    );
  }

  // -- session lifecycle ----------------------------------------------------

  Future<void> _onCancel(RelayInboundPayload inbound) async {
    final cancel = TransferCancel.tryParse(inbound.payload);
    if (cancel == null) {
      return;
    }
    final session = _sessions[cancel.sessionId];
    if (session == null || session.peerDeviceId != inbound.fromDeviceId) {
      return;
    }
    await _abandon(session, '对方取消了传输');
  }

  /// Called by the dialog once it closes, whichever way the batch ended.
  Future<void> _finish(_ReceiveSession session) async {
    _forget(session);
    _batchReceiveManager.clearPendingForSender(session.senderKey);

    if (session.histories.isNotEmpty) {
      await _historyManager.saveTransferHistoryBatch(
        session.histories.values.toList(),
      );
      historyRefreshCallbackGetter?.call()?.call();
    }
  }

  /// Drops a session and everything derived from it.
  ///
  /// The keys go with it: they are worth nothing once the batch is over, and
  /// leaving them registered would keep a window open for a later message.
  void _forget(_ReceiveSession session) {
    _sessions.remove(session.sessionId);
    _client.sessions.remove(session.sessionId);
    unawaited(session.dispose());
  }

  /// Ends a session that cannot finish normally, releasing the dialog.
  Future<void> _abandon(_ReceiveSession session, String reason) async {
    session.watchdog?.cancel();
    if (!_sessions.containsKey(session.sessionId)) {
      return;
    }

    LogUtil.wTag(logTag, '中转接收会话中止: $reason');
    for (final info in session.pending.values) {
      if (!info.isCompleted) {
        _batchReceiveManager.markTransferFailed(info.transferId, reason);
      }
    }
    await _finish(session);
  }

  // -- helpers --------------------------------------------------------------

  Future<String> _localDeviceName() async {
    final name = await _preferencesService.getDeviceName();
    return name ?? '';
  }

  /// Translates a peer's rejection code for display on this device.
  ///
  /// Lives here beside the codes it mirrors, and is used by `RelayChannel` on
  /// the sending side.
  static String describeRejection(
    String? reason,
    TransferStatusProvider statusProvider,
  ) {
    switch (reason) {
      case RelayRejectReason.notPaired:
        return statusProvider.relayPeerNotPaired;
      case RelayRejectReason.noUi:
        return statusProvider.relayPeerOffline;
      case RelayRejectReason.busy:
        return statusProvider.relayPeerBusy;
      case RelayRejectReason.declined:
      case null:
        return statusProvider.receiverRejected;
      default:
        return reason;
    }
  }

  static String _short(String deviceId) =>
      deviceId.length <= 8 ? deviceId : deviceId.substring(0, 8);
}

/// One batch from one peer, from the session offer to the last file.
class _ReceiveSession {
  final String sessionId;
  final String peerDeviceId;

  /// Key the shared [BatchReceiveManager] groups this batch under. It doubles
  /// as the "address" shown in the confirmation dialog, so it is readable
  /// rather than a bare 32-character fingerprint.
  final String senderKey;

  /// Keys for this session, and the transcript the peer has to have signed.
  final RelaySecureSession secure;

  /// The paired public key the manifest's signature is checked against.
  final Uint8List senderPublicKey;

  /// Starts as the name in the trust list and is refreshed by the manifest.
  String? senderDeviceName;

  final Map<String, PendingFileInfo> pending = {};

  /// One entry per file, replaced when a retry supersedes a failed attempt.
  final Map<String, TransferHistory> histories = {};

  /// Files with a download in progress, so a retry cannot start on top of one.
  final Set<String> receiving = {};

  Timer? watchdog;

  RelayCryptoWorker? _worker;
  Future<RelayFrameCodec>? _codec;

  _ReceiveSession({
    required this.sessionId,
    required this.peerDeviceId,
    required this.senderKey,
    required this.secure,
    required this.senderPublicKey,
    this.senderDeviceName,
  });

  /// Decryption for this session's files.
  ///
  /// Spawned on first use and shared by every file in the batch: a session
  /// that is offered and then refused never pays for an isolate, and a batch
  /// of two hundred files pays for exactly one.
  Future<RelayFrameCodec> get codec {
    return _codec ??= RelayCryptoWorker.spawn().then((worker) {
      _worker = worker;
      return RelayFrameCodec(worker: worker);
    });
  }

  /// Restarts the stall timer. Progress counts as liveness, so a slow but
  /// moving transfer is never cut off.
  void restartWatchdog(void Function() onTimeout) {
    watchdog?.cancel();
    watchdog = Timer(AppConstants.relayReceiveIdleTimeout, onTimeout);
  }

  Future<void> dispose() async {
    watchdog?.cancel();
    watchdog = null;

    // A session torn down while the isolate is still starting would otherwise
    // leave it running with nothing left holding a reference to stop it.
    final starting = _codec;
    _codec = null;
    if (starting != null) {
      try {
        await starting;
      } catch (_) {
        // Nothing to shut down if it never started.
      }
    }

    await _worker?.dispose();
    _worker = null;
  }
}

class _ReceiveOutcome {
  final bool ok;
  final String? savedPath;
  final String? error;

  /// Set when the attempt failed but what arrived is still worth keeping, and
  /// names the chunk a retry may start from.
  final int? resumeFromChunk;

  const _ReceiveOutcome.success(this.savedPath)
    : ok = true,
      error = null,
      resumeFromChunk = null;

  const _ReceiveOutcome.failure(this.error)
    : ok = false,
      savedPath = null,
      resumeFromChunk = null;

  const _ReceiveOutcome.retryable(this.error, this.resumeFromChunk)
    : ok = false,
      savedPath = null;
}
