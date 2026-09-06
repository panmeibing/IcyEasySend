import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/clipboard_data_model.dart';
import '../../utils/constants.dart';
import '../../utils/log_util.dart';
import '../../utils/network_util.dart';
import '../../utils/operation_result.dart';
import '../../utils/relay_message_provider.dart';
import '../clipboard_service.dart';
import '../identity_service.dart';
import '../paired_device_store.dart';
import '../preferences_service.dart';
import '../transfer/transfer_http.dart';
import 'relay_client.dart';
import 'relay_crypto.dart';
import 'relay_crypto_worker.dart';
import 'relay_frame_codec.dart';
import 'relay_protocol.dart';

/// Uploads framed clipboard plaintext to a relay stream (injectable for tests).
typedef ClipboardStreamUpload =
    Future<OperationResult<void>> Function({
      required String streamId,
      required int size,
      required Stream<List<int>> plaintext,
      required RelayFileKey fileKey,
      required RelayFrameCodec codec,
    });

/// Downloads and decrypts a clipboard blob from a relay stream.
typedef ClipboardStreamDownload =
    Future<OperationResult<Uint8List>> Function({
      required String streamId,
      required int size,
      required int chunkCount,
      required RelayFileKey fileKey,
      required RelayFrameCodec codec,
    });

/// Clipboard sync over the relay.
///
/// Small payloads stay on the signaling plane (inline JSON). Larger text or
/// any file/image bytes use a data-plane stream with the same AEAD framing as
/// file transfer. The clipboard owner POSTs; the requester GETs.
class RelayClipboardService {
  final RelayClient _client;
  final IdentityService _identity;
  final PairedDeviceStore _pairedDevices;
  final PreferencesService _preferences;
  final ClipboardService _clipboardService;
  final Dio Function(int fileSize)? _dioFactory;
  final ClipboardStreamUpload? _streamUpload;
  final ClipboardStreamDownload? _streamDownload;
  final BuildContext? Function()? contextGetter;
  final bool Function()? isInBackgroundGetter;

  /// When set (tests), replaces the confirm dialog.
  final Future<bool> Function(String requesterDeviceName)? confirmShare;

  final String logTag = LogTags.clipboard;
  final RelayMessages _messages = RelayMessages.instance;

  StreamSubscription<RelayInboundPayload>? _subscription;
  bool _busy = false;

  RelayClipboardService({
    required RelayClient client,
    this.contextGetter,
    this.isInBackgroundGetter,
    this.confirmShare,
    IdentityService? identity,
    PairedDeviceStore? pairedDevices,
    PreferencesService? preferences,
    ClipboardService? clipboardService,
    Dio Function(int fileSize)? dioFactory,
    ClipboardStreamUpload? streamUpload,
    ClipboardStreamDownload? streamDownload,
  }) : _client = client,
       _identity = identity ?? IdentityService.instance,
       _pairedDevices = pairedDevices ?? PairedDeviceStore.instance,
       _preferences = preferences ?? PreferencesService(),
       _clipboardService = clipboardService ?? ClipboardService(),
       _dioFactory = dioFactory,
       _streamUpload = streamUpload,
       _streamDownload = streamDownload;

