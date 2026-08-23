@Tags(['live'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/paired_device.dart';
import 'package:icy_easy_send/models/relay_config.dart';
import 'package:icy_easy_send/models/transfer_file_item.dart';
import 'package:icy_easy_send/services/identity_service.dart';
import 'package:icy_easy_send/services/paired_device_store.dart';
import 'package:icy_easy_send/services/relay/relay_client.dart';
import 'package:icy_easy_send/services/relay/relay_crypto.dart';
import 'package:icy_easy_send/services/relay/relay_crypto_worker.dart';
import 'package:icy_easy_send/services/relay/relay_frame_codec.dart';
import 'package:icy_easy_send/services/relay/relay_protocol.dart';
import 'package:icy_easy_send/services/relay/relay_receive_coordinator.dart';
import 'package:icy_easy_send/transport/relay_channel.dart';
import 'package:icy_easy_send/transport/transport_channel.dart';
import 'package:icy_easy_send/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end encrypted transfers over a real `relayd`.
///
/// The sender is the production [RelayChannel]; the receiver is scripted here
/// rather than being the real coordinator, because the coordinator's accept
/// path goes through a confirmation dialog and therefore needs a widget tree.
/// What this covers is everything between the two: the session handshake, the
/// signed manifest, stream allocation, the rendezvous on the data plane, the
/// encrypted frames, and the acknowledgement that decides whether a file
/// counts as delivered.
///
/// ```
/// flutter test --tags live \
///   --dart-define=RELAY_TEST_URL=http://127.0.0.1:18443 \
///   --dart-define=RELAY_TEST_TOKEN=...
/// ```
const String _serverUrl = String.fromEnvironment('RELAY_TEST_URL');
const String _token = String.fromEnvironment('RELAY_TEST_TOKEN');

void main() {
  final configured = _serverUrl.isNotEmpty && _token.isNotEmpty;

  group(
    'relayed transfers',
    () {
      late Directory workspace;
      late RelayClient senderClient;
      late RelayClient receiverClient;
      late String receiverDeviceId;
      late RelayChannel channel;
      late _ScriptedReceiver receiver;

      setUp(() async {
        TestWidgetsFlutterBinding.ensureInitialized();
        SharedPreferences.setMockInitialValues({});

        _allowRealNetwork();

        workspace = await Directory.systemTemp.createTemp('relay-transfer');
        final config = RelayConfig(
          serverUrl: _serverUrl,
          token: _token,
          enabled: true,
        );

        final senderIdentity = IdentityService.forTesting(
          filePath: _path(workspace, 'sender.key'),
        );
        final receiverIdentity = IdentityService.forTesting(
          filePath: _path(workspace, 'receiver.key'),
        );
        receiverDeviceId = await receiverIdentity.getDeviceId();

        senderClient = RelayClient(identity: senderIdentity);
        receiverClient = RelayClient(identity: receiverIdentity);
        await senderClient.applyConfig(config);
        await receiverClient.applyConfig(config);
        expect(await senderClient.connect(), isTrue);
        expect(await receiverClient.connect(), isTrue);

        receiver = _ScriptedReceiver(
          client: receiverClient,
          identity: receiverIdentity,
          senderPublicKey: await senderIdentity.getPublicKeyBytes(),
        )..start();

        // Neither end will talk to a device it has not paired with, so both
        // trust lists are seeded before anything is sent.
        channel = RelayChannel(
          client: senderClient,
          identity: senderIdentity,
          pairedDevices: await _trustList(
            workspace,
            'sender-trusts.json',
            peer: receiverIdentity,
          ),
        );
      });

      tearDown(() async {
        await receiver.dispose();
        await senderClient.dispose();
        await receiverClient.dispose();
        if (await workspace.exists()) {
          await workspace.delete(recursive: true);
        }
      });

      PeerRef peer() =>
          PeerRef(deviceId: receiverDeviceId, deviceName: 'Receiver');

      Future<TransferFileItem> makeFile(String name, int size) async {
        final file = File(_path(workspace, name));
        final random = Random(size);
        await file.writeAsBytes(
          List<int>.generate(size, (_) => random.nextInt(256)),
        );
        return TransferFileItem(file: file, transferName: name);
      }

      test('delivers a file byte for byte', () async {
        final item = await makeFile('payload.bin', 512 * 1024);
        final expected = await item.file.readAsBytes();

        final results = await channel.sendFiles(peer: peer(), files: [item]);

        expect(results['payload.bin']!.isSuccess, isTrue,
            reason: results['payload.bin']!.errorMessage);
        expect(receiver.received['payload.bin'], equals(expected));
      });

      test('the manifest is signed by the paired key', () async {
        final item = await makeFile('signed.bin', 1024);

        await channel.sendFiles(peer: peer(), files: [item]);

        expect(receiver.manifestVerified, isTrue);
        // The name reached the receiver, so the encrypted manifest was not
        // merely unreadable to everyone.
        expect(receiver.received.keys, contains('signed.bin'));
      });

      test('what crosses the relay is not the file', () async {
        final item = await makeFile('secret.bin', 128 * 1024);
        final plaintext = await item.file.readAsBytes();

        await channel.sendFiles(peer: peer(), files: [item]);

        final wire = receiver.wire['secret.bin']!;
        // Framed and tagged, so longer than the file and equal to it nowhere.
        expect(wire.length, RelayFrameCodec.encryptedLength(plaintext.length));
        expect(_contains(wire, plaintext.sublist(0, 64)), isFalse);
      });

      test('delivers several files in one batch', () async {
        final files = [
          await makeFile('a.bin', 1024),
          await makeFile('b.bin', 64 * 1024),
          await makeFile('c.bin', 4),
        ];

        final results = await channel.sendFiles(peer: peer(), files: files);

        expect(results, hasLength(3));
        for (final entry in results.entries) {
          expect(entry.value.isSuccess, isTrue, reason: entry.value.errorMessage);
        }
        expect(receiver.received.keys, containsAll(['a.bin', 'b.bin', 'c.bin']));
      });

      test('handles an empty file, which has no bytes to rendezvous on', () async {
        final item = await makeFile('empty.bin', 0);

        final results = await channel.sendFiles(peer: peer(), files: [item]);

        expect(results['empty.bin']!.isSuccess, isTrue,
            reason: results['empty.bin']!.errorMessage);
        expect(receiver.received['empty.bin'], isEmpty);
        // Empty on the inside, one frame on the wire: that frame is what says
        // the file ended where the sender meant it to.
        expect(receiver.wire['empty.bin'], isNotEmpty);
      });

      test('reports progress that ends at the full size', () async {
        final item = await makeFile('progress.bin', 256 * 1024);
        final observed = <int>[];

        await channel.sendFiles(
          peer: peer(),
          files: [item],
          onProgress: (_, bytes, _) => observed.add(bytes),
        );

        expect(observed, isNotEmpty);
        expect(observed.last, 256 * 1024);
        // Progress must never run backwards, or the UI jumps around.
        for (var i = 1; i < observed.length; i++) {
          expect(observed[i], greaterThanOrEqualTo(observed[i - 1]));
        }
      });

      test('fails every file when the receiver declines the batch', () async {
        receiver.accept = false;
        final files = [
          await makeFile('a.bin', 16),
          await makeFile('b.bin', 16),
        ];

        final results = await channel.sendFiles(peer: peer(), files: files);

        expect(results, hasLength(2));
        expect(results.values.every((r) => !r.isSuccess), isTrue);
        expect(receiver.received, isEmpty);
      });

      test('sends only the tail when the receiver already has the head',
          () async {
        const chunkSize = AppConstants.relayChunkSize;
        final item = await makeFile('resumed.bin', chunkSize * 3 + 100);
        final plaintext = await item.file.readAsBytes();

        // Stand in for a previous attempt that got two chunks onto disk.
        final head = plaintext.sublist(0, chunkSize * 2);
        receiver.resumeOffers['resumed.bin'] = (
          chunks: 2,
          hash: base64Encode(
            (await Sha256().hash(
              plaintext.sublist(chunkSize, chunkSize * 2),
            )).bytes,
          ),
          prefix: head,
        );

        final results = await channel.sendFiles(peer: peer(), files: [item]);

        expect(results['resumed.bin']!.isSuccess, isTrue,
            reason: results['resumed.bin']!.errorMessage);
        expect(receiver.startChunks['resumed.bin'], 2);
        // Only two chunks and change crossed the wire, but what the receiver
        // ends up holding is the whole file.
        expect(
          receiver.wire['resumed.bin']!.length,
          RelayFrameCodec.encryptedLengthFrom(plaintext.length, 2),
        );
        expect(receiver.received['resumed.bin'], equals(plaintext));
      });

      test('starts over when the local file no longer matches the hash',
          () async {
        const chunkSize = AppConstants.relayChunkSize;
        final item = await makeFile('changed.bin', chunkSize * 3);
        final plaintext = await item.file.readAsBytes();

        // The receiver holds two chunks of some other version of this file.
        receiver.resumeOffers['changed.bin'] = (
          chunks: 2,
          hash: base64Encode(
            (await Sha256().hash(List<int>.filled(chunkSize, 0))).bytes,
          ),
          prefix: List<int>.filled(chunkSize * 2, 0),
        );

        final results = await channel.sendFiles(peer: peer(), files: [item]);

        expect(results['changed.bin']!.isSuccess, isTrue,
            reason: results['changed.bin']!.errorMessage);
        // The sender checked its own copy of the chunk the hash described,
        // found something else, and refused the shortcut.
        expect(receiver.startChunks['changed.bin'], 0);
        expect(receiver.received['changed.bin'], equals(plaintext));
      });

      test('retries from the break when the stream drops mid-file', () async {
        const chunkSize = AppConstants.relayChunkSize;
        final item = await makeFile('flaky.bin', chunkSize * 4);
        final plaintext = await item.file.readAsBytes();

        // The receiver takes two chunks, drops the connection, and says where
        // it stopped. The sender should come back for the rest by itself.
        receiver.breakAfterChunks = 2;

        final results = await channel.sendFiles(peer: peer(), files: [item]);

        expect(results['flaky.bin']!.isSuccess, isTrue,
            reason: results['flaky.bin']!.errorMessage);
        expect(receiver.startChunks['flaky.bin'], 2);
        expect(receiver.received['flaky.bin'], equals(plaintext));
      });

      test('fails the file when the receiver cannot save it', () async {
        receiver.failWrites = true;
        final item = await makeFile('doomed.bin', 32 * 1024);

        final results = await channel.sendFiles(peer: peer(), files: [item]);

        // The upload itself succeeds — the relay forwarded every byte — so the
        // only thing that can catch this is the receiver's acknowledgement.
        expect(results['doomed.bin']!.isSuccess, isFalse);
        expect(results['doomed.bin']!.errorMessage, contains('disk on fire'));
      });

      test('refuses to send to a peer with no device id', () async {
        final item = await makeFile('nowhere.bin', 16);

        final results = await channel.sendFiles(
          peer: PeerRef.lanAddress('192.168.1.5'),
          files: [item],
        );

        expect(results['nowhere.bin']!.isSuccess, isFalse);
      });

      test('refuses to send to a device that was never paired', () async {
        final item = await makeFile('stranger.bin', 16);

        final results = await channel.sendFiles(
          peer: const PeerRef(deviceId: 'ffffffffffffffffffffffffffffffff'),
          files: [item],
        );

        expect(results['stranger.bin']!.isSuccess, isFalse);
      });

      test('probe reports the peer online once both subscribe', () async {
        final senderDeviceId = await IdentityService.forTesting(
          filePath: _path(workspace, 'sender.key'),
        ).getDeviceId();

        final online = senderClient.presenceChanges.firstWhere(
          (event) => event.deviceId == receiverDeviceId && event.online,
        );
        await senderClient.setSubscriptions([receiverDeviceId]);
        await receiverClient.setSubscriptions([senderDeviceId]);
        await online.timeout(const Duration(seconds: 5));

        final result = await channel.probe(peer());
        expect(result.ok, isTrue, reason: result.errorMessage);
      });

      test('probe reports unreachable for a peer that is not online', () async {
        final result = await channel.probe(
          const PeerRef(deviceId: 'ffffffffffffffffffffffffffffffff'),
        );

        expect(result.ok, isFalse);
        expect(result.attempted, isTrue);
      });
    },
    skip: configured
        ? false
        : 'set RELAY_TEST_URL and RELAY_TEST_TOKEN to run against a relayd',
  );

  group(
    'RelayReceiveCoordinator admission',
    () {
      late Directory workspace;
      late RelayClient senderClient;
      late RelayClient receiverClient;
      late IdentityService senderIdentity;
      late IdentityService receiverIdentity;
      late String senderDeviceId;
      late String receiverDeviceId;
      late String senderPublicKey;
      late RelayChannel channel;
      late RelayReceiveCoordinator coordinator;

      setUp(() async {
        TestWidgetsFlutterBinding.ensureInitialized();
        SharedPreferences.setMockInitialValues({});

        _allowRealNetwork();

        workspace = await Directory.systemTemp.createTemp('relay-admission');
        final config = RelayConfig(
          serverUrl: _serverUrl,
          token: _token,
          enabled: true,
        );

        senderIdentity = IdentityService.forTesting(
          filePath: _path(workspace, 'sender.key'),
        );
        receiverIdentity = IdentityService.forTesting(
          filePath: _path(workspace, 'receiver.key'),
        );
        senderDeviceId = await senderIdentity.getDeviceId();
        senderPublicKey = await senderIdentity.getPublicKeyBase64();
        receiverDeviceId = await receiverIdentity.getDeviceId();

        senderClient = RelayClient(identity: senderIdentity);
        receiverClient = RelayClient(identity: receiverIdentity);
        await senderClient.applyConfig(config);
        await receiverClient.applyConfig(config);
        expect(await senderClient.connect(), isTrue);
        expect(await receiverClient.connect(), isTrue);

        channel = RelayChannel(
          client: senderClient,
          identity: senderIdentity,
          pairedDevices: await _trustList(
            workspace,
            'sender-trusts.json',
            peer: receiverIdentity,
          ),
        );
      });

      tearDown(() async {
        await coordinator.stop();
        await senderClient.dispose();
        await receiverClient.dispose();
        if (await workspace.exists()) {
          await workspace.delete(recursive: true);
        }
      });

      /// Sends one file to a coordinator configured the given way, and returns
      /// the reason the sender was given.
      Future<String> sendOne({
        required bool paired,
        required bool inBackground,
      }) async {
        final store = PairedDeviceStore.forTesting(
          filePath: _path(workspace, 'paired-$paired-$inBackground.json'),
        );
        if (paired) {
          await store.upsert(
            PairedDevice(
              deviceId: senderDeviceId,
              publicKey: senderPublicKey,
              deviceName: 'Sender',
              pairedAt: DateTime.now(),
            ),
          );
        }

        coordinator = RelayReceiveCoordinator(
          client: receiverClient,
          identity: receiverIdentity,
          pairedDevices: store,
          isInBackgroundGetter: () => inBackground,
          contextGetter: () => null,
        )..start();

        final file = File(_path(workspace, 'x.bin'));
        await file.writeAsBytes(List<int>.filled(16, 7));

        final results = await channel.sendFiles(
          peer: PeerRef(deviceId: receiverDeviceId),
          files: [TransferFileItem(file: file, transferName: 'x.bin')],
        );
        return results['x.bin']!.errorMessage ?? '';
      }

      test('refuses a sender that is not in the trust list', () async {
        // Anyone holding the server token can address any device id, so the
        // trust list is the only thing standing between a stranger and the
        // user's confirmation dialog.
        final error = await sendOne(paired: false, inBackground: false);

        expect(error, isNotEmpty);
        // A refusal, not a timeout: the sender is told why straight away.
        expect(error, isNot(contains('没有响应')));
      });

      test('refuses when there is no UI to ask the user with', () async {
        final error = await sendOne(paired: true, inBackground: true);

        expect(error, isNotEmpty);
        expect(error, isNot(contains('没有响应')));
      });
    },
    skip: configured
        ? false
        : 'set RELAY_TEST_URL and RELAY_TEST_TOKEN to run against a relayd',
  );
}

String _path(Directory directory, String name) =>
    '${directory.path}${Platform.pathSeparator}$name';

/// A trust list holding exactly one peer.
Future<PairedDeviceStore> _trustList(
  Directory workspace,
  String fileName, {
  required IdentityService peer,
}) async {
  final store = PairedDeviceStore.forTesting(
    filePath: _path(workspace, fileName),
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

/// Whether [haystack] holds [needle] anywhere in it.
bool _contains(List<int> haystack, List<int> needle) {
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) {
      return true;
    }
  }
  return false;
}

/// Restores real HTTP.
///
/// Initializing the test binding installs an [HttpOverrides] whose client
/// answers 400 to everything, which is the right default for unit tests and
/// exactly wrong for these: the whole point is to talk to a running relay.
void _allowRealNetwork() {
  HttpOverrides.global = null;
}

/// A receiver that speaks the encrypted transfer protocol without any UI.
class _ScriptedReceiver {
  final RelayClient client;
  final IdentityService identity;

  /// The sender's long-term key, which the manifest has to be signed by.
  final Uint8List senderPublicKey;

  /// Whether to accept the next manifest.
  bool accept = true;

  /// Simulates the file reaching the receiver but failing to be stored, which
  /// is the case the upload's own status code cannot detect.
  bool failWrites = false;

  /// Resume offers to make in `transfer.accept`, by file name.
  final Map<String, ({int chunks, String hash, List<int> prefix})>
  resumeOffers = {};

  /// Drops the connection once, after this many chunks have been decrypted.
  int? breakAfterChunks;

  /// The start chunk the sender actually chose, by file name.
  final Map<String, int> startChunks = {};

  /// Plaintext of every file that arrived, by name. For a resumed file this
  /// is what the receiver would hold on disk: the part it kept, plus the tail.
  final Map<String, List<int>> received = {};

  /// The bytes as they crossed the relay, by name.
  final Map<String, List<int>> wire = {};

  /// Whether the last manifest carried a signature made by [senderPublicKey].
  bool manifestVerified = false;

  final Map<String, RelaySecureSession> _sessions = {};
  final Map<String, String> _names = {};
  RelayCryptoWorker? _worker;

  _ScriptedReceiver({
    required this.client,
    required this.identity,
    required this.senderPublicKey,
  });

  void start() {
    client.payloads.listen((inbound) {
      switch (inbound.payload['type']) {
        case RelayPayloadType.transferOffer:
          unawaited(_onOffer(inbound));
        case RelayPayloadType.transferManifest:
          unawaited(_onManifest(inbound));
        case RelayPayloadType.fileBegin:
          unawaited(_onFileBegin(inbound));
      }
    });
  }

  Future<void> dispose() async {
    await _worker?.dispose();
    _worker = null;
  }

  Future<void> _onOffer(RelayInboundPayload inbound) async {
    final offer = TransferOffer.tryParse(inbound.payload)!;
    final answered = await RelayCrypto.answerOffer(
      offer: offer,
      senderDeviceId: inbound.fromDeviceId,
      receiverDeviceId: await identity.getDeviceId(),
      identity: identity,
    );

    final session = answered.data!.session;
    _sessions[offer.sessionId] = session;
    // Registering it here is what lets the client hand the rest of this
    // session's messages over already decrypted.
    client.sessions.add(session);

    await client.sendPayload(
      toDeviceId: inbound.fromDeviceId,
      payload: answered.data!.answer.toJson(),
    );
  }

  Future<void> _onManifest(RelayInboundPayload inbound) async {
    final manifest = TransferManifest.tryParse(inbound.payload)!;
    final session = _sessions[manifest.sessionId]!;

    manifestVerified = await RelayCrypto.verifySenderSignature(
      transcript: session.transcript,
      signature: manifest.signature,
      senderPublicKey: senderPublicKey,
    );

    for (final file in manifest.files) {
      _names[file.fileId] = file.name;
    }

    await client.sendPayload(
      toDeviceId: inbound.fromDeviceId,
      payload: await session.seal(
        TransferAccept(
          sessionId: manifest.sessionId,
          accepted: accept,
          receiverDeviceName: 'Scripted',
          files: [
            for (final file in manifest.files)
              AcceptedFile(
                fileId: file.fileId,
                resumeFromChunk: resumeOffers[file.name]?.chunks ?? 0,
                lastChunkHash: resumeOffers[file.name]?.hash,
              ),
          ],
          reason: accept ? null : 'declined',
        ).toJson(),
      ),
    );
  }

  Future<void> _onFileBegin(RelayInboundPayload inbound) async {
    final begin = FileBegin.tryParse(inbound.payload)!;
    final session = _sessions[begin.sessionId]!;
    final name = _names[begin.fileId] ?? begin.fileId;
    startChunks[name] = begin.startChunk;

    final dio = Dio();
    try {
      final response = await dio.get<ResponseBody>(
        client.streamUri(begin.streamId)!.toString(),
        options: Options(
          headers: await client.streamHeaders(begin.streamId),
          responseType: ResponseType.stream,
          validateStatus: (status) => status != null,
        ),
      );

      final codec = RelayFrameCodec(
        worker: _worker ??= await RelayCryptoWorker.spawn(),
      );
      final key = await session.keys.fileKey(
        begin.fileId,
        attempt: begin.attempt,
      );

      // Breaking mid-stream has to happen while the bytes are still arriving,
      // so this path decrypts as it reads instead of buffering first.
      if (breakAfterChunks != null) {
        await _breakMidStream(inbound, session, begin, codec, key, response);
        return;
      }

      // Buffered rather than piped so the tests can look at the ciphertext as
      // the relay saw it, which is the whole point of the exercise.
      final ciphertext = <int>[];
      await for (final chunk in response.data!.stream) {
        ciphertext.addAll(chunk);
      }
      wire[name] = ciphertext;

      final plaintext = <int>[];
      await for (final chunk in codec.decrypt(
        Stream<List<int>>.value(ciphertext),
        key,
        chunkCount: begin.chunkCount,
        startChunk: begin.startChunk,
      )) {
        plaintext.addAll(chunk);
      }

      if (failWrites) {
        await _report(inbound, session, begin, ok: false, error: 'disk on fire');
        return;
      }

      // What the receiver ends up holding is whatever it kept from the earlier
      // attempt followed by what just arrived.
      final held = resumeOffers[name]?.prefix ?? const <int>[];
      received[name] = [
        ...held.take(begin.startChunk * AppConstants.relayChunkSize),
        ...plaintext,
      ];
      await _report(
        inbound,
        session,
        begin,
        ok: true,
        bytes: received[name]!.length,
      );
    } finally {
      dio.close();
    }
  }

  /// Abandons the download partway and tells the sender where to pick up.
  Future<void> _breakMidStream(
    RelayInboundPayload inbound,
    RelaySecureSession session,
    FileBegin begin,
    RelayFrameCodec codec,
    RelayFileKey key,
    Response<ResponseBody> response,
  ) async {
    final name = _names[begin.fileId] ?? begin.fileId;
    final limit = breakAfterChunks!;
    breakAfterChunks = null;

    final kept = <int>[];
    var chunks = 0;
    await for (final chunk in codec.decrypt(
      response.data!.stream,
      key,
      chunkCount: begin.chunkCount,
      startChunk: begin.startChunk,
    )) {
      kept.addAll(chunk);
      chunks++;
      if (chunks >= limit) {
        // Leaving the loop cancels the subscription, which drops the HTTP
        // stream — the same thing a real network break does to the sender.
        break;
      }
    }

    final resumeFrom = begin.startChunk + chunks;
    resumeOffers[name] = (
      chunks: resumeFrom,
      hash: '',
      prefix: [
        ...(resumeOffers[name]?.prefix ?? const <int>[]).take(
          begin.startChunk * AppConstants.relayChunkSize,
        ),
        ...kept,
      ],
    );

    await _report(
      inbound,
      session,
      begin,
      ok: false,
      resumeFromChunk: resumeFrom,
      error: 'link dropped',
    );
  }

  Future<void> _report(
    RelayInboundPayload inbound,
    RelaySecureSession session,
    FileBegin begin, {
    required bool ok,
    int bytes = 0,
    int? resumeFromChunk,
    String? error,
  }) async {
    await client.sendPayload(
      toDeviceId: inbound.fromDeviceId,
      payload: await session.seal(
        FileDone(
          sessionId: begin.sessionId,
          fileId: begin.fileId,
          ok: ok,
          bytes: bytes,
          resumeFromChunk: resumeFromChunk,
          error: error,
        ).toJson(),
      ),
    );
  }
}
