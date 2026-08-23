import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/identity_service.dart';
import 'package:icy_easy_send/services/relay/relay_crypto.dart';
import 'package:icy_easy_send/services/relay/relay_protocol.dart';

/// End-to-end encryption for relayed transfers.
///
/// The relay is the adversary these tests are written against: it sees every
/// handshake message and may change any of them, so the properties that matter
/// are that both honest ends agree on keys and that anything else fails
/// closed.
void main() {
  late Directory tempDir;
  late IdentityService senderIdentity;
  late IdentityService receiverIdentity;
  late String senderDeviceId;
  late String receiverDeviceId;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('icy_relay_crypto');
    senderIdentity = IdentityService.forTesting(
      filePath: '${tempDir.path}/sender.key',
    );
    receiverIdentity = IdentityService.forTesting(
      filePath: '${tempDir.path}/receiver.key',
    );
    senderDeviceId = await senderIdentity.getDeviceId();
    receiverDeviceId = await receiverIdentity.getDeviceId();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  /// Runs the handshake both ends would run over a well-behaved relay.
  Future<(RelaySecureSession, RelaySecureSession)> handshake({
    String sessionId = 'session-1',
  }) async {
    final offer = await RelayCrypto.createOffer(sessionId);

    final answered = await RelayCrypto.answerOffer(
      offer: offer.payload,
      senderDeviceId: senderDeviceId,
      receiverDeviceId: receiverDeviceId,
      identity: receiverIdentity,
    );
    expect(answered.isSuccess, isTrue, reason: answered.errorMessage);

    final completed = await RelayCrypto.completeOffer(
      offer: offer,
      answer: answered.data!.answer,
      senderDeviceId: senderDeviceId,
      receiverDeviceId: receiverDeviceId,
      receiverPublicKey: await receiverIdentity.getPublicKeyBytes(),
    );
    expect(completed.isSuccess, isTrue, reason: completed.errorMessage);

    return (completed.data!, answered.data!.session);
  }

  group('handshake', () {
    test('both ends derive the same transcript', () async {
      final (sender, receiver) = await handshake();
      expect(sender.transcript, receiver.transcript);
    });

    test('the sender can read what the receiver sealed, and back', () async {
      final (sender, receiver) = await handshake();

      final toReceiver = await sender.seal({'type': 'x', 'hello': 'sender'});
      expect(await receiver.open(toReceiver), containsPair('hello', 'sender'));

      final toSender = await receiver.seal({'type': 'x', 'hello': 'receiver'});
      expect(await sender.open(toSender), containsPair('hello', 'receiver'));
    });

    test('a session cannot read its own outbound messages', () async {
      final (sender, _) = await handshake();

      // Distinct keys per direction: a relay cannot bounce a message back at
      // the device that sent it and have it accepted as the peer's answer.
      final sealed = await sender.seal({'type': 'x'});
      expect(await sender.open(sealed), isNull);
    });

    test('an answer signed by another device is refused', () async {
      final offer = await RelayCrypto.createOffer('session-1');
      final impostor = IdentityService.forTesting(
        filePath: '${tempDir.path}/impostor.key',
      );

      final answered = await RelayCrypto.answerOffer(
        offer: offer.payload,
        senderDeviceId: senderDeviceId,
        receiverDeviceId: receiverDeviceId,
        identity: impostor,
      );

      final completed = await RelayCrypto.completeOffer(
        offer: offer,
        answer: answered.data!.answer,
        senderDeviceId: senderDeviceId,
        receiverDeviceId: receiverDeviceId,
        receiverPublicKey: await receiverIdentity.getPublicKeyBytes(),
      );

      expect(completed.isFailure, isTrue);
    });

    test('a swapped ephemeral key breaks the answer signature', () async {
      final offer = await RelayCrypto.createOffer('session-1');
      final answered = await RelayCrypto.answerOffer(
        offer: offer.payload,
        senderDeviceId: senderDeviceId,
        receiverDeviceId: receiverDeviceId,
        identity: receiverIdentity,
      );

      // What a man-in-the-middle relay would do: keep the signature, replace
      // the key it covers.
      final attacker = await RelayCrypto.createOffer('session-1');
      final tampered = TransferAnswer(
        sessionId: 'session-1',
        ephemeralPublicKey: attacker.payload.ephemeralPublicKey,
        nonce: answered.data!.answer.nonce,
        signature: answered.data!.answer.signature,
      );

      final completed = await RelayCrypto.completeOffer(
        offer: offer,
        answer: tampered,
        senderDeviceId: senderDeviceId,
        receiverDeviceId: receiverDeviceId,
        receiverPublicKey: await receiverIdentity.getPublicKeyBytes(),
      );

      expect(completed.isFailure, isTrue);
    });

    test('the sender signature is verified against the transcript', () async {
      final (sender, receiver) = await handshake();

      final signature = await RelayCrypto.signAsSender(
        sender.transcript,
        identity: senderIdentity,
      );

      expect(
        await RelayCrypto.verifySenderSignature(
          transcript: receiver.transcript,
          signature: signature,
          senderPublicKey: await senderIdentity.getPublicKeyBytes(),
        ),
        isTrue,
      );
      expect(
        await RelayCrypto.verifySenderSignature(
          transcript: receiver.transcript,
          signature: signature,
          senderPublicKey: await receiverIdentity.getPublicKeyBytes(),
        ),
        isFalse,
      );
    });

    test('the receiver signature cannot be replayed as the sender one',
        () async {
      final offer = await RelayCrypto.createOffer('session-1');
      final answered = await RelayCrypto.answerOffer(
        offer: offer.payload,
        senderDeviceId: senderDeviceId,
        receiverDeviceId: receiverDeviceId,
        identity: receiverIdentity,
      );
      final session = answered.data!.session;

      // Domain separation: "R" ‖ transcript must not verify as "S" ‖ same.
      expect(
        await RelayCrypto.verifySenderSignature(
          transcript: session.transcript,
          signature: answered.data!.answer.signature,
          senderPublicKey: await receiverIdentity.getPublicKeyBytes(),
        ),
        isFalse,
      );
    });

    test('sessions with different ids derive different keys', () async {
      final (senderA, _) = await handshake(sessionId: 'session-a');
      final (_, receiverB) = await handshake(sessionId: 'session-b');

      final sealed = await senderA.seal({'type': 'x'});
      expect(await receiverB.open(sealed), isNull);
    });
  });

  group('sealed messages', () {
    test('a flipped ciphertext bit is rejected', () async {
      final (sender, receiver) = await handshake();
      final sealed = await sender.seal({'type': 'x', 'v': 1});

      final raw = base64Decode(sealed['ct'] as String);
      raw[0] ^= 0x01;
      sealed['ct'] = base64Encode(raw);

      expect(await receiver.open(sealed), isNull);
    });

    test('a replayed message is rejected', () async {
      final (sender, receiver) = await handshake();
      final sealed = await sender.seal({'type': 'x', 'v': 1});

      expect(await receiver.open(Map.of(sealed)), isNotNull);
      expect(await receiver.open(Map.of(sealed)), isNull);
    });

    test('a message renumbered to another sequence is rejected', () async {
      final (sender, receiver) = await handshake();
      final first = await sender.seal({'type': 'x', 'v': 1});
      await sender.seal({'type': 'x', 'v': 2});

      // The sequence is part of the additional data, so moving a message to
      // another slot invalidates it rather than reordering the conversation.
      first['seq'] = 1;
      expect(await receiver.open(first), isNull);
    });

    test('a wrapper for an unknown session is rejected by the registry',
        () async {
      final (sender, receiver) = await handshake();
      final registry = RelaySessionRegistry()..add(receiver);
      final sealed = await sender.seal({'type': 'x'});

      expect(await registry.open(senderDeviceId, sealed), isNotNull);
      expect(
        await registry.open('another-device-id', await sender.seal({'type': 'x'})),
        isNull,
      );

      registry.remove(receiver.sessionId);
      expect(
        await registry.open(senderDeviceId, await sender.seal({'type': 'x'})),
        isNull,
      );
    });
  });

  group('file keys', () {
    test('both ends derive the same key and nonce prefix', () async {
      final (sender, receiver) = await handshake();

      final mine = await sender.keys.fileKey('0123456789abcdef0123456789abcdef');
      final theirs = await receiver.keys.fileKey(
        '0123456789abcdef0123456789abcdef',
      );

      expect(mine.key, theirs.key);
      expect(mine.noncePrefix, theirs.noncePrefix);
    });

    test('each file gets its own key, so chunk counters cannot collide',
        () async {
      final (sender, _) = await handshake();

      final first = await sender.keys.fileKey('a' * 32);
      final second = await sender.keys.fileKey('b' * 32);

      expect(first.key, isNot(second.key));
      expect(first.noncePrefix, isNot(second.noncePrefix));
    });

    test('each attempt at a file gets its own key', () async {
      final (sender, receiver) = await handshake();

      final first = await sender.keys.fileKey('a' * 32);
      final retry = await sender.keys.fileKey('a' * 32, attempt: 1);

      // A retry re-sends chunks under the numbers they already had, and the
      // nonce comes from the number. Were the key the same, those chunks would
      // be encrypted twice under one key and nonce — which stays harmless only
      // as long as the file on disk did not change in between. It need not.
      expect(first.key, isNot(retry.key));
      expect(first.noncePrefix, isNot(retry.noncePrefix));
      expect(first.nonceFor(3), isNot(retry.nonceFor(3)));

      // Both ends still have to land on the same material for a given attempt.
      final theirs = await receiver.keys.fileKey('a' * 32, attempt: 1);
      expect(retry.key, theirs.key);
      expect(retry.noncePrefix, theirs.noncePrefix);
    });

    test('the nonce is the prefix followed by the chunk index', () async {
      final (sender, _) = await handshake();
      final key = await sender.keys.fileKey('a' * 32);

      final nonce = key.nonceFor(258);
      expect(nonce.length, 12);
      expect(nonce.sublist(0, 4), key.noncePrefix);
      expect(
        ByteData.view(Uint8List.fromList(nonce).buffer).getUint64(4),
        258,
      );
    });

    test('the additional data binds the file, the index and the final flag',
        () async {
      final (sender, _) = await handshake();
      final key = await sender.keys.fileKey('0f' * 16);

      final aad = key.aadFor(7, isFinal: true);
      expect(aad.length, 25);
      expect(aad.sublist(0, 16), List.filled(16, 0x0f));
      expect(ByteData.view(Uint8List.fromList(aad).buffer).getUint64(16), 7);
      expect(aad[24], 1);
      expect(key.aadFor(7, isFinal: false)[24], 0);
    });
  });
}
