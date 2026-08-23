import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/paired_device.dart';
import 'package:icy_easy_send/services/paired_device_store.dart';

void main() {
  late Directory tempDir;
  late String storePath;

  String key(int fill) => base64Encode(List<int>.filled(32, fill));

  PairedDevice device(
    String id, {
    int fill = 1,
    String name = 'Desktop',
    bool autoAccept = false,
    String? lastSeenLan,
  }) {
    return PairedDevice(
      deviceId: id,
      publicKey: key(fill),
      deviceName: name,
      platform: 'windows',
      pairedAt: DateTime.fromMillisecondsSinceEpoch(1770000000000),
      autoAccept: autoAccept,
      lastSeenLan: lastSeenLan,
    );
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('icy_paired_store_test');
    storePath = '${tempDir.path}${Platform.pathSeparator}paired_devices.json';
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('PairedDevice serialization', () {
    test('round trips through JSON', () {
      final original = device('abc123', lastSeenLan: '192.168.1.10:9527');

      final restored = PairedDevice.tryParse(
        jsonDecode(jsonEncode(original.toJson())),
      );

      expect(restored, original);
    });

    test('rejects entries without a usable public key', () {
      expect(PairedDevice.tryParse({'deviceId': 'abc'}), isNull);
      expect(
        PairedDevice.tryParse({'deviceId': 'abc', 'publicKey': 'nope'}),
        isNull,
      );
      expect(
        PairedDevice.tryParse({'publicKey': key(1), 'deviceId': ''}),
        isNull,
      );
      expect(PairedDevice.tryParse('not a map'), isNull);
    });

    test('tolerates missing optional fields', () {
      final parsed = PairedDevice.tryParse({
        'deviceId': 'abc',
        'publicKey': key(2),
      });

      expect(parsed, isNotNull);
      expect(parsed!.deviceName, isEmpty);
      expect(parsed.autoAccept, isFalse);
      expect(parsed.lastSeenLan, isNull);
    });

    test('shortens the device id for display', () {
      expect(device('a3f21b7c9de').shortDeviceId, 'a3f2-1b7c');
      expect(device('abc').shortDeviceId, 'abc');
    });
  });

  group('persistence', () {
    test('stores a device and finds it again', () async {
      final store = PairedDeviceStore.forTesting(filePath: storePath);

      expect(await store.upsert(device('peer-1')), isTrue);

      expect((await store.find('peer-1'))?.deviceName, 'Desktop');
      expect(await store.isPaired('peer-1'), isTrue);
      expect(await store.isPaired('peer-2'), isFalse);
    });

    test('survives a reload from disk', () async {
      final writer = PairedDeviceStore.forTesting(filePath: storePath);
      await writer.upsert(device('peer-1', lastSeenLan: '10.0.0.2:9527'));

      final reader = PairedDeviceStore.forTesting(filePath: storePath);
      final loaded = await reader.loadAll();

      expect(loaded, hasLength(1));
      expect(loaded.single.lastSeenLan, '10.0.0.2:9527');
    });

    test('updates an existing entry instead of duplicating it', () async {
      final store = PairedDeviceStore.forTesting(filePath: storePath);
      await store.upsert(device('peer-1', name: 'Old'));

      await store.upsert(device('peer-1', name: 'New'));

      final all = await store.loadAll();
      expect(all, hasLength(1));
      expect(all.single.deviceName, 'New');
    });

    test('refuses to rotate the key of an already trusted device', () async {
      final store = PairedDeviceStore.forTesting(filePath: storePath);
      await store.upsert(device('peer-1', fill: 1));

      final accepted = await store.upsert(device('peer-1', fill: 9));

      expect(accepted, isFalse);
      expect((await store.find('peer-1'))?.publicKey, key(1));
    });

    test('removes a device', () async {
      final store = PairedDeviceStore.forTesting(filePath: storePath);
      await store.upsert(device('peer-1'));

      await store.remove('peer-1');

      expect(await store.find('peer-1'), isNull);
      expect(
        jsonDecode(File(storePath).readAsStringSync()),
        isEmpty,
      );
    });

    test('clears every device', () async {
      final store = PairedDeviceStore.forTesting(filePath: storePath);
      await store.upsert(device('peer-1'));
      await store.upsert(device('peer-2', fill: 2));

      await store.clear();

      expect(await store.loadAll(), isEmpty);
    });

    test('skips corrupted entries but keeps the valid ones', () async {
      File(storePath).writeAsStringSync(
        jsonEncode([
          device('peer-1').toJson(),
          {'deviceId': 'broken'},
          'garbage',
        ]),
      );

      final store = PairedDeviceStore.forTesting(filePath: storePath);

      expect(await store.loadAll(), hasLength(1));
    });

    test('an unreadable file degrades to an empty list', () async {
      File(storePath).writeAsStringSync('{"not":"a list"}');

      final store = PairedDeviceStore.forTesting(filePath: storePath);

      expect(await store.loadAll(), isEmpty);
    });

    test('missing file is not an error', () async {
      final store = PairedDeviceStore.forTesting(filePath: storePath);

      expect(await store.loadAll(), isEmpty);
      expect(File(storePath).existsSync(), isFalse);
    });
  });

  group('mutating helpers', () {
    test('touch refreshes name and address of a trusted peer', () async {
      final store = PairedDeviceStore.forTesting(filePath: storePath);
      await store.upsert(device('peer-1', name: 'Old'));

      await store.touch(
        'peer-1',
        deviceName: 'Renamed',
        lastSeenLan: '192.168.0.5:9527',
      );

      final updated = await store.find('peer-1');
      expect(updated?.deviceName, 'Renamed');
      expect(updated?.lastSeenLan, '192.168.0.5:9527');
    });

    test('touch does not create an entry for an unknown device', () async {
      final store = PairedDeviceStore.forTesting(filePath: storePath);

      await store.touch('stranger', deviceName: 'Evil');

      expect(await store.loadAll(), isEmpty);
    });

    test('touch keeps the existing name when given an empty one', () async {
      final store = PairedDeviceStore.forTesting(filePath: storePath);
      await store.upsert(device('peer-1', name: 'Desktop'));

      await store.touch('peer-1', deviceName: '');

      expect((await store.find('peer-1'))?.deviceName, 'Desktop');
    });

    test('notifies listeners when the list changes', () async {
      final store = PairedDeviceStore.forTesting(filePath: storePath);
      final seen = <int>[];
      final subscription = store.changes.listen((d) => seen.add(d.length));

      await store.upsert(device('peer-1'));
      await store.upsert(device('peer-2', fill: 2));
      await store.remove('peer-1');
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(seen, [1, 2, 1]);
    });
  });
}
