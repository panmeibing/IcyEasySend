import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/transfer_data.dart';
import '../models/transfer_file_item.dart';
import '../models/transfer_history.dart';
import '../services/identity_service.dart';
import '../services/paired_device_store.dart';
import '../services/preferences_service.dart';
import '../services/relay/relay_client.dart';
import '../services/relay/relay_crypto.dart';
import '../services/relay/relay_crypto_worker.dart';
import '../services/relay/relay_frame_codec.dart';
import '../services/relay/relay_protocol.dart';
import '../services/relay/relay_receive_coordinator.dart';
import '../services/transfer/transfer_http.dart';
import '../services/transfer/transfer_history_manager.dart';
import '../utils/constants.dart';
import '../utils/log_util.dart';
import '../utils/operation_result.dart';
import '../utils/transfer_status_provider.dart';
import 'transport_channel.dart';

/// Transfer forwarded through the user's relay server.
///
/// The shape of a transfer mirrors the LAN channel — offer everything, wait for
/// one decision, then upload file by file — so the two produce the same
/// results and the same history entries. What differs is the plumbing: the
/// handshake travels as application messages over the signaling socket, and
/// each file gets its own short-lived HTTP stream through the relay.
///
/// Inbound transfers are not handled here. As on the LAN, where the shelf
/// server owns the receive side, that belongs to `RelayReceiveCoordinator`.
///
/// Everything past the opening handshake is encrypted end to end. The relay
/// sees a session id, two ephemeral public keys and a count of bytes; the file
/// names, sizes and contents are unreadable to it.
class RelayChannel implements TransportChannel {
  final RelayClient _client;
  final PreferencesService _preferencesService;
  final TransferHistoryManager _historyManager;
  final TransferStatusProvider _statusProvider;
  final PairedDeviceStore _pairedDevices;
  final IdentityService _identity;
  final Dio Function(int fileSize)? _dioFactory;
  final String logTag = LogTags.transfer;

  RelayChannel({
    required RelayClient client,
    PreferencesService? preferencesService,
    TransferHistoryManager? historyManager,
    TransferStatusProvider? statusProvider,
    PairedDeviceStore? pairedDevices,
    IdentityService? identity,
    Dio Function(int fileSize)? dioFactory,
  }) : _client = client,
       _preferencesService = preferencesService ?? PreferencesService(),
       _historyManager = historyManager ?? TransferHistoryManager(),
       _statusProvider = statusProvider ?? TransferStatusProvider(),
       _pairedDevices = pairedDevices ?? PairedDeviceStore.instance,
       _identity = identity ?? IdentityService.instance,
       _dioFactory = dioFactory;

  @override
  TransportKind get kind => TransportKind.relay;

  /// The connection is owned by `RelayService`, which keeps it up for the
  /// receive side too, so there is nothing for the channel to bring up.
  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<ProbeResult> probe(PeerRef peer, {Duration? timeout}) async {
    final deviceId = peer.deviceId;
    if (deviceId == null) {
      return ProbeResult.unavailable(
        kind: kind,
        errorMessage: _statusProvider.relayNeedsPairedDevice,
      );
    }
    if (!_client.config.isActive) {
      return ProbeResult.unavailable(
        kind: kind,
        errorMessage: _statusProvider.relayNotConnected,
      );
    }

    final stopwatch = Stopwatch()..start();
    if (!_client.isConnected) {
      try {
        final connected = await _client.connect().timeout(
          timeout ?? AppConstants.relayProbeTimeout,
        );
        if (!connected) {
          stopwatch.stop();
          return ProbeResult.unreachable(
            kind: kind,
            errorMessage: _statusProvider.relayNotConnected,
          );
        }
      } on TimeoutException {
        stopwatch.stop();
        return ProbeResult.unreachable(
          kind: kind,
          errorMessage: _statusProvider.relayNotConnected,
        );
      }
    }
    stopwatch.stop();

    // Presence is pushed by the server, so this needs no round trip. The
    // elapsed time therefore says nothing about the path to the peer, which
    // is why relay is a fallback rather than something raced against the LAN.
    if (!_client.isOnline(deviceId)) {
      return ProbeResult.unreachable(
        kind: kind,
        errorMessage: _statusProvider.relayPeerOffline,
      );
    }

    return ProbeResult.reachable(
      kind: kind,
      rtt: stopwatch.elapsed,
      deviceName: peer.deviceName,
    );
  }

