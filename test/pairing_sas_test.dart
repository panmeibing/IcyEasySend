import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/pairing_service.dart';
import 'package:icy_easy_send/utils/constants.dart';

void main() {
  final keyA = List<int>.generate(32, (i) => i);
  final keyB = List<int>.generate(32, (i) => 255 - i);

  group('pairing short authentication string', () {
    test('is six decimal digits', () async {
      final sas = await PairingService.computeSas(keyA, keyB);

      expect(sas, hasLength(AppConstants.sasDigits));
      expect(RegExp(r'^\d{6}$').hasMatch(sas), isTrue);
    });

    test('both devices derive the same code despite opposite key order',
        () async {
      expect(
        await PairingService.computeSas(keyA, keyB),
        await PairingService.computeSas(keyB, keyA),
      );
    });

    test('is deterministic across calls', () async {
      expect(
        await PairingService.computeSas(keyA, keyB),
        await PairingService.computeSas(keyA, keyB),
      );
    });

    test('changes when one of the keys changes', () async {
      final keyC = List<int>.generate(32, (i) => i == 31 ? 99 : i);

      expect(
        await PairingService.computeSas(keyA, keyB),
        isNot(await PairingService.computeSas(keyA, keyC)),
      );
    });

    test('keeps leading zeros so the two screens always show six digits',
        () async {
      // Search for a key pair whose code is below 100000; without padding it
      // would render shorter on one device and invite a false mismatch.
      String? shortCode;
      for (var i = 0; i < 5000 && shortCode == null; i++) {
        final candidate = List<int>.generate(32, (j) => (i + j) % 256);
        final sas = await PairingService.computeSas(keyA, candidate);
        if (sas.startsWith('0')) {
          shortCode = sas;
        }
      }

      expect(shortCode, isNotNull);
      expect(shortCode, hasLength(AppConstants.sasDigits));
    });
  });
}
