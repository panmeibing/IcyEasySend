import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/l10n/current_localizations.dart';
import 'package:icy_easy_send/models/paired_device.dart';
import 'package:icy_easy_send/models/transfer_data.dart';
import 'package:icy_easy_send/models/transfer_file_item.dart';
import 'package:icy_easy_send/models/transfer_history.dart';
import 'package:icy_easy_send/services/batch_receive_manager.dart';
import 'package:icy_easy_send/services/batch_receive_prompter.dart';
import 'package:icy_easy_send/services/file_transfer_service.dart';
import 'package:icy_easy_send/services/identity_service.dart';
import 'package:icy_easy_send/services/paired_device_store.dart';
import 'package:icy_easy_send/services/relay/relay_client.dart';
import 'package:icy_easy_send/services/relay/relay_protocol.dart';
import 'package:icy_easy_send/services/relay/relay_receive_coordinator.dart';
import 'package:icy_easy_send/services/relay/resume_store.dart';
import 'package:icy_easy_send/services/transfer/transfer_history_manager.dart';
import 'package:icy_easy_send/transport/relay_channel.dart';
import 'package:icy_easy_send/transport/transport_channel.dart';
import 'package:icy_easy_send/utils/operation_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cancelling a relayed batch from either end, with the production sender and
/// receiver talking to each other. The control plane is an in-memory pair of
/// clients; the data plane is a local server that forwards each stream's
/// upload to its download slowly enough to cancel in the middle.
void main() {
  late Directory workspace;
  late _MiniRelay relay;
  late _FakeRelayClient senderClient;
  late _FakeRelayClient receiverClient;
  late String receiverDeviceId;
  late RelayChannel channel;
  late RelayReceiveCoordinator coordinator;
  late _Prompter prompter;
  late BatchReceiveManager receiveManager;
  late Directory saveDir;

  Future<void> setUpPair(BuildContext context) async {
    SharedPreferences.setMockInitialValues({'device_name': 'tester'});
    HttpOverrides.global = null;
    workspace = await Directory.systemTemp.createTemp('relay_cancel');
    saveDir = await Directory('${workspace.path}/saved').create();
    final partialDir = await Directory('${workspace.path}/partial').create();

    relay = _MiniRelay();
    await relay.start();

    final senderIdentity = IdentityService.forTesting(
      filePath: '${workspace.path}/sender.key',
    );
    final receiverIdentity = IdentityService.forTesting(
      filePath: '${workspace.path}/receiver.key',
    );
    final senderDeviceId = await senderIdentity.getDeviceId();
    receiverDeviceId = await receiverIdentity.getDeviceId();

    senderClient = _FakeRelayClient(
      deviceId: senderDeviceId,
      identity: senderIdentity,
      relay: relay,
    );
    receiverClient = _FakeRelayClient(
      deviceId: receiverDeviceId,
      identity: receiverIdentity,
      relay: relay,
    );
    senderClient.peer = receiverClient;
    receiverClient.peer = senderClient;

    channel = RelayChannel(
      client: senderClient,
      identity: senderIdentity,
      historyManager: _NoHistory(),
      pairedDevices: await _trustList(
        workspace,
        'sender-trusts.json',
        receiverIdentity,
      ),
    );

    prompter = _Prompter();
    receiveManager = BatchReceiveManager.forTesting(prompter: prompter);
    coordinator = RelayReceiveCoordinator(
      client: receiverClient,
      identity: receiverIdentity,
      pairedDevices: await _trustList(
        workspace,
        'receiver-trusts.json',
        senderIdentity,
      ),
      contextGetter: () => context,
      isInBackgroundGetter: () => false,
      batchReceiveManager: receiveManager,
      fileTransferService: _SavingService(saveDir),
      historyManager: _NoHistory(),
      resumeStore: ResumeStore(directoryOverride: () => partialDir),
    )..start();
  }

  Future<void> tearDownPair() async {
    await coordinator.stop();
    await senderClient.shutdown();
    await receiverClient.shutdown();
    await relay.close();
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  }

  Future<TransferFileItem> makeFile(String name, int size) async {
    final file = File('${workspace.path}/$name');
    final random = Random(size);
    await file.writeAsBytes(
      List<int>.generate(size, (_) => random.nextInt(256)),
    );
    return TransferFileItem(file: file, transferName: name);
  }

  PeerRef peer() => PeerRef(deviceId: receiverDeviceId, deviceName: 'Receiver');

  /// Runs [body] with a mounted context for the receiver's prompt, on real
  /// time and real sockets.
  void relayTest(String description, Future<void> Function() body) {
    testWidgets(description, (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.runAsync(() async {
        await setUpPair(context);
        try {
          await body().timeout(const Duration(seconds: 60));
        } finally {
          await tearDownPair();
        }
      });
    });
  }

  relayTest('the sender cancelling a file mid-upload stops it on both ends '
      'and the rest of the batch goes on', () async {
    relay.chunkDelay = const Duration(milliseconds: 10);
    final big = await makeFile('big.bin', 8 * 1024 * 1024);
    final small = await makeFile('small.bin', 32 * 1024);
    final cancellation = TransferCancellation();

    final results = await channel.sendFiles(
      peer: peer(),
      files: [big, small],
      cancellation: cancellation,
      onFileProgress: (index, _, bytes, _) {
        if (index == 0 && bytes > 0) cancellation.cancelFile('big.bin');
      },
    );

    expect(results['big.bin']?.errorMessage, appText.transferCancelled);
    expect(
      results['small.bin']?.isSuccess,
      isTrue,
      reason: results['small.bin']?.errorMessage,
    );
    final batch = await prompter.shown.future;
    await prompter.closed.future.timeout(const Duration(seconds: 10));
    expect(batch.files[0].isCancelled, isTrue);
    expect(batch.files[1].isReceived, isTrue);
    expect(File('${saveDir.path}/big.bin').existsSync(), isFalse);
    expect(File('${saveDir.path}/small.bin').lengthSync(), 32 * 1024);
  });

  relayTest('the sender cancelling a queued file tells the receiver, which '
      'stops waiting for it', () async {
    relay.chunkDelay = const Duration(milliseconds: 5);
    final first = await makeFile('first.bin', 2 * 1024 * 1024);
    final queued = await makeFile('queued.bin', 1024);
    final cancellation = TransferCancellation();

    final results = await channel.sendFiles(
      peer: peer(),
      files: [first, queued],
      cancellation: cancellation,
      onFileProgress: (index, _, bytes, _) {
        if (index == 0 && bytes > 0) cancellation.cancelFile('queued.bin');
      },
    );

    expect(
      results['first.bin']?.isSuccess,
      isTrue,
      reason: results['first.bin']?.errorMessage,
    );
    expect(results['queued.bin']?.errorMessage, appText.transferCancelled);
    final batch = await prompter.shown.future;
    await prompter.closed.future.timeout(const Duration(seconds: 10));
    expect(batch.files[1].isCancelled, isTrue);
  });

  relayTest('the receiver cancelling a file mid-download is reported to the '
      'sender as cancelled, not as a broken link', () async {
    relay.chunkDelay = const Duration(milliseconds: 10);
    final big = await makeFile('big.bin', 8 * 1024 * 1024);
    final small = await makeFile('small.bin', 32 * 1024);
    unawaited(
      prompter.shown.future.then((batch) {
        void watch() {
          if (batch.files[0].bytesReceived > 0) {
            batch.removeListener(watch);
            receiveManager.cancelTransfer(batch.files[0].transferId);
          }
        }

        batch.addListener(watch);
      }),
    );

    final stopwatch = Stopwatch()..start();
    final results = await channel.sendFiles(peer: peer(), files: [big, small]);

    expect(results['big.bin']?.errorMessage, appText.transferCancelled);
    expect(
      results['small.bin']?.isSuccess,
      isTrue,
      reason: results['small.bin']?.errorMessage,
    );
    // No retries and no waiting out the ACK timeout.
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 20)));
    await prompter.closed.future.timeout(const Duration(seconds: 10));
  });

  relayTest('a queued file the receiver cancelled is skipped even after its '
      'prompt has closed', () async {
    relay.chunkDelay = const Duration(milliseconds: 5);
    final first = await makeFile('first.bin', 2 * 1024 * 1024);
    final queued = await makeFile('queued.bin', 4 * 1024 * 1024);
    unawaited(
      prompter.shown.future.then((batch) {
        void watch() {
          if (batch.files[0].bytesReceived > 0) {
            batch.removeListener(watch);
            receiveManager.cancelTransfer(batch.files[1].transferId);
          }
        }

        batch.addListener(watch);
      }),
    );

    final stopwatch = Stopwatch()..start();
    final results = await channel.sendFiles(
      peer: peer(),
      files: [first, queued],
    );

    expect(
      results['first.bin']?.isSuccess,
      isTrue,
      reason: results['first.bin']?.errorMessage,
    );
    expect(results['queued.bin']?.errorMessage, appText.transferCancelled);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 20)));
    expect(File('${saveDir.path}/queued.bin').existsSync(), isFalse);
  });

  relayTest('cancel all while the receiver is deciding returns at once and '
      'closes the prompt', () async {
    prompter.autoAccept = false;
    final file = await makeFile('pending.bin', 1024);
    final cancellation = TransferCancellation();

    final pending = channel.sendFiles(
      peer: peer(),
      files: [file],
      cancellation: cancellation,
    );
    final batch = await prompter.shown.future;
    cancellation.cancelAll(['pending.bin']);
    final results = await pending.timeout(const Duration(seconds: 5));

    expect(results['pending.bin']?.errorMessage, appText.transferCancelled);
    await prompter.closed.future.timeout(const Duration(seconds: 5));
    expect(batch.isAccepted, isFalse);
  });
}

