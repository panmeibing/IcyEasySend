import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/relay_config.dart';
import 'package:icy_easy_send/services/preferences_service.dart';
import 'package:icy_easy_send/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PreferencesService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = PreferencesService();
  });

  test('unset settings read as their defaults', () async {
    expect(await service.getLastUsedIP(), isNull);
    expect(await service.getLastUsedPort(), AppConstants.defaultPort);
    expect(await service.getIPHistory(), isEmpty);
    expect(await service.getIPValidationEnabled(), isTrue);
    expect(
      await service.getConcurrentTransfers(),
      AppConstants.defaultConcurrentTransfers,
    );
    expect(
      await service.getMaxHistoryItems(),
      AppConstants.defaultMaxHistoryItems,
    );
    expect(
      await service.getMaxClipboardSize(),
      AppConstants.defaultMaxClipboardSize,
    );
    expect(await service.getClipboardOverlayEnabled(), isFalse);
    expect(await service.getRelayPairingEnabled(), isTrue);
    expect(await service.getRelayConfig(), same(RelayConfig.empty));
    expect(await service.getCustomReceiveSavePath(), isNull);
  });

  test('out-of-range values are refused and not stored', () async {
    expect(await service.saveLastUsedPort(0), isFalse);
    expect(await service.saveLastUsedPort(65536), isFalse);
    expect(await service.getLastUsedPort(), AppConstants.defaultPort);

    expect(await service.saveConcurrentTransfers(0), isFalse);
    expect(
      await service.saveConcurrentTransfers(
        AppConstants.maxConcurrentTransfers + 1,
      ),
      isFalse,
    );
    expect(
      await service.saveMaxHistoryItems(AppConstants.allowMinHistoryItems - 1),
      isFalse,
    );
    expect(
      await service.saveMaxClipboardSize(AppConstants.maxClipboardSizeMB + 1),
      isFalse,
    );
    expect(await service.saveCustomReceiveSavePath('   '), isFalse);

    expect(await service.saveLastUsedPort(8080), isTrue);
    expect(await service.getLastUsedPort(), 8080);
  });

  test('last used IP leads a bounded, de-duplicated history', () async {
    for (var i = 0; i < 12; i++) {
      await service.saveLastUsedIP('10.0.0.$i');
    }
    await service.saveLastUsedIP('10.0.0.5');

    final history = await service.getIPHistory();
    expect(await service.getLastUsedIP(), '10.0.0.5');
    expect(history.first, '10.0.0.5');
    expect(history, hasLength(10));
    expect(history.where((ip) => ip == '10.0.0.5'), hasLength(1));

    await service.removeIPFromHistory('10.0.0.5');
    expect(await service.getIPHistory(), isNot(contains('10.0.0.5')));
  });

  test('receive path is stored trimmed and can be cleared', () async {
    await service.saveCustomReceiveSavePath('  /tmp/in  ');
    expect(await service.getCustomReceiveSavePath(), '/tmp/in');
    await service.clearCustomReceiveSavePath();
    expect(await service.getCustomReceiveSavePath(), isNull);
  });

  test('a corrupt relay config reads as empty', () async {
    SharedPreferences.setMockInitialValues({'relay_config': '[1, 2]'});
    expect(await service.getRelayConfig(), same(RelayConfig.empty));
    SharedPreferences.setMockInitialValues({'relay_config': '{not json'});
    expect(await service.getRelayConfig(), same(RelayConfig.empty));
  });

  group('relay pairing blocklist', () {
    final idA = 'a' * 32;
    final idB = 'b' * 32;

    test('legacy entries migrate and junk is dropped', () async {
      SharedPreferences.setMockInitialValues({
        'relay_pair_blocklist': [idA, '$idB:1700000000000', 'garbage', '{}'],
      });

      final entries = await service.getRelayPairBlocklistEntries();
      expect(entries.map((p) => p.deviceId), unorderedEquals([idA, idB]));

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('relay_pair_blocklist')!;
      expect(stored, hasLength(2));
      expect(stored.every((e) => jsonDecode(e) is Map), isTrue);
    });

    test('block puts the peer first, unblock removes it', () async {
      await service.blockRelayPairing(idA, deviceName: 'Phone');
      await service.blockRelayPairing(idB);
      await service.blockRelayPairing(idA, deviceName: 'Phone');

      final entries = await service.getRelayPairBlocklistEntries();
      expect(entries.map((p) => p.deviceId), [idA, idB]);
      expect(entries.first.deviceName, 'Phone');
      expect(await service.isRelayPairingBlocked(idB), isTrue);

      expect(await service.unblockRelayPairing(idB), isTrue);
      expect(await service.getRelayPairBlocklist(), {idA});
      expect(await service.blockRelayPairing(''), isFalse);
    });
  });
}
