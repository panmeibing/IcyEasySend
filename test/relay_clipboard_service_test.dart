import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/clipboard_data_model.dart';
import 'package:icy_easy_send/models/paired_device.dart';
import 'package:icy_easy_send/services/clipboard_service.dart';
import 'package:icy_easy_send/services/identity_service.dart';
import 'package:icy_easy_send/services/paired_device_store.dart';
import 'package:icy_easy_send/services/relay/relay_client.dart';
import 'package:icy_easy_send/services/relay/relay_clipboard_service.dart';
import 'package:icy_easy_send/services/relay/relay_crypto.dart';
import 'package:icy_easy_send/services/relay/relay_frame_codec.dart';
import 'package:icy_easy_send/services/relay/relay_protocol.dart';
import 'package:icy_easy_send/utils/constants.dart';
import 'package:icy_easy_send/utils/operation_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('clipboard protocol', () {
    test('offer / answer / request / response / done round-trip', () {
      const offer = ClipboardOffer(
        sessionId: 'abc',
        ephemeralPublicKey: 'epk',
        nonce: 'n',
      );
      expect(ClipboardOffer.tryParse(offer.toJson())!.sessionId, 'abc');

      const answer = ClipboardAnswer(
        sessionId: 'abc',
        ephemeralPublicKey: 'epk2',
        nonce: 'n2',
        signature: 'sig',
      );
      expect(ClipboardAnswer.tryParse(answer.toJson())!.signature, 'sig');

      const request = ClipboardRequest(
        sessionId: 'abc',
        requesterDeviceName: 'Phone',
        signature: 'sig',
      );
      expect(
        ClipboardRequest.tryParse(request.toJson())!.requesterDeviceName,
        'Phone',
      );

      const inline = ClipboardResponse(
        sessionId: 'abc',
        accepted: true,
        clipboardData: {'type': 'text', 'textContent': 'hi'},
      );
      final parsedInline = ClipboardResponse.tryParse(inline.toJson())!;
      expect(parsedInline.accepted, isTrue);
      expect(parsedInline.isStream, isFalse);
      expect(parsedInline.clipboardData!['textContent'], 'hi');

      const streamed = ClipboardResponse(
        sessionId: 'abc',
        accepted: true,
        delivery: ClipboardDelivery.stream,
        blobId: AppConstants.relayClipboardBlobId,
        streamId: 's1',
        size: 12,
        chunkCount: 1,
        clipboardType: 'text',
      );
      final parsedStream = ClipboardResponse.tryParse(streamed.toJson())!;
      expect(parsedStream.isStream, isTrue);
      expect(parsedStream.streamId, 's1');

      const done = ClipboardDone(
        sessionId: 'abc',
        blobId: AppConstants.relayClipboardBlobId,
        ok: true,
      );
      expect(ClipboardDone.tryParse(done.toJson())!.ok, isTrue);
    });
  });

  group('RelayClipboardService', () {
    late Directory workspace;
    late IdentityService initiatorIdentity;
    late IdentityService peerIdentity;
    late String initiatorDeviceId;
    late String peerDeviceId;
    late _FakeRelayClient initiatorClient;
    late _FakeRelayClient peerClient;
    late PairedDeviceStore initiatorStore;
    late PairedDeviceStore peerStore;
    late _InMemoryClipboardStreams streams;
    late RelayClipboardService initiator;
    RelayClipboardService? peer;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      workspace = await Directory.systemTemp.createTemp('relay-clipboard');
      initiatorIdentity = IdentityService.forTesting(
        filePath: '${workspace.path}${Platform.pathSeparator}a.key',
      );
      peerIdentity = IdentityService.forTesting(
        filePath: '${workspace.path}${Platform.pathSeparator}b.key',
      );
      initiatorDeviceId = await initiatorIdentity.getDeviceId();
      peerDeviceId = await peerIdentity.getDeviceId();

      streams = _InMemoryClipboardStreams();
      initiatorClient = _FakeRelayClient(
        deviceId: initiatorDeviceId,
        identity: initiatorIdentity,
      );
      peerClient = _FakeRelayClient(
        deviceId: peerDeviceId,
        identity: peerIdentity,
      );
      initiatorClient.peer = peerClient;
      peerClient.peer = initiatorClient;

      initiatorStore = PairedDeviceStore.forTesting(
        filePath: '${workspace.path}${Platform.pathSeparator}a.json',
      );
      peerStore = PairedDeviceStore.forTesting(
        filePath: '${workspace.path}${Platform.pathSeparator}b.json',
      );

      await initiatorStore.upsert(
        PairedDevice(
          deviceId: peerDeviceId,
          publicKey: await peerIdentity.getPublicKeyBase64(),
          deviceName: 'Peer',
          pairedAt: DateTime.now(),
        ),
      );
      await peerStore.upsert(
        PairedDevice(
          deviceId: initiatorDeviceId,
          publicKey: await initiatorIdentity.getPublicKeyBase64(),
          deviceName: 'Initiator',
          pairedAt: DateTime.now(),
        ),
      );

      initiator = RelayClipboardService(
        client: initiatorClient,
        identity: initiatorIdentity,
        pairedDevices: initiatorStore,
        streamUpload: streams.upload,
        streamDownload: streams.download,
      )..start();
      initiatorClient.markOnline(peerDeviceId);
    });

    tearDown(() async {
      await initiator.stop();
      await peer?.stop();
      await initiatorClient.shutdown();
      await peerClient.shutdown();
      if (await workspace.exists()) {
        await workspace.delete(recursive: true);
      }
    });

    test('rejects when the peer is not paired on this device', () async {
      await initiatorStore.remove(peerDeviceId);

      final result = await initiator.requestFromPeer(peerDeviceId);
      expect(result.isSuccess, isFalse);
    });

    test('rejects when the peer is offline on the relay', () async {
      initiatorClient.clearOnline();

      final result = await initiator.requestFromPeer(peerDeviceId);
      expect(result.isSuccess, isFalse);
    });

    test('peer without UI refuses the offer', () async {
      peer = RelayClipboardService(
        client: peerClient,
        identity: peerIdentity,
        pairedDevices: peerStore,
        contextGetter: () => null,
        isInBackgroundGetter: () => false,
        streamUpload: streams.upload,
        streamDownload: streams.download,
      )..start();

      final result = await initiator.requestFromPeer(peerDeviceId);
      expect(result.isSuccess, isFalse);
    });

    test('happy path shares small text clipboard inline', () async {
      peer = RelayClipboardService(
        client: peerClient,
        identity: peerIdentity,
        pairedDevices: peerStore,
        clipboardService: _FakeClipboardService(
          ClipboardDataModel(
            type: ClipboardDataType.text,
            textContent: 'hello-relay',
          ),
        ),
        confirmShare: (_) async => true,
        streamUpload: streams.upload,
        streamDownload: streams.download,
      )..start();

      final result = await initiator.requestFromPeer(peerDeviceId);
      expect(result.isSuccess, isTrue, reason: result.errorMessage);
      expect(result.data!.textContent, 'hello-relay');
      expect(streams.uploadCount, 0);
    });

    test('large text clipboard uses the data plane', () async {
      final largeText = 'x' * (AppConstants.relayClipboardMaxPlainBytes + 64);
      peer = RelayClipboardService(
        client: peerClient,
        identity: peerIdentity,
        pairedDevices: peerStore,
        clipboardService: _FakeClipboardService(
          ClipboardDataModel(
            type: ClipboardDataType.text,
            textContent: largeText,
          ),
        ),
        confirmShare: (_) async => true,
        streamUpload: streams.upload,
        streamDownload: streams.download,
      )..start();

      final result = await initiator.requestFromPeer(peerDeviceId);
      expect(result.isSuccess, isTrue, reason: result.errorMessage);
      expect(result.data!.textContent, largeText);
      expect(streams.uploadCount, 1);
      expect(streams.downloadCount, 1);
    });

    test('file clipboard uses the data plane', () async {
      final bytes = Uint8List.fromList(
        List<int>.generate(AppConstants.relayClipboardMaxPlainBytes, (i) => i),
      );
      peer = RelayClipboardService(
        client: peerClient,
        identity: peerIdentity,
        pairedDevices: peerStore,
        clipboardService: _FakeClipboardService(
          ClipboardDataModel(
            type: ClipboardDataType.file,
            fileData: bytes,
            fileName: 'clip.bin',
            mimeType: 'application/octet-stream',
          ),
        ),
        confirmShare: (_) async => true,
        streamUpload: streams.upload,
        streamDownload: streams.download,
      )..start();

      final result = await initiator.requestFromPeer(peerDeviceId);
      expect(result.isSuccess, isTrue, reason: result.errorMessage);
      expect(result.data!.type, ClipboardDataType.file);
      expect(result.data!.fileName, 'clip.bin');
      expect(result.data!.fileData, bytes);
      expect(streams.uploadCount, 1);
    });

    test('peer declining leaves the initiator with an error', () async {
      peer = RelayClipboardService(
        client: peerClient,
        identity: peerIdentity,
        pairedDevices: peerStore,
        clipboardService: _FakeClipboardService(
          ClipboardDataModel(
            type: ClipboardDataType.text,
            textContent: 'secret',
          ),
        ),
        confirmShare: (_) async => false,
        streamUpload: streams.upload,
        streamDownload: streams.download,
      )..start();

      final result = await initiator.requestFromPeer(peerDeviceId);
      expect(result.isSuccess, isFalse);
    });
  });
}