Future<PairedDeviceStore> _trustList(
  Directory workspace,
  String fileName,
  IdentityService peer,
) async {
  final store = PairedDeviceStore.forTesting(
    filePath: '${workspace.path}/$fileName',
  );
  await store.upsert(
    PairedDevice(
      deviceId: await peer.getDeviceId(),
      publicKey: await peer.getPublicKeyBase64(),
      deviceName: 'Peer',
      pairedAt: DateTime.now(),
    ),
  );
  return store;
}

/// Stands in for the confirmation dialog: accepts (or waits), and stays up
/// until the batch is over, as the real one does.
class _Prompter extends BatchReceivePrompter {
  bool autoAccept = true;
  final shown = Completer<IncomingBatch>();
  final closed = Completer<void>();

  @override
  Future<void> present(BuildContext context, IncomingBatch batch) async {
    shown.complete(batch);
    if (autoAccept) batch.accept();
    final over = Completer<void>();
    void check() {
      final done = batch.isDecided && (!batch.isAccepted || batch.isFinished);
      if (done && !over.isCompleted) over.complete();
    }

    batch.addListener(check);
    check();
    await over.future;
    batch.removeListener(check);
    closed.complete();
  }
}

class _SavingService extends FileTransferService {
  _SavingService(this.dir);