  @override
  Future<Map<String, OperationResult<TransferData>>> sendFiles({
    required PeerRef peer,
    required List<TransferFileItem> files,
    String? secretKey,
    TransferProgressCallback? onProgress,
    FileProgressCallback? onFileProgress,
    void Function(String status)? onStatusChange,
    VoidCallback? onHistoryUpdated,
  }) async {
    final deviceId = peer.deviceId;
    if (deviceId == null) {
      LogUtil.wTag(logTag, 'sendFiles() peer has no device id: $peer');
      return _failAll(files, _statusProvider.relayNeedsPairedDevice);
    }

    // The peer's long-term key is what the handshake is checked against, so a
    // device that was never paired cannot be sent to at all.
    final paired = await _pairedDevices.find(deviceId);
    final peerPublicKey = paired == null
        ? null
        : IdentityService.decodePublicKey(paired.publicKey);
    if (peerPublicKey == null) {
      return _failAll(files, _statusProvider.relayPeerNotPaired);
    }

    onStatusChange?.call(_statusProvider.checkingTargetDevice);
    if (!_client.isConnected && !await _client.connect()) {
      return _failAll(files, _statusProvider.relayNotConnected);
    }

    onStatusChange?.call(_statusProvider.preparingTransferInfo);
    final entries = await _describeFiles(deviceId, files);
    final totalBytes = entries.fold<int>(0, (sum, entry) => sum + entry.size);
    final sessionId = _randomHex(16);

    onStatusChange?.call(_statusProvider.relayNegotiatingSession);
    final established = await _establishSession(
      peerDeviceId: deviceId,
      sessionId: sessionId,
      peerPublicKey: peerPublicKey,
    );
    if (!established.isSuccess) {
      return _failAll(files, established.errorMessage!);
    }
    final session = established.data!;

    RelayCryptoWorker? worker;
    var notifyCancel = true;
    try {
      final accept = await _offer(
        session: session,
        entries: entries,
        onStatusChange: onStatusChange,
      );
      if (!accept.isSuccess) {
        return _failAll(files, accept.errorMessage!);
      }

      final acceptedFiles = {
        for (final file in accept.data!.files) file.fileId: file,
      };
      onStatusChange?.call(_statusProvider.relayTransferNotice);

      worker = await RelayCryptoWorker.spawn();
      final codec = RelayFrameCodec(worker: worker);

      final results = <String, OperationResult<TransferData>>{};
      final histories = <TransferHistory>[];
      var sentBytes = 0;

      // Sequential, unlike the LAN channel: the relay is a shared uplink, and
      // several parallel streams through it would only divide the same
      // bandwidth while multiplying the server's memory footprint.
      for (var index = 0; index < entries.length; index++) {
        final entry = entries[index];
        final completedBefore = sentBytes;

        final result = acceptedFiles.containsKey(entry.fileId)
            ? await _sendOne(
                session: session,
                codec: codec,
                entry: entry,
                accepted: acceptedFiles[entry.fileId]!,
                onStatusChange: onStatusChange,
                onFileBytes: (bytes) {
                  onFileProgress?.call(
                    index,
                    entry.size == 0 ? 1.0 : bytes / entry.size,
                    bytes,
                    entry.size,
                  );
                  if (totalBytes > 0) {
                    final overall = completedBefore + bytes;
                    onProgress?.call(overall / totalBytes, overall, totalBytes);
                  }
                },
              )
            : OperationResult<TransferData>.failure(
                _statusProvider.receiverRejected,
              );

        sentBytes += entry.size;
        results[entry.item.transferName] = result;
        histories.add(
          _historyManager.createTransferHistory(
            fileName: entry.item.transferName,
            fileSize: entry.size,
            targetIP: AppConstants.relayHistoryPeerIp,
            success: result.isSuccess,
            isReceived: false,
            deviceName: accept.data!.receiverDeviceName.isNotEmpty
                ? accept.data!.receiverDeviceName
                : peer.deviceName,
          ),
        );
      }

      if (totalBytes > 0) {
        onProgress?.call(1.0, totalBytes, totalBytes);
      }

      await _historyManager.saveTransferHistoryBatch(histories);
      onHistoryUpdated?.call();

      notifyCancel = false;
      return results;
    } finally {
      if (notifyCancel) {
        await _client.sendPayload(
          toDeviceId: deviceId,
          payload: TransferCancel(
            sessionId: sessionId,
            reason: 'sender_stopped',
          ).toJson(),
        );
      }
      // The keys die with the transfer. Nothing later may be decrypted with
      // them, which is what makes a captured session worthless afterwards.
      _client.sessions.remove(sessionId);
      await worker?.dispose();
    }
  }

