import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/transfer_file_item.dart';
import 'package:icy_easy_send/services/web_share_handler.dart';
import 'package:icy_easy_send/services/web_share_service.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';

void main() {
  late Directory tempDir;
  late WebShareService service;
  late WebShareHandler handler;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('icy_web_share_http_');
    service = WebShareService.instance;
    service.clearAll();
    handler = WebShareHandler(shareService: service);
  });

  tearDown(() async {
    service.clearAll();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<TransferFileItem> _item(String name, String content) async {
    final file = File(path.join(tempDir.path, name));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return TransferFileItem(file: file, transferName: name);
  }

  test('share page and meta return file list for valid token', () async {
    final item = await _item('hello.txt', 'hello-share');
    final session = await service.createSession(
      items: [item],
      deviceName: 'UnitTest',
    );

    final page = await handler.handleSharePage(
      Request('GET', Uri.parse('http://127.0.0.1/s/${session.token}')),
      session.token,
    );
    expect(page.statusCode, 200);
    final html = await page.readAsString();
    expect(html.contains('hello.txt'), isTrue);
    expect(html.contains('Icy Easy Send'), isTrue);
    expect(html.contains('/web-share/logo.png'), isTrue);

    final meta = await handler.handleShareMeta(
      Request('GET', Uri.parse('http://127.0.0.1/s/${session.token}/meta')),
      session.token,
    );
    expect(meta.statusCode, 200);
    final body = jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
    expect(body['fileCount'], 1);
    expect((body['files'] as List).first['name'], 'hello.txt');
  });

  test('file download streams content and rejects bad ids', () async {
    final item = await _item('photo.bin', 'binary-data-123');
    final session = await service.createSession(
      items: [item],
      deviceName: 'UnitTest',
    );
    final fileId = session.files.single.id;

    final ok = await handler.handleFileDownload(
      Request(
        'GET',
        Uri.parse('http://127.0.0.1/s/${session.token}/file/$fileId'),
      ),
      session.token,
      fileId,
    );
    expect(ok.statusCode, 200);
    expect(ok.headers['content-disposition'], contains('photo.bin'));
    expect(await ok.readAsString(), 'binary-data-123');

    final bad = await handler.handleFileDownload(
      Request(
        'GET',
        Uri.parse('http://127.0.0.1/s/${session.token}/file/../secret'),
      ),
      session.token,
      '../secret',
    );
    expect(bad.statusCode, 403);
  });

  test('stopped or unknown token returns gone', () async {
    final item = await _item('x.txt', 'x');
    final session = await service.createSession(
      items: [item],
      deviceName: 'UnitTest',
    );
    service.stopSession(token: session.token);

    final page = await handler.handleSharePage(
      Request('GET', Uri.parse('http://127.0.0.1/s/${session.token}')),
      session.token,
    );
    expect(page.statusCode, 410);

    final missing = await handler.handleShareMeta(
      Request('GET', Uri.parse('http://127.0.0.1/s/missing/meta')),
      'missing',
    );
    expect(missing.statusCode, 410);
  });

  test('invalid token is rejected without looking up session', () async {
    final page = await handler.handleSharePage(
      Request('GET', Uri.parse('http://127.0.0.1/s/not-a-token')),
      'not-a-token',
    );
    expect(page.statusCode, 410);
  });

  test('Content-Disposition keeps ASCII filename and UTF-8 filename*', () {
    final header = WebShareHandler.buildContentDisposition(
      '计算机软件著作权登记申请表.pdf',
    );
    expect(header, contains('filename="download.pdf"'));
    expect(header.contains('计算机'), isFalse);
    expect(
      header,
      contains(
        'filename*=UTF-8\'\'${Uri.encodeComponent('计算机软件著作权登记申请表.pdf')}',
      ),
    );
    // Entire header must be Latin-1 / ASCII safe for Dart HttpHeaders.
    expect(header.codeUnits.every((u) => u <= 0xFF && u >= 0x20), isTrue);
  });

  test('Chinese file name download response headers are valid', () async {
    final item = await _item('计算机软件著作权登记申请表.pdf', 'pdf-bytes');
    final session = await service.createSession(
      items: [item],
      deviceName: 'UnitTest',
    );
    final fileId = session.files.single.id;

    final response = await handler.handleFileDownload(
      Request(
        'GET',
        Uri.parse('http://127.0.0.1/s/${session.token}/file/$fileId'),
      ),
      session.token,
      fileId,
    );
    expect(response.statusCode, 200);
    expect(response.headers['content-type'], 'application/octet-stream');
    final disposition = response.headers['content-disposition']!;
    expect(disposition.contains('计算机'), isFalse);
    expect(disposition, contains('filename="download.pdf"'));
    expect(disposition.contains("filename*=UTF-8''"), isTrue);
    expect(await response.readAsString(), 'pdf-bytes');
  });

  test('multi-file page lists every selected file', () async {
    final items = [
      await _item('one.txt', '1'),
      await _item('two.txt', '2'),
      await _item('folder/three.txt', '3'),
    ];
    final session = await service.createSession(
      items: items,
      deviceName: 'UnitTest',
    );

    final page = await handler.handleSharePage(
      Request('GET', Uri.parse('http://127.0.0.1/s/${session.token}')),
      session.token,
    );
    final html = await page.readAsString();
    expect(html.contains('one.txt'), isTrue);
    expect(html.contains('two.txt'), isTrue);
    expect(html.contains('three.txt'), isTrue);
    expect(session.files.length, 3);
  });
}