  final Directory dir;

  @override
  Future<OperationResult<TransferData>> adoptReceivedFile({
    required File source,
    required String fileName,
    required int fileSize,
  }) async {
    final saved = await source.copy('${dir.path}/$fileName');
    return OperationResult.success(
      data: TransferData(savedPath: saved.path, bytesTransferred: fileSize),
    );
  }
}

class _NoHistory extends TransferHistoryManager {
  @override
  Future<void> saveTransferHistoryBatch(
    List<TransferHistory> histories,
  ) async {}
}

/// The relay's data plane: each stream's upload is forwarded to whoever
/// downloads the same stream id. When either side goes away, so does the
/// other's connection.
class _MiniRelay {
  late HttpServer _server;
  final Map<String, Completer<HttpRequest>> _downloads = {};
  Duration chunkDelay = Duration.zero;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) => unawaited(_handle(request)));
  }

  Future<void> close() => _server.close(force: true);

  Uri uri(String streamId) =>
      Uri.parse('http://127.0.0.1:${_server.port}/v1/stream/$streamId');

  Future<void> _handle(HttpRequest request) async {
    final id = request.uri.pathSegments.last;
    final slot = _downloads.putIfAbsent(id, Completer<HttpRequest>.new);
    if (request.method == 'GET') {
      slot.complete(request);
      return;
    }

    final HttpRequest download;
    try {
      download = await slot.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      await _quietly(() async {
        request.response.statusCode = HttpStatus.gone;
        await request.response.close();
      });
      return;
    }

    final out = download.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.binary
      ..contentLength = request.contentLength;
    unawaited(out.done.then((_) {}, onError: (_) {}));
    try {
      await for (final chunk in request) {
        out.add(chunk);
        await out.flush();
        if (chunkDelay > Duration.zero) {
          await Future<void>.delayed(chunkDelay);
        }
      }
      await out.close();
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
    } catch (_) {
      // A short body against the declared length drops the download's socket.
      await _quietly(out.close);
      await _quietly(request.response.close);
    }
  }

  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }
}

class _FakeRelayClient extends RelayClient {
  _FakeRelayClient({
    required this.deviceId,
    required IdentityService identity,
    required this.relay,
  }) : super(identity: identity);

  final String deviceId;
  final _MiniRelay relay;
  final StreamController<RelayInboundPayload> _inbound =
      StreamController<RelayInboundPayload>.broadcast();
  var _streamSeq = 0;
  Future<void> _delivery = Future.value();

  _FakeRelayClient? peer;

  @override
  bool get isConnected => true;

  @override
  Future<bool> connect() async => true;

  @override
  bool isOnline(String peerDeviceId) => true;

  @override
  Stream<RelayInboundPayload> get payloads => _inbound.stream;

  @override
  Uri? streamUri(String streamId) => relay.uri(streamId);

  @override
  Future<Map<String, String>> streamHeaders(String streamId) async => {};

  @override
  Future<OperationResult<String>> createStream({
    required String peerDeviceId,
    required String role,
  }) async {
    _streamSeq++;
    return OperationResult.success(data: '$deviceId-$_streamSeq');
  }

  @override
  Future<OperationResult<void>> sendPayload({
    required String toDeviceId,
    required Map<String, dynamic> payload,
    String kind = RelayKind.transfer,
  }) async {
    await peer?._deliver(deviceId, payload);
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
      return OperationResult.failure('no reply');
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
      return OperationResult.failure('no reply');
    } on StateError {
      return OperationResult.failure('closed');
    }
  }

  Future<void> _deliver(String from, Map<String, dynamic> payload) {
    _delivery = _delivery.then((_) async {
      if (_inbound.isClosed) return;
      var delivered = payload;
      if (payload['type'] == RelayPayloadType.secure) {
        final opened = await sessions.open(from, payload);
        if (opened == null) return;
        delivered = opened;
      }
      if (_inbound.isClosed) return;
      _inbound.add(RelayInboundPayload(fromDeviceId: from, payload: delivered));
    });
    return _delivery;
  }

  Future<void> shutdown() => _inbound.close();
}