  /// Runs the session handshake and registers the resulting keys.
  ///
  /// Until this succeeds nothing about the transfer has been said out loud:
  /// the offer carries an ephemeral key and a random number, and the answer is
  /// only accepted if it is signed by the key this device paired with.
  Future<OperationResult<RelaySecureSession>> _establishSession({
    required String peerDeviceId,
    required String sessionId,
    required Uint8List peerPublicKey,
  }) async {
    final localDeviceId = await _identity.getDeviceId();
    final offer = await RelayCrypto.createOffer(sessionId);

    final reply = await _client.sendAndAwaitReply(
      toDeviceId: peerDeviceId,
      payload: offer.payload.toJson(),
      matches: (payload) =>
          payload['sid'] == sessionId &&
          (payload['type'] == RelayPayloadType.transferAnswer ||
              payload['type'] == RelayPayloadType.transferAccept),
      timeout: AppConstants.relayHandshakeReplyTimeout,
    );
    if (!reply.isSuccess) {
      return OperationResult.failure(reply.errorMessage!);
    }

    // A peer that will not accept the transfer says so in the clear rather
    // than agreeing keys first, so the reason survives to the sender's screen.
    if (reply.data!['type'] == RelayPayloadType.transferAccept) {
      final refusal = TransferAccept.tryParse(reply.data!);
      return OperationResult.failure(
        RelayReceiveCoordinator.describeRejection(
          refusal?.reason,
          _statusProvider,
        ),
      );
    }

    final answer = TransferAnswer.tryParse(reply.data!);
    if (answer == null) {
      return OperationResult.failure('中转会话应答无法解析');
    }

    final session = await RelayCrypto.completeOffer(
      offer: offer,
      answer: answer,
      senderDeviceId: localDeviceId,
      receiverDeviceId: peerDeviceId,
      receiverPublicKey: peerPublicKey,
    );
    if (!session.isSuccess) {
      return OperationResult.failure(session.errorMessage!);
    }

    _client.sessions.add(session.data!);
    return session;
  }

  // -- transfer stages ------------------------------------------------------

  /// Offers the whole batch and waits for the receiver's single decision.
  ///
  /// The manifest is both encrypted and signed: encrypted so the relay does
  /// not learn what is being sent, signed so the receiver can tell who is
  /// asking. Everything after this point rides on the same session.
  Future<OperationResult<TransferAccept>> _offer({
    required RelaySecureSession session,
    required List<_RelayFileEntry> entries,
    void Function(String status)? onStatusChange,
  }) async {
    final deviceName = await _localDeviceName();
    final manifest = TransferManifest(
      sessionId: session.sessionId,
      senderDeviceName: deviceName,
      files: [
        for (final entry in entries)
          ManifestFile(
            fileId: entry.fileId,
            name: entry.item.transferName,
            size: entry.size,
          ),
      ],
      signature: await RelayCrypto.signAsSender(
        session.transcript,
        identity: _identity,
      ),
    );

    onStatusChange?.call(
      _statusProvider.waitingForReceiverConfirmFiles(entries.length),
    );

    final reply = await _client.sendAndAwaitReply(
      toDeviceId: session.peerDeviceId,
      payload: await session.seal(manifest.toJson()),
      matches: (payload) =>
          payload['type'] == RelayPayloadType.transferAccept &&
          payload['sid'] == session.sessionId,
      timeout: AppConstants.relayManifestTimeout,
    );
    if (!reply.isSuccess) {
      return OperationResult.failure(reply.errorMessage!);
    }

    final accept = TransferAccept.tryParse(reply.data!);
    if (accept == null) {
      return OperationResult.failure('中转应答无法解析');
    }
    if (!accept.accepted) {
      return OperationResult.failure(
        RelayReceiveCoordinator.describeRejection(
          accept.reason,
          _statusProvider,
        ),
      );
    }
    return OperationResult.success(data: accept);
  }