class _FakeClipboardService extends ClipboardService {
  final ClipboardDataModel? content;

  _FakeClipboardService(this.content);

  @override
  Future<ClipboardDataModel?> getClipboardContent() async => content;
}

/// In-memory stand-in for relay HTTP streams, still using real frame crypto.
class _InMemoryClipboardStreams {
  final Map<String, Completer<Uint8List>> _wire = {};
  int uploadCount = 0;
  int downloadCount = 0;

  Future<OperationResult<void>> upload({
    required String streamId,
    required int size,
    required Stream<List<int>> plaintext,
    required RelayFileKey fileKey,
    required RelayFrameCodec codec,
  }) async {
    uploadCount++;
    final builder = BytesBuilder(copy: false);
    await for (final frame in codec.encrypt(
      size == 0 ? const Stream<List<int>>.empty() : plaintext,
      fileKey,
    )) {
      builder.add(frame);
    }
    final completer = _wire.putIfAbsent(streamId, Completer<Uint8List>.new);
    if (!completer.isCompleted) {
      completer.complete(builder.takeBytes());
    }
    return OperationResult.success();
  }

  Future<OperationResult<Uint8List>> download({
    required String streamId,
    required int size,
    required int chunkCount,
    required RelayFileKey fileKey,
    required RelayFrameCodec codec,
  }) async {
    downloadCount++;
    final completer = _wire.putIfAbsent(streamId, Completer<Uint8List>.new);
    final wire = await completer.future.timeout(const Duration(seconds: 5));
    final builder = BytesBuilder(copy: false);
    await for (final chunk in codec.decrypt(
      Stream<List<int>>.value(wire),
      fileKey,
      chunkCount: chunkCount,
    )) {
      builder.add(chunk);
    }
    return OperationResult.success(data: builder.takeBytes());
  }
}