  void start() {
    _subscription ??= _client.payloads.listen(_onPayload);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  // -- initiator ------------------------------------------------------------

  /// Pulls the peer's clipboard over the relay and returns the plaintext model.
  ///
  /// The caller is responsible for writing it to the local clipboard.
  Future<OperationResult<ClipboardDataModel>> requestFromPeer(
    String peerDeviceId,
  ) async {
    final paired = await _pairedDevices.find(peerDeviceId);
    if (paired == null) {
      return OperationResult.failure(_messages.clipboardNeedsPairing);
    }

    final peerPublicKey = IdentityService.decodePublicKey(paired.publicKey);
    if (peerPublicKey == null) {
      return OperationResult.failure(_messages.clipboardNeedsPairing);
    }

    if (!_client.isConnected && !await _client.connect()) {
      return OperationResult.failure(_messages.clipboardRelayUnavailable);
    }

    if (!_client.isOnline(peerDeviceId)) {
      return OperationResult.failure(_messages.clipboardPeerOffline);
    }

    final sessionId = _randomHex(16);
    final localDeviceId = await _identity.getDeviceId();
    final pending = await RelayCrypto.createOffer(sessionId);

    final reply = await _client.sendAndAwaitReply(
      toDeviceId: peerDeviceId,
      kind: RelayKind.transfer,
      payload: {
        'type': RelayPayloadType.clipboardOffer,
        'sid': sessionId,
        'epk': base64Encode(pending.publicKey),
        'n': base64Encode(pending.nonce),
      },
      matches: (payload) =>
          payload['sid'] == sessionId &&
          (payload['type'] == RelayPayloadType.clipboardAnswer ||
              payload['type'] == RelayPayloadType.clipboardReject),
      timeout: AppConstants.relayClipboardReplyTimeout,
    );
    if (!reply.isSuccess) {
      return OperationResult.failure(reply.errorMessage!);
    }

    if (reply.data!['type'] == RelayPayloadType.clipboardReject) {
      final reject = ClipboardReject.tryParse(reply.data!);
      return OperationResult.failure(_describeReject(reject?.reason));
    }

    final answer = ClipboardAnswer.tryParse(reply.data!);
    if (answer == null) {
      return OperationResult.failure(_messages.clipboardFailed);
    }

    final sessionResult = await RelayCrypto.completeOffer(
      offer: pending,
      answer: answer.asTransferAnswer,
      senderDeviceId: localDeviceId,
      receiverDeviceId: peerDeviceId,
      receiverPublicKey: peerPublicKey,
    );
    if (!sessionResult.isSuccess) {
      return OperationResult.failure(sessionResult.errorMessage!);
    }
    final session = sessionResult.data!;
    _client.sessions.add(session);

    RelayCryptoWorker? worker;
    try {
      final deviceName = await NetworkUtil.getDeviceName();
      final signature = await RelayCrypto.signAsSender(
        session.transcript,
        identity: _identity,
      );

      final responseTimeout =
          AppConstants.relayClipboardReplyTimeout +
          TransferHttp.transferTimeout(AppConstants.maxClipboardSizeMB *
              AppConstants.bytesPerMB);

      final response = await _client.sendAndAwaitReply(
        toDeviceId: peerDeviceId,
        kind: RelayKind.transfer,
        payload: await session.seal(
          ClipboardRequest(
            sessionId: sessionId,
            requesterDeviceName: deviceName,
            signature: signature,
          ).toJson(),
        ),
        matches: (payload) =>
            payload['type'] == RelayPayloadType.clipboardResponse &&
            payload['sid'] == sessionId,
        timeout: responseTimeout,
      );
      if (!response.isSuccess) {
        return OperationResult.failure(response.errorMessage!);
      }

      final parsed = ClipboardResponse.tryParse(response.data!);
      if (parsed == null) {
        return OperationResult.failure(_messages.clipboardFailed);
      }
      if (!parsed.accepted) {
        return OperationResult.failure(_describeReject(parsed.reason));
      }

      if (parsed.isStream) {
        worker = await _openWorker();
        final codec = RelayFrameCodec(worker: worker);
        return await _receiveStreamedClipboard(
          session: session,
          response: parsed,
          codec: codec,
        );
      }

      if (parsed.clipboardData == null) {
        return OperationResult.failure(_messages.clipboardFailed);
      }
      try {
        return OperationResult.success(
          data: ClipboardDataModel.fromJson(parsed.clipboardData!),
        );
      } catch (e) {
        LogUtil.wTag(logTag, '???????????: $e');
        return OperationResult.failure(_messages.clipboardFailed);
      }
    } finally {
      await worker?.dispose();
      _client.sessions.remove(sessionId);
    }
  }

  Future<OperationResult<ClipboardDataModel>> _receiveStreamedClipboard({
    required RelaySecureSession session,
    required ClipboardResponse response,
    required RelayFrameCodec codec,
  }) async {
    final blobId = response.blobId!;
    final streamId = response.streamId!;
    final size = response.size!;
    final chunkCount = response.chunkCount!;

    final fileKey = await session.keys.fileKey(blobId, attempt: 0);
    final downloaded = await _downloadBlob(
      streamId: streamId,
      size: size,
      chunkCount: chunkCount,
      fileKey: fileKey,
      codec: codec,
    );

    if (!downloaded.isSuccess) {
      await _sendDone(
        session,
        blobId: blobId,
        ok: false,
        error: downloaded.errorMessage,
      );
      return OperationResult.failure(
        downloaded.errorMessage ?? _messages.clipboardStreamFailed,
      );
    }

    final bytes = downloaded.data!;
    if (bytes.length != size) {
      await _sendDone(
        session,
        blobId: blobId,
        ok: false,
        error: 'size mismatch',
      );
      return OperationResult.failure(_messages.clipboardStreamFailed);
    }

    final model = _modelFromBlob(
      clipboardType: response.clipboardType!,
      bytes: bytes,
      fileName: response.fileName,
      mimeType: response.mimeType,
    );
    if (model == null) {
      await _sendDone(
        session,
        blobId: blobId,
        ok: false,
        error: 'bad clipboard type',
      );
      return OperationResult.failure(_messages.clipboardFailed);
    }

    await _sendDone(session, blobId: blobId, ok: true);
    return OperationResult.success(data: model);
  }

  // -- answering ------------------------------------------------------------

  void _onPayload(RelayInboundPayload inbound) {
    if (inbound.payload['type'] == RelayPayloadType.clipboardOffer) {
      unawaited(_onOffer(inbound));
    }
  }

  Future<void> _onOffer(RelayInboundPayload inbound) async {
    final offer = ClipboardOffer.tryParse(inbound.payload);
    if (offer == null) {
      return;
    }

    final peerDeviceId = inbound.fromDeviceId;
    final paired = await _pairedDevices.find(peerDeviceId);
    if (paired == null) {
      await _reject(
        peerDeviceId,
        offer.sessionId,
        ClipboardRejectReason.notPaired,
      );
      return;
    }

    if (_busy) {
      await _reject(peerDeviceId, offer.sessionId, ClipboardRejectReason.busy);
      return;
    }
    if (!_hasUsableUi()) {
      await _reject(peerDeviceId, offer.sessionId, ClipboardRejectReason.noUi);
      return;
    }

    final localDeviceId = await _identity.getDeviceId();
    final answered = await RelayCrypto.answerOffer(
      offer: offer.asTransferOffer,
      senderDeviceId: peerDeviceId,
      receiverDeviceId: localDeviceId,
      identity: _identity,
    );
    if (!answered.isSuccess) {
      await _reject(
        peerDeviceId,
        offer.sessionId,
        ClipboardRejectReason.declined,
      );
      return;
    }

    final session = answered.data!.session;
    _client.sessions.add(session);
    _busy = true;
    RelayCryptoWorker? worker;

    try {
      final requestFuture = _client.awaitPayload(
        fromDeviceId: peerDeviceId,
        matches: (payload) =>
            payload['type'] == RelayPayloadType.clipboardRequest &&
            payload['sid'] == offer.sessionId,
        timeout: AppConstants.relayClipboardReplyTimeout,
      );

      await _client.sendPayload(
        toDeviceId: peerDeviceId,
        kind: RelayKind.transfer,
        payload: ClipboardAnswer.fromTransferAnswer(
          answered.data!.answer,
        ).toJson(),
      );

      final requestInbound = await requestFuture;
      if (!requestInbound.isSuccess) {
        await _sendResponse(
          session,
          accepted: false,
          reason: ClipboardRejectReason.timeout,
        );
        return;
      }

      final request = ClipboardRequest.tryParse(requestInbound.data!);
      if (request == null) {
        await _sendResponse(
          session,
          accepted: false,
          reason: ClipboardRejectReason.declined,
        );
        return;
      }

      final peerKey = IdentityService.decodePublicKey(paired.publicKey);
      if (peerKey == null ||
          !await RelayCrypto.verifySenderSignature(
            transcript: session.transcript,
            signature: request.signature,
            senderPublicKey: peerKey,
          )) {
        LogUtil.wTag(logTag, '???????????: $peerDeviceId');
        await _sendResponse(
          session,
          accepted: false,
          reason: ClipboardRejectReason.declined,
        );
        return;
      }

      final name = request.requesterDeviceName.isNotEmpty
          ? request.requesterDeviceName
          : (paired.deviceName.isNotEmpty ? paired.deviceName : peerDeviceId);

      final bool accepted;
      if (confirmShare != null) {
        accepted = await confirmShare!(name);
      } else {
        final context = contextGetter?.call();
        if (context == null || !context.mounted || !_hasUsableUi()) {
          await _sendResponse(
            session,
            accepted: false,
            reason: ClipboardRejectReason.noUi,
          );
          return;
        }
        accepted = await _confirmShare(context, name);
      }
      if (!accepted) {
        await _sendResponse(
          session,
          accepted: false,
          reason: ClipboardRejectReason.declined,
        );
        return;
      }

      final content = await _clipboardService.getClipboardContent();
      if (content == null) {
        await _sendResponse(
          session,
          accepted: false,
          reason: ClipboardRejectReason.empty,
        );
        return;
      }

      final maxMb = await _preferences.getMaxClipboardSize();
      if (content.sizeInMB > maxMb) {
        await _sendResponse(
          session,
          accepted: false,
          reason: ClipboardRejectReason.tooLarge,
        );
        return;
      }

      final dataJson = content.toJson();
      final plainSize = utf8.encode(jsonEncode(dataJson)).length;
      if (plainSize <= AppConstants.relayClipboardMaxPlainBytes) {
        await _sendResponse(
          session,
          accepted: true,
          delivery: ClipboardDelivery.inline,
          clipboardData: dataJson,
        );
        return;
      }

      LogUtil.iTag(
        logTag,
        '??????? ($plainSize bytes JSON / ${content.sizeInBytes} bytes blob)',
      );
      worker = await _openWorker();
      await _shareViaStream(
        session: session,
        content: content,
        codec: RelayFrameCodec(worker: worker),
      );
    } finally {
      await worker?.dispose();
      _busy = false;
      _client.sessions.remove(offer.sessionId);
    }
  }

  Future<void> _shareViaStream({
    required RelaySecureSession session,
    required ClipboardDataModel content,
    required RelayFrameCodec codec,
  }) async {
    final blob = _blobBytes(content);
    if (blob == null) {
      await _sendResponse(
        session,
        accepted: false,
        reason: ClipboardRejectReason.empty,
      );
      return;
    }

    final stream = await _client.createStream(
      peerDeviceId: session.peerDeviceId,
      role: RelayStreamRole.sender,
    );
    if (!stream.isSuccess) {
      LogUtil.wTag(logTag, '??????????: ${stream.errorMessage}');
      await _sendResponse(
        session,
        accepted: false,
        reason: ClipboardRejectReason.declined,
      );
      return;
    }
    final streamId = stream.data!;
    const blobId = AppConstants.relayClipboardBlobId;
    final size = blob.length;
    final chunkCount = FileBegin.chunkCountFor(size);

    final doneFuture = _client.awaitPayload(
      fromDeviceId: session.peerDeviceId,
      matches: (payload) =>
          payload['type'] == RelayPayloadType.clipboardDone &&
          payload['sid'] == session.sessionId &&
          payload['blobId'] == blobId,
      timeout:
          TransferHttp.transferTimeout(size) +
          AppConstants.relayClipboardStreamAckTimeout,
    );

    await _sendResponse(
      session,
      accepted: true,
      delivery: ClipboardDelivery.stream,
      blobId: blobId,
      streamId: streamId,
      size: size,
      chunkCount: chunkCount,
      clipboardType: content.type.name,
      fileName: content.fileName,
      mimeType: content.mimeType,
    );

    final fileKey = await session.keys.fileKey(blobId, attempt: 0);
    final uploaded = await _uploadBlob(
      streamId: streamId,
      size: size,
      plaintext: Stream<List<int>>.value(blob),
      fileKey: fileKey,
      codec: codec,
    );
    if (!uploaded.isSuccess) {
      LogUtil.wTag(logTag, '??????????: ${uploaded.errorMessage}');
      // Still wait briefly so the initiator is not left hanging forever if it
      // already started the GET; the ack timeout covers the rest.
      try {
        await doneFuture.timeout(AppConstants.relayClipboardStreamAckTimeout);
      } catch (_) {}
      return;
    }

    final doneInbound = await doneFuture;
    if (!doneInbound.isSuccess) {
      LogUtil.wTag(logTag, '??????????: ${doneInbound.errorMessage}');
      return;
    }
    final done = ClipboardDone.tryParse(doneInbound.data!);
    if (done == null || !done.ok) {
      LogUtil.wTag(logTag, '?????????: ${done?.error}');
    }
  }

  // -- stream I/O -----------------------------------------------------------

  Future<OperationResult<void>> _uploadBlob({
    required String streamId,
    required int size,
    required Stream<List<int>> plaintext,
    required RelayFileKey fileKey,
    required RelayFrameCodec codec,
  }) {
    final injected = _streamUpload;
    if (injected != null) {
      return injected(
        streamId: streamId,
        size: size,
        plaintext: plaintext,
        fileKey: fileKey,
        codec: codec,
      );
    }
    return _uploadViaHttp(
      streamId: streamId,
      size: size,
      plaintext: plaintext,
      fileKey: fileKey,
      codec: codec,
    );
  }

  Future<OperationResult<Uint8List>> _downloadBlob({
    required String streamId,
    required int size,
    required int chunkCount,
    required RelayFileKey fileKey,
    required RelayFrameCodec codec,
  }) {
    final injected = _streamDownload;
    if (injected != null) {
      return injected(
        streamId: streamId,
        size: size,
        chunkCount: chunkCount,
        fileKey: fileKey,
        codec: codec,
      );
    }
    return _downloadViaHttp(
      streamId: streamId,
      size: size,
      chunkCount: chunkCount,
      fileKey: fileKey,
      codec: codec,
    );
  }

  Future<OperationResult<void>> _uploadViaHttp({
    required String streamId,
    required int size,
    required Stream<List<int>> plaintext,
    required RelayFileKey fileKey,
    required RelayFrameCodec codec,
  }) async {
    final uri = _client.streamUri(streamId);
    if (uri == null) {
      return OperationResult.failure('?????????');
    }

    final headers = await _client.streamHeaders(streamId);
    final dio =
        _dioFactory?.call(size) ?? TransferHttp.createForUpload(size);
    final wireLength = RelayFrameCodec.encryptedLength(size);

    try {
      final response = await dio.post<String>(
        uri.toString(),
        data: codec.encrypt(
          size == 0 ? const Stream<List<int>>.empty() : plaintext,
          fileKey,
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
      );
      if (response.statusCode == HttpStatus.ok) {
        return OperationResult.success();
      }
      return OperationResult.failure(
        '??????\n???: ${response.statusCode}',
      );
    } on DioException catch (e) {
      return OperationResult.failure(
        TransferHttp.describeFailure(
          e,
          transport: TransferTransport.relay,
          verb: '??',
        ),
      );
    } catch (e) {
      return OperationResult.failure('??????: $e');
    } finally {
      dio.close();
    }
  }

  Future<OperationResult<Uint8List>> _downloadViaHttp({
    required String streamId,
    required int size,
    required int chunkCount,
    required RelayFileKey fileKey,
    required RelayFrameCodec codec,
  }) async {
    final uri = _client.streamUri(streamId);
    if (uri == null) {
      return OperationResult.failure('?????????');
    }

    final dio =
        _dioFactory?.call(size) ?? TransferHttp.createForDownload(size);
    try {
      final response = await dio.get<ResponseBody>(
        uri.toString(),
        options: Options(
          headers: await _client.streamHeaders(streamId),
          responseType: ResponseType.stream,
          validateStatus: (status) => status != null,
        ),
      );
      if (response.statusCode != 200 || response.data == null) {
        return OperationResult.failure(
          '?????????\n???: ${response.statusCode}',
        );
      }

      final builder = BytesBuilder(copy: false);
      await for (final chunk in codec.decrypt(
        response.data!.stream,
        fileKey,
        chunkCount: chunkCount,
      )) {
        builder.add(chunk);
      }
      return OperationResult.success(data: builder.takeBytes());
    } on DioException catch (e) {
      return OperationResult.failure(
        TransferHttp.describeFailure(
          e,
          transport: TransferTransport.relay,
          verb: '??',
        ),
      );
    } on RelayCryptoException catch (e) {
      return OperationResult.failure('???????????????: $e');
    } catch (e) {
      return OperationResult.failure('??????: $e');
    } finally {
      // Safe here because the response stream is fully drained into the
      // builder above before this runs.
      dio.close();
    }
  }

  // -- helpers --------------------------------------------------------------

  Future<void> _sendResponse(
    RelaySecureSession session, {
    required bool accepted,
    String delivery = ClipboardDelivery.inline,
    String? reason,
    Map<String, dynamic>? clipboardData,
    String? blobId,
    String? streamId,
    int? size,
    int? chunkCount,
    String? clipboardType,
    String? fileName,
    String? mimeType,
  }) async {
    await _client.sendPayload(
      toDeviceId: session.peerDeviceId,
      kind: RelayKind.transfer,
      payload: await session.seal(
        ClipboardResponse(
          sessionId: session.sessionId,
          accepted: accepted,
          reason: reason,
          delivery: delivery,
          clipboardData: clipboardData,
          blobId: blobId,
          streamId: streamId,
          size: size,
          chunkCount: chunkCount,
          clipboardType: clipboardType,
          fileName: fileName,
          mimeType: mimeType,
        ).toJson(),
      ),
    );
  }

  Future<void> _sendDone(
    RelaySecureSession session, {
    required String blobId,
    required bool ok,
    String? error,
  }) async {
    await _client.sendPayload(
      toDeviceId: session.peerDeviceId,
      kind: RelayKind.transfer,
      payload: await session.seal(
        ClipboardDone(
          sessionId: session.sessionId,
          blobId: blobId,
          ok: ok,
          error: error,
        ).toJson(),
      ),
    );
  }

  Future<void> _reject(String peerDeviceId, String sessionId, String reason) {
    return _client.sendPayload(
      toDeviceId: peerDeviceId,
      kind: RelayKind.transfer,
      payload: ClipboardReject(sessionId: sessionId, reason: reason).toJson(),
    );
  }

  Future<bool> _confirmShare(
    BuildContext context,
    String requesterDeviceName,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.clipboardRequest),
          content: Text(l10n.clipboardRequestFrom(requesterDeviceName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.reject),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.allowClipboardRequest),
            ),
          ],
        );
      },
    ).timeout(
      AppConstants.receiveConfirmationTimeout,
      onTimeout: () => false,
    );
    return result == true;
  }

  bool _hasUsableUi() {
    if (confirmShare != null) {
      return true;
    }
    if (isInBackgroundGetter?.call() ?? false) {
      return false;
    }
    final context = contextGetter?.call();
    return context != null && context.mounted;
  }

  Future<RelayCryptoWorker> _openWorker() async {
    if (_streamUpload != null || _streamDownload != null) {
      return RelayCryptoWorker.inlineForTesting();
    }
    return RelayCryptoWorker.spawn();
  }

  String _describeReject(String? reason) {
    switch (reason) {
      case ClipboardRejectReason.notPaired:
        return _messages.clipboardNeedsPairing;
      case ClipboardRejectReason.noUi:
        return _messages.clipboardPeerNoUi;
      case ClipboardRejectReason.busy:
        return _messages.clipboardPeerBusy;
      case ClipboardRejectReason.empty:
        return _messages.clipboardEmpty;
      case ClipboardRejectReason.tooLarge:
        return _messages.clipboardTooLargeForRelay;
      case ClipboardRejectReason.timeout:
        return _messages.clipboardPeerTimeout;
      default:
        return _messages.clipboardDeclined;
    }
  }

  /// Raw bytes placed on the data plane (not base64 JSON).
  static Uint8List? _blobBytes(ClipboardDataModel content) {
    switch (content.type) {
      case ClipboardDataType.text:
        final text = content.textContent;
        if (text == null) return null;
        return Uint8List.fromList(utf8.encode(text));
      case ClipboardDataType.file:
        return content.fileData;
      case ClipboardDataType.unknown:
        return null;
    }
  }

  static ClipboardDataModel? _modelFromBlob({
    required String clipboardType,
    required Uint8List bytes,
    String? fileName,
    String? mimeType,
  }) {
    if (clipboardType == ClipboardDataType.text.name) {
      return ClipboardDataModel(
        type: ClipboardDataType.text,
        textContent: utf8.decode(bytes),
      );
    }
    if (clipboardType == ClipboardDataType.file.name) {
      return ClipboardDataModel(
        type: ClipboardDataType.file,
        fileData: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
    }
    return null;
  }

  static String _randomHex(int bytes) {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < bytes; i++) {
      buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