  /// Sends one file, retrying from wherever the receiver got to.
  ///
  /// A retry is only attempted when the receiver said in so many words that it
  /// kept what arrived and named the chunk to continue from. Any other failure
  /// ends the file here: without that word there is no way to know whether the
  /// peer is still writing, and a second stream on top of a live one would
  /// interleave two copies of the same file. The partial file survives either
  /// way, so a transfer the user starts again still picks up where this left
  /// off.
  Future<OperationResult<TransferData>> _sendOne({
    required RelaySecureSession session,
    required RelayFrameCodec codec,
    required _RelayFileEntry entry,
    required AcceptedFile accepted,
    required void Function(int bytes) onFileBytes,
    void Function(String status)? onStatusChange,
  }) async {
    if (entry.error != null) {
      return OperationResult.failure(entry.error!);
    }

    var startChunk = await _resolveStartChunk(entry, accepted);

    for (var attempt = 0; ; attempt++) {
      if (attempt > 0) {
        onStatusChange?.call(
          _statusProvider.retryingAfterInterruption(
            attempt,
            AppConstants.relayMaxFileRetries,
          ),
        );
        await Future<void>.delayed(
          AppConstants.relayRetryBackoff[attempt - 1],
        );
      }

      final attemptResult = await _attempt(
        session: session,
        codec: codec,
        entry: entry,
        startChunk: startChunk,
        attempt: attempt,
        onFileBytes: onFileBytes,
      );
      if (attemptResult.result.isSuccess) {
        return attemptResult.result;
      }

      final resume = attemptResult.resumeFromChunk;
      if (resume == null || attempt >= AppConstants.relayMaxFileRetries) {
        return attemptResult.result;
      }

      LogUtil.wTag(
        logTag,
        '中转传输中断，将从第 $resume 块重试 ${entry.item.transferName}',
      );
      startChunk = resume;
    }
  }

  /// Decides where this file actually starts.
  ///
  /// The receiver's offer is checked against the bytes on this device: the
  /// same 64 KiB it hashed is read back and hashed again. A file edited
  /// between attempts fails this and starts over, which is the whole point —
  /// the identifier alone cannot tell an edit from a coincidence.
  Future<int> _resolveStartChunk(
    _RelayFileEntry entry,
    AcceptedFile accepted,
  ) async {
    final resume = accepted.resumeFromChunk;
    final hash = accepted.lastChunkHash;
    if (resume <= 0 || hash == null) {
      return 0;
    }

    // The last frame carries the proof that the stream ended where it should,
    // so it is never skipped however much the receiver already holds.
    if (resume >= FileBegin.chunkCountFor(entry.size)) {
      return 0;
    }

    try {
      final start = (resume - 1) * AppConstants.relayChunkSize;
      final end = min(start + AppConstants.relayChunkSize, entry.size);
      final builder = BytesBuilder(copy: false);
      await for (final piece in entry.item.file.openRead(start, end)) {
        builder.add(piece);
      }

      final digest = await Sha256().hash(builder.takeBytes());
      if (base64Encode(digest.bytes) != hash) {
        LogUtil.iTag(
          logTag,
          '本地文件已改动，放弃断点续传 ${entry.item.transferName}',
        );
        return 0;
      }
      return resume;
    } catch (e) {
      LogUtil.wTag(logTag, '校验断点续传块失败 ${entry.item.transferName}: $e');
      return 0;
    }
  }

