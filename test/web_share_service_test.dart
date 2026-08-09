import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/transfer_file_item.dart';
import 'package:icy_easy_send/services/web_share_service.dart';
import 'package:icy_easy_send/utils/constants.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late WebShareService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('icy_web_share_');
    service = WebShareService.instance;
    service.clearAll();
  });

  tearDown(() async {
    service.clearAll();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> _writeTempFile(String name, String content) async {
    final file = File(path.join(tempDir.path, name));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return file;
  }

  test('createSession exposes only selected files with random token', () async {
    final a = await _writeTempFile('a.txt', 'hello');
    final b = await _writeTempFile('nested/b.txt', 'world');

    final session = await service.createSession(
      items: [
        TransferFileItem(file: a, transferName: 'a.txt'),
        TransferFileItem(file: b, transferName: 'nested/b.txt'),
      ],
      deviceName: 'TestDevice',
      ttl: const Duration(minutes: 5),
    );

    expect(session.token.length, 32);
    expect(session.files.length, 2);
    expect(session.deviceName, 'TestDevice');
    expect(session.findFile(session.files.first.id)?.displayName, 'a.txt');
    expect(service.getSession(session.token), isNotNull);
    expect(service.getSession('deadbeef'), isNull);
  });

  test('stopSession invalidates token', () async {
    final file = await _writeTempFile('c.txt', 'data');
    final session = await service.createSession(
      items: [TransferFileItem.fromFile(file)],
      deviceName: 'TestDevice',
    );

    expect(service.stopSession(token: session.token), isTrue);
    expect(service.getSession(session.token), isNull);
    expect(service.hasActiveSession, isFalse);
  });

  test('expired session is treated as missing', () async {
    final file = await _writeTempFile('d.txt', 'data');
    final session = await service.createSession(
      items: [TransferFileItem.fromFile(file)],
      deviceName: 'TestDevice',
      ttl: const Duration(milliseconds: 1),
    );

    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(session.isExpired, isTrue);
    expect(service.getSession(session.token), isNull);
  });

  test('createSession replaces previous session', () async {
    final first = await _writeTempFile('first.txt', '1');
    final second = await _writeTempFile('second.txt', '2');

    final session1 = await service.createSession(
      items: [TransferFileItem.fromFile(first)],
      deviceName: 'TestDevice',
    );
    final session2 = await service.createSession(
      items: [TransferFileItem.fromFile(second)],
      deviceName: 'TestDevice',
    );

    expect(service.getSession(session1.token), isNull);
    expect(service.getSession(session2.token), isNotNull);
    expect(session2.files.single.displayName, 'second.txt');
  });

  test('buildShareUrl uses server address and token', () {
    final url = service.buildShareUrl('192.168.1.8:9527', 'abc123');
    expect(url, 'http://192.168.1.8:9527/s/abc123');
  });

  test('default TTL matches AppConstants', () async {
    final file = await _writeTempFile('ttl.txt', 'x');
    final before = DateTime.now();
    final session = await service.createSession(
      items: [TransferFileItem.fromFile(file)],
      deviceName: 'TestDevice',
    );
    final expected = before.add(AppConstants.webShareSessionDuration);
    expect(
      session.expiresAt.difference(expected).inSeconds.abs(),
      lessThan(3),
    );
  });

  test('rejects path traversal style file ids via findFile miss', () async {
    final file = await _writeTempFile('safe.txt', 'ok');
    final session = await service.createSession(
      items: [TransferFileItem.fromFile(file)],
      deviceName: 'TestDevice',
    );

    expect(session.findFile('../etc/passwd'), isNull);
    expect(session.findFile(session.files.single.id), isNotNull);
  });
}
