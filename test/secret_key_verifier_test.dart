import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/secret_key_verifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A matching secret key skips the receive prompt, so guessing it must not be
/// something a peer can simply keep doing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecretKeyVerifier verifier;

  setUp(() {
    SharedPreferences.setMockInitialValues({'device_secret_key': 'right-key'});
    verifier = SecretKeyVerifier.forTesting();
  });

  test('accepts the stored key and nothing else', () async {
    expect(
      await verifier.verify('right-key', remoteAddress: '10.0.0.2'),
      isTrue,
    );
    expect(
      await verifier.verify('wrong-key', remoteAddress: '10.0.0.2'),
      isFalse,
    );
    expect(
      await verifier.verify('right-ke', remoteAddress: '10.0.0.2'),
      isFalse,
    );
    expect(await verifier.verify('', remoteAddress: '10.0.0.2'), isFalse);
    expect(await verifier.verify(null, remoteAddress: '10.0.0.2'), isFalse);
  });

  test('never matches when this device has no key', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await verifier.verify('', remoteAddress: '10.0.0.2'), isFalse);
    expect(
      await verifier.verify('anything', remoteAddress: '10.0.0.2'),
      isFalse,
    );
  });

  test(
    'repeated wrong guesses lock that address out, even with the right key',
    () async {
      for (var i = 0; i < 5; i++) {
        await verifier.verify('guess-$i', remoteAddress: '10.0.0.66');
      }

      expect(
        await verifier.verify('right-key', remoteAddress: '10.0.0.66'),
        isFalse,
      );
      expect(
        await verifier.verify('right-key', remoteAddress: '10.0.0.2'),
        isTrue,
        reason: 'other addresses are unaffected',
      );
    },
  );
}