  /// Allocates a stream, points the receiver at it, and uploads the bytes.
  Future<_SendAttempt> _attempt({
    required RelaySecureSession session,
    required RelayFrameCodec codec,
    required _RelayFileEntry entry,
    required int startChunk,
    required int attempt,
    required void Function(int bytes) onFileBytes,
  }) async {
    final stream = await _client.createStream(
      peerDeviceId: session.peerDeviceId,
      role: RelayStreamRole.sender,
    );
    if (!stream.isSuccess) {
      return _SendAttempt.failed(stream.errorMessage!);
    }
    final streamId = stream.data!;

    // Armed before the upload starts: a small file can be written and
    // acknowledged by the receiver before the upload's own response arrives.
    final acknowledged = _client.awaitPayload(
      fromDeviceId: session.peerDeviceId,
      matches: (payload) =>
          payload['type'] == RelayPayloadType.fileDone &&
          payload['sid'] == session.sessionId &&
          payload['fileId'] == entry.fileId,
      timeout:
          TransferHttp.transferTimeout(entry.size) +
          AppConstants.relayFileAckTimeout,
    );

    final announced = await _client.sendPayload(
      toDeviceId: session.peerDeviceId,
      payload: await session.seal(
        FileBegin(
          sessionId: session.sessionId,
          fileId: entry.fileId,
          streamId: streamId,
          size: entry.size,
          chunkCount: FileBegin.chunkCountFor(entry.size),
          startChunk: startChunk,
          attempt: attempt,
        ).toJson(),
      ),
    );
    if (!announced.isSuccess) {
      return _SendAttempt.failed(announced.errorMessage!);
    }

    final uploaded = await _upload(
      streamId: streamId,
      entry: entry,
      startChunk: startChunk,
      fileKey: await session.keys.fileKey(entry.fileId, attempt: attempt),
      codec: codec,
      onFileBytes: onFileBytes,
    );
    if (!uploaded.isSuccess) {
      // The receiver saw the same break and is about to say how far it got.
      // Waiting for that is what makes a retry safe: it proves the peer has
      // stopped writing, so a second stream cannot overlap the first.
      return _SendAttempt.failed(
        uploaded.errorMessage!,
        resumeFromChunk: await _resumeOffered(acknowledged),
      );
    }

    // The relay accepting every byte only means it forwarded them. Whether
    // they reached the peer's disk is something only the peer can say.
    final ack = await acknowledged;
    if (!ack.isSuccess) {
      return _SendAttempt.failed(ack.errorMessage!);
    }

    final done = FileDone.tryParse(ack.data!);
    if (done == null || !done.ok) {
      return _SendAttempt.failed(
        done?.error ?? '对方未能保存文件',
        resumeFromChunk: done?.resumeFromChunk,
      );
    }

    onFileBytes(entry.size);
    return _SendAttempt.sent(entry.size);
  }

  /// Waits, briefly, for the receiver to say where a broken transfer stopped.
  ///
  /// The pending acknowledgement was armed with a timeout sized for the whole
  /// upload, which is far too long to sit on once the upload has already
  /// failed.
  Future<int?> _resumeOffered(
    Future<OperationResult<Map<String, dynamic>>> acknowledged,
  ) async {
    try {
      final ack = await acknowledged.timeout(
        AppConstants.relayFileAckTimeout,
      );
      if (!ack.isSuccess) {
        return null;
      }
      final done = FileDone.tryParse(ack.data!);
      return done != null && !done.ok ? done.resumeFromChunk : null;
    } on TimeoutException {
      return null;
    }
  }

  Future<OperationResult<void>> _upload({
    required String streamId,
    required _RelayFileEntry entry,
    required int startChunk,
    required RelayFileKey fileKey,
    required RelayFrameCodec codec,
    required void Function(int bytes) onFileBytes,
  }) async {
    final uri = _client.streamUri(streamId);
    if (uri == null) {
      return OperationResult.failure('中转服务器地址无效');
    }

    final headers = await _client.streamHeaders(streamId);
    final dio =
        _dioFactory?.call(entry.size) ??
        TransferHttp.createForUpload(entry.size);
    final resumedBytes = startChunk * AppConstants.relayChunkSize;
    final remaining = entry.size - resumedBytes;
    final wireLength = RelayFrameCodec.encryptedLengthFrom(
      entry.size,
      startChunk,
    );

    try {
      final response = await dio.post<String>(
        uri.toString(),
        // Always a stream, never a list: Dio runs a list through its JSON
        // transformer, which for an empty file would upload the two bytes
        // "[]" instead of the one frame that proves the file ended there.
        data: codec.encrypt(
          entry.size == 0
              ? const Stream<List<int>>.empty()
              : entry.item.file.openRead(resumedBytes),
          fileKey,
          startChunk: startChunk,
        ),
        options: Options(
          headers: {
            ...headers,
            Headers.contentLengthHeader: wireLength,
          },
          contentType: 'application/octet-stream',
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null,
        ),
        // Progress is measured on the wire but shown against the file, so the
        // ciphertext's per-frame overhead is scaled back out of it, and what
        // a previous attempt already delivered is added back in.
        onSendProgress: entry.size == 0
            ? null
            : (sent, _) => onFileBytes(
                min(
                  resumedBytes + sent * remaining ~/ wireLength,
                  entry.size,
                ),
              ),
      );

      if (response.statusCode == HttpStatus.ok) {
        return OperationResult.success();
      }
      return OperationResult.failure(
        _describeUploadFailure(response.statusCode!, response.data),
      );
    } on DioException catch (e) {
      LogUtil.wTag(logTag, '中转上传失败 ${entry.item.transferName}: ${e.message}');
      return OperationResult.failure(
        TransferHttp.describeFailure(e, transport: TransferTransport.relay),
      );
    } on FileSystemException catch (e) {
      return OperationResult.failure('文件访问错误: ${e.message}');
    } catch (e) {
      LogUtil.eTag(logTag, '中转上传异常 ${entry.item.transferName}: $e');
      return OperationResult.failure('中转上传失败: $e');
    } finally {
      dio.close();
    }
  }

