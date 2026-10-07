import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/utils/error_messages.dart';
import 'package:icy_easy_send/utils/http_helper.dart';

void main() {
  late HttpServer server;
  late String base;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}';
    server.listen((request) async {
      switch (request.uri.path) {
        case '/echo':
          final body = await utf8.decodeStream(request);
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'method': request.method,
                'type': request.headers.contentType?.mimeType,
                'body': body,
              }),
            );
        case '/forbidden':
          request.response
            ..statusCode = 403
            ..write('{"code":"declined","message":"拒绝"}');
        case '/slow':
          await Future<void>.delayed(const Duration(seconds: 2));
          request.response.write('late');
        default:
          request.response.statusCode = 404;
      }
      await request.response.close();
    });
  });

  tearDown(() => server.close(force: true));

  test('posts the body as given and decodes UTF-8 replies', () async {
    final result = await HttpHelper.post(
      '$base/echo',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': '客厅电视'}),
    );

    final response = result.data!;
    expect(HttpHelper.isSuccessResponse(response), isTrue);
    final echoed = HttpHelper.parseJsonResponse(response).data!;
    expect(echoed['method'], 'POST');
    expect(echoed['type'], 'application/json');
    expect(jsonDecode(echoed['body'] as String), {'name': '客厅电视'});
  });

  test('an error status is a response, not a failure', () async {
    final result = await HttpHelper.get('$base/forbidden');

    expect(result.isSuccess, isTrue);
    expect(result.data!.statusCode, 403);
    expect(result.data!.body, contains('拒绝'));
  });

  test('a refused connection is a connection failure', () async {
    final port = server.port;
    await server.close(force: true);

    final result = await HttpHelper.get('http://127.0.0.1:$port/echo');

    expect(result.isSuccess, isFalse);
    expect(
      result.errorMessage,
      startsWith(ErrorMessages.networkConnectionFailed),
    );
  });

  test('the timeout covers the whole exchange', () async {
    final result = await HttpHelper.get(
      '$base/slow',
      timeout: const Duration(milliseconds: 200),
    );

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, ErrorMessages.networkTimeout);
  });
}
