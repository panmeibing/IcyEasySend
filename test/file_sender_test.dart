import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/l10n/current_localizations.dart';
import 'package:icy_easy_send/models/transfer_data.dart';
import 'package:icy_easy_send/utils/operation_result.dart';
import 'package:icy_easy_send/services/transfer/file_sender.dart';
import 'package:icy_easy_send/services/transfer/transfer_cancellation.dart';

/// The widget binding answers every [HttpClient] with HTTP 400. These tests
/// talk to a local server, so they put the real client back.
class _RealHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workspace;
  late HttpServer server;
  late Future<void> Function(HttpRequest request) onTransfer;

  setUp(() async {
    HttpOverrides.global = _RealHttp();
    workspace = await Directory.systemTemp.createTemp('file_sender');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) => onTransfer(request));
  });

  tearDown(() async {
    await server.close(force: true);
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  Future<File> fileOf(int size) async {
    final file = File('${workspace.path}/payload.bin');
    await file.writeAsBytes(List<int>.filled(size, 1));
    return file;
  }

  Future<OperationResult<TransferData>> send(
    FileSender sender,
    File file, {
    TransferCancellation? cancellation,
  }) {
    return sender.sendFileWithTransferId(
      targetIP: '127.0.0.1:${server.port}',
      file: file,
      transferId: 'id',
      senderIP: '127.0.0.1',
      transferName: 'payload.bin',
      cancellation: cancellation,
    );
  }

  test('a receiver that takes every byte but never answers is given up on '
      'after the ACK timeout', () async {
    // Reads the whole body, then goes quiet, like a peer that dropped off the
    // network after the last packet arrived.
    onTransfer = (request) => request.drain<void>();
    final sender = FileSender(
      stallTimeout: const Duration(milliseconds: 200),
      ackTimeout: const Duration(milliseconds: 400),
    );

    final result = await send(
      sender,
      await fileOf(64 * 1024),
    ).timeout(const Duration(seconds: 10));

    expect(result.isFailure, isTrue);
    expect(result.errorMessage, appText.transferTimeout);
  });

  test('a receiver that answers within the ACK timeout succeeds', () async {
    onTransfer = (request) async {
      await request.drain<void>();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write('{"savedPath":"ok"}');
      await request.response.close();
    };
    final sender = FileSender(
      stallTimeout: const Duration(milliseconds: 100),
      ackTimeout: const Duration(seconds: 5),
    );

    final result = await send(sender, await fileOf(64 * 1024));

    expect(result.isSuccess, isTrue, reason: result.errorMessage);
  });

  test('a user can still cancel while waiting for the ACK', () async {
    final bodyRead = Completer<void>();
    onTransfer = (request) async {
      await request.drain<void>();
      bodyRead.complete();
    };
    final sender = FileSender(
      stallTimeout: const Duration(milliseconds: 200),
      ackTimeout: const Duration(minutes: 1),
    );
    final cancellation = TransferCancellation();

    final pending = send(
      sender,
      await fileOf(64 * 1024),
      cancellation: cancellation,
    );
    await bodyRead.future;
    cancellation.cancelFile('payload.bin');
    final result = await pending.timeout(const Duration(seconds: 10));

    expect(result.isFailure, isTrue);
    expect(result.errorMessage, appText.transferCancelled);
    expect(cancellation.isSettled('payload.bin'), isTrue);
  });

  /// Reads the first chunk of an upload, then drops the connection the way a
  /// receiver does when the file is cancelled on its side. [state] is what
  /// `/transfer-status` reports for it afterwards.
  void cutUploadAndReport(String? state, {List<String>? statusQueries}) {
    onTransfer = (request) async {
      if (request.uri.path == '/transfer-status') {
        statusQueries?.add(request.uri.queryParameters['transferId'] ?? '');
        if (state == null) {
          request.response.statusCode = HttpStatus.notFound;
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write('{"state":"$state"}');
        }
        await request.response.close();
        return;
      }
      final firstChunk = Completer<void>();
      final subscription = request.listen((_) {
        if (!firstChunk.isCompleted) firstChunk.complete();
      });
      await firstChunk.future;
      // dart:io closes the connection when an unfinished body is abandoned.
      await subscription.cancel();
    };
  }

  test('a connection the receiver cut because it cancelled the file is '
      'reported as cancelled', () async {
    final queries = <String>[];
    cutUploadAndReport('cancelled', statusQueries: queries);

    final result = await send(
      FileSender(stallTimeout: const Duration(seconds: 10)),
      await fileOf(8 * 1024 * 1024),
    ).timeout(const Duration(seconds: 20));

    expect(result.errorMessage, appText.transferCancelled);
    expect(queries, ['id']);
  });

  test('a cut connection the receiver did not cancel stays a network '
      'error', () async {
    cutUploadAndReport('unknown');

    final result = await send(
      FileSender(stallTimeout: const Duration(seconds: 10)),
      await fileOf(8 * 1024 * 1024),
    ).timeout(const Duration(seconds: 20));

    expect(result.isFailure, isTrue);
    expect(result.errorMessage, isNot(appText.transferCancelled));
  });

  test('an older receiver without the status endpoint stays a network '
      'error', () async {
    cutUploadAndReport(null);

    final result = await send(
      FileSender(stallTimeout: const Duration(seconds: 10)),
      await fileOf(8 * 1024 * 1024),
    ).timeout(const Duration(seconds: 20));

    expect(result.isFailure, isTrue);
    expect(result.errorMessage, isNot(appText.transferCancelled));
  });

  test('a finished file is marked so it cannot be cancelled later', () async {
    onTransfer = (request) async {
      await request.drain<void>();
      request.response
        ..statusCode = HttpStatus.ok
        ..write('{"savedPath":"ok"}');
      await request.response.close();
    };
    final cancellation = TransferCancellation();
    final notified = <Set<String>>[];
    cancellation.onChanged = notified.add;

    final result = await send(
      FileSender(),
      await fileOf(1024),
      cancellation: cancellation,
    );
    cancellation.cancelAll(['payload.bin']);

    expect(result.isSuccess, isTrue, reason: result.errorMessage);
    expect(notified, isEmpty);
  });
}