  // -- helpers --------------------------------------------------------------

  /// Reads the size of every file up front, so the manifest describes the
  /// batch accurately and an unreadable file fails before anything is sent.
  Future<List<_RelayFileEntry>> _describeFiles(
    String peerDeviceId,
    List<TransferFileItem> files,
  ) async {
    final entries = <_RelayFileEntry>[];

    for (final item in files) {
      try {
        final size = await item.file.length();
        entries.add(
          _RelayFileEntry(
            item: item,
            size: size,
            fileId: await _fileId(peerDeviceId, item, size),
          ),
        );
      } catch (e) {
        LogUtil.wTag(logTag, '无法读取文件 ${item.transferName}: $e');
        entries.add(
          _RelayFileEntry(
            item: item,
            size: 0,
            fileId: _randomHex(16),
            error: '无法读取文件: $e',
          ),
        );
      }
    }
    return entries;
  }

  /// A stable identifier for one file in one transfer.
  ///
  /// Derived from the path, size and modification time rather than the
  /// contents, so offering a large file costs nothing (decision D6). Editing
  /// the file changes the id, which is what retires the half-received copy the
  /// peer is holding. The peer device id is mixed in so the same file sent to
  /// two peers does not collide in their resume state.
  Future<String> _fileId(
    String peerDeviceId,
    TransferFileItem item,
    int size,
  ) async {
    final modified = await _modifiedAt(item);
    final digest = await Sha256().hash(
      utf8.encode(
        '$peerDeviceId|${item.file.path}|${item.transferName}|$size|$modified',
      ),
    );
    return digest.bytes
        .take(16)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Modification time in seconds, or zero when the filesystem will not say.
  ///
  /// Zero is safe: it only means the id stops distinguishing two versions of
  /// the same path, and the chunk hash exchanged before resuming catches that.
  Future<int> _modifiedAt(TransferFileItem item) async {
    try {
      final stat = await item.file.stat();
      return stat.modified.millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return 0;
    }
  }

  Future<String> _localDeviceName() async {
    final name = await _preferencesService.getDeviceName();
    return name == null || name.isEmpty ? '' : name;
  }

  Map<String, OperationResult<TransferData>> _failAll(
    List<TransferFileItem> files,
    String reason,
  ) {
    return {
      for (final item in files)
        item.transferName: OperationResult<TransferData>.failure(reason),
    };
  }

  String _describeUploadFailure(int statusCode, String? body) {
    try {
      final decoded = jsonDecode(body ?? '');
      if (decoded is Map<String, dynamic>) {
        final code = decoded['code'];
        if (code == RelayErrorCode.peerNotAttached) {
          return '对方没有接入数据流';
        }
        if (code == RelayErrorCode.payloadTooLarge) {
          return '文件超过中转服务器的单次传输上限';
        }
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return '中转上传失败: $message';
        }
      }
    } catch (_) {
      // Fall through to the status code, which is always meaningful.
    }
    return '中转上传失败\n状态码: $statusCode';
  }

  static final Random _random = Random.secure();

  static String _randomHex(int bytes) {
    return List.generate(
      bytes,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

/// How one pass at a file turned out.
class _SendAttempt {
  final OperationResult<TransferData> result;

  /// Where the receiver says a retry may pick up. Null means there is no
  /// retry to be had, whether because the peer kept nothing or because it
  /// never got the chance to say.
  final int? resumeFromChunk;

  _SendAttempt.sent(int bytes)
    : result = OperationResult.success(
        data: TransferData(bytesTransferred: bytes),
      ),
      resumeFromChunk = null;

  _SendAttempt.failed(String error, {this.resumeFromChunk})
    : result = OperationResult<TransferData>.failure(error);
}

/// One file, resolved and ready to send.
class _RelayFileEntry {
  final TransferFileItem item;
  final int size;
  final String fileId;

  /// Set when the file could not be read; it is still announced so the result
  /// map has an entry for it, but it is never uploaded.
  final String? error;

  const _RelayFileEntry({
    required this.item,
    required this.size,
    required this.fileId,
    this.error,
  });
}
