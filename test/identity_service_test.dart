import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/identity_service.dart';

void main() {
  late Directory tempDir;
  late String keyPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('icy_identity_test');
    keyPath = '${tempDir.path}${Platform.pathSeparator}identity.key';
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('key material', () {
    test('generates a key pair on first use and writes it to disk', () async {
      final service = IdentityService.forTesting(filePath: keyPath);
      await service.ensureInitialized();

      expect(File(keyPath).existsSync(), isTrue);
      final stored = jsonDecode(File(keyPath).readAsStringSync());
      expect(stored['alg'], 'ed25519');
      expect(base64Decode(stored['seed'] as String).length, 32);
    });

    test('reuses the stored key across instances', () async {
      final first = IdentityService.forTesting(filePath: keyPath);
      final firstId = await first.getDeviceId();
      final firstKey = await first.getPublicKeyBase64();

      final second = IdentityService.forTesting(filePath: keyPath);

      expect(await second.getDeviceId(), firstId);
      expect(await second.getPublicKeyBase64(), firstKey);
    });

    test('different devices get different identities', () async {
      final a = IdentityService.forTesting(filePath: keyPath);
      final b = IdentityService.forTesting(
        filePath: '${tempDir.path}${Platform.pathSeparator}other.key',
      );

      expect(await a.getDeviceId(), isNot(await b.getDeviceId()));
    });

    test('regenerates when the stored key is corrupted', () async {
      File(keyPath).writeAsStringSync('not json at all');

      final service = IdentityService.forTesting(filePath: keyPath);
      await service.ensureInitialized();

      expect((await service.getPublicKeyBytes()).length, 32);
    });

    test('regenerates when the stored seed has the wrong length', () async {
      File(keyPath).writeAsStringSync(
        jsonEncode({'v': 1, 'alg': 'ed25519', 'seed': base64Encode([1, 2, 3])}),
      );

      final service = IdentityService.forTesting(filePath: keyPath);
      await service.ensureInitialized();

      expect((await service.getPublicKeyBytes()).length, 32);
    });

    test('concurrent initialization generates only one key', () async {
      final service = IdentityService.forTesting(filePath: keyPath);

      final ids = await Future.wait([
        service.getDeviceId(),
        service.getDeviceId(),
        service.getDeviceId(),
      ]);

      expect(ids.toSet(), hasLength(1));
    });

    test(
      'restricts the key file to the owner on POSIX platforms',
      () async {
        final service = IdentityService.forTesting(filePath: keyPath);
        await service.ensureInitialized();

        final mode = File(keyPath).statSync().mode & 0x1FF;
        expect(mode, 0x180); // 0600
      },
      skip: Platform.isWindows ? 'chmod is POSIX-only' : false,
    );
  });

  group('deviceId derivation', () {
    test('is the 32-hex-character fingerprint of the public key', () async {
      final service = IdentityService.forTesting(filePath: keyPath);
      final deviceId = await service.getDeviceId();

      expect(deviceId, hasLength(32));
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(deviceId), isTrue);
      expect(
        deviceId,
        await IdentityService.deviceIdFromPublicKey(
          await service.getPublicKeyBytes(),
        ),
      );
    });

    test('is stable for the same public key', () async {
      final key = List<int>.generate(32, (i) => i);

      expect(
        await IdentityService.deviceIdFromPublicKey(key),
        await IdentityService.deviceIdFromPublicKey(key),
      );
    });

    test('matchesDeviceId rejects a forged id', () async {
      final key = List<int>.generate(32, (i) => i);
      final realId = await IdentityService.deviceIdFromPublicKey(key);

      expect(await IdentityService.matchesDeviceId(realId, key), isTrue);
      expect(
        await IdentityService.matchesDeviceId('0' * 32, key),
        isFalse,
      );
    });

    test('cached getters stay null until initialization completes', () {
      final service = IdentityService.forTesting(filePath: keyPath);

      expect(service.deviceIdOrNull, isNull);
      expect(service.publicKeyBase64OrNull, isNull);
    });

    test('cached getters are populated after initialization', () async {
      final service = IdentityService.forTesting(filePath: keyPath);
      await service.ensureInitialized();

      expect(service.deviceIdOrNull, await service.getDeviceId());
      expect(
        service.publicKeyBase64OrNull,
        await service.getPublicKeyBase64(),
      );
    });
  });

  group('decodePublicKey', () {
    test('accepts a valid 32-byte base64 key', () {
      final encoded = base64Encode(List<int>.filled(32, 7));

      expect(IdentityService.decodePublicKey(encoded), hasLength(32));
    });

    test('rejects null, empty, malformed and wrong-length input', () {
      expect(IdentityService.decodePublicKey(null), isNull);
      expect(IdentityService.decodePublicKey(''), isNull);
      expect(IdentityService.decodePublicKey('!!!not base64!!!'), isNull);
      expect(
        IdentityService.decodePublicKey(base64Encode(List<int>.filled(16, 1))),
        isNull,
      );
    });
  });

  group('sign and verify', () {
    test('a signature verifies against the matching public key', () async {
      final service = IdentityService.forTesting(filePath: keyPath);
      final message = utf8.encode('icy-easy-send');

      final signature = await service.sign(message);

      expect(
        await IdentityService.verify(
          message,
          signature: signature,
          publicKey: await service.getPublicKeyBytes(),
        ),
        isTrue,
      );
    });

    test('a tampered message does not verify', () async {
      final service = IdentityService.forTesting(filePath: keyPath);
      final signature = await service.sign(utf8.encode('original'));

      expect(
        await IdentityService.verify(
          utf8.encode('tampered'),
          signature: signature,
          publicKey: await service.getPublicKeyBytes(),
        ),
        isFalse,
      );
    });

    test('another device\'s key does not verify', () async {
      final signer = IdentityService.forTesting(filePath: keyPath);
      final other = IdentityService.forTesting(
        filePath: '${tempDir.path}${Platform.pathSeparator}other.key',
      );
      final message = utf8.encode('icy-easy-send');

      expect(
        await IdentityService.verify(
          message,
          signature: await signer.sign(message),
          publicKey: await other.getPublicKeyBytes(),
        ),
        isFalse,
      );
    });

    test('malformed signature input returns false instead of throwing',
        () async {
      final service = IdentityService.forTesting(filePath: keyPath);

      expect(
        await IdentityService.verify(
          utf8.encode('message'),
          signature: const [1, 2, 3],
          publicKey: await service.getPublicKeyBytes(),
        ),
        isFalse,
      );
    });
  });
}