class _FakeRelayClient extends RelayClient {
  final String deviceId;
  final StreamController<RelayInboundPayload> _inbound =
      StreamController<RelayInboundPayload>.broadcast();
  final Set<String> _online = {};
  var _streamSeq = 0;

  _FakeRelayClient? peer;

  Future<void> _delivery = Future.value();

  _FakeRelayClient({required this.deviceId, required IdentityService identity})
    : super(identity: identity);

  void markOnline(String id) => _online.add(id);

  void clearOnline() => _online.clear();

  @override
  bool get isConnected => true;

  @override
  Future<bool> connect() async => true;

  @override
  bool isOnline(String peerDeviceId) => _online.contains(peerDeviceId);

  @override
  Stream<RelayInboundPayload> get payloads => _inbound.stream;

  @override
  Future<OperationResult<String>> createStream({
    required String peerDeviceId,
    required String role,
  }) async {
    _streamSeq++;
    return OperationResult.success(data: 'stream-$_streamSeq');
  }

  @override
  Future<OperationResult<void>> sendPayload({
    required String toDeviceId,
    required Map<String, dynamic> payload,
    String kind = RelayKind.transfer,
  }) async {
    final target = peer;
    if (target == null) {
      return OperationResult.success();
    }
    await target._deliver(deviceId, payload);
    return OperationResult.success();
  }

  @override
  Future<OperationResult<Map<String, dynamic>>> sendAndAwaitReply({
    required String toDeviceId,
    required Map<String, dynamic> payload,
    required bool Function(Map<String, dynamic> reply) matches,
    required Duration timeout,
    String kind = RelayKind.transfer,
  }) async {
    final reply = _inbound.stream
        .firstWhere(
          (event) => event.fromDeviceId == toDeviceId && matches(event.payload),
        )
        .timeout(timeout);

    await sendPayload(toDeviceId: toDeviceId, payload: payload, kind: kind);

    try {
      return OperationResult.success(data: (await reply).payload);
    } on TimeoutException {
      return OperationResult.failure('对方设备没有响应');
    }
  }

  @override
  Future<OperationResult<Map<String, dynamic>>> awaitPayload({
    required String fromDeviceId,
    required bool Function(Map<String, dynamic> payload) matches,
    required Duration timeout,
  }) async {
    try {
      final inbound = await _inbound.stream
          .firstWhere(
            (event) =>
                event.fromDeviceId == fromDeviceId && matches(event.payload),
          )
          .timeout(timeout);
      return OperationResult.success(data: inbound.payload);
    } on TimeoutException {
      return OperationResult.failure('对方设备没有响应');
    }
  }

  Future<void> _deliver(String from, Map<String, dynamic> payload) {
    _delivery = _delivery.then((_) async {
      if (_inbound.isClosed) {
        return;
      }
      var delivered = payload;
      if (payload['type'] == RelayPayloadType.secure) {
        final opened = await sessions.open(from, payload);
        if (opened == null) {
          return;
        }
        delivered = opened;
      }
      if (_inbound.isClosed) {
        return;
      }
      _inbound.add(
        RelayInboundPayload(fromDeviceId: from, payload: delivered),
      );
    });
    return _delivery;
  }

  Future<void> shutdown() async {
    await _inbound.close();
  }
}
