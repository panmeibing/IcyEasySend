import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/l10n/current_localizations.dart';
import 'package:icy_easy_send/models/transfer_data.dart';
import 'package:icy_easy_send/models/transfer_file_item.dart';
import 'package:icy_easy_send/models/transfer_history.dart';
import 'package:icy_easy_send/services/preferences_service.dart';
import 'package:icy_easy_send/services/transfer/batch_transfer_manager.dart';
import 'package:icy_easy_send/services/transfer/file_sender.dart';
import 'package:icy_easy_send/services/transfer/transfer_cancellation.dart';
import 'package:icy_easy_send/services/transfer/transfer_history_manager.dart';
import 'package:icy_easy_send/utils/operation_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts overlapping [FileSender.sendFileWithTransferId] calls.
///
/// The batch manager used to treat a timed-out future as finished while the
/// HTTP upload kept running, so the next wave opened more sockets than the
/// concurrency setting allowed.
class _CountingSender extends FileSender {
  _CountingSender() : super(stallTimeout: const Duration(milliseconds: 200));

  int inFlight = 0;
  int maxInFlight = 0;

  @override
  Future<OperationResult<TransferData>> sendFileWithTransferId({
    required String targetIP,
    required File file,
    required String transferId,
    required String senderIP,
    String? deviceName,
    String? secretKey,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    String? transferName,
    TransferCancellation? cancellation,
  }) async {
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    try {
      return await super.sendFileWithTransferId(
        targetIP: targetIP,
        file: file,
        transferId: transferId,
        senderIP: senderIP,
        deviceName: deviceName,
        secretKey: secretKey,
        onProgress: onProgress,
        transferName: transferName,
        cancellation: cancellation,
      );
    } finally {
      inFlight--;
    }
  }
}

class _NoHistory extends TransferHistoryManager {
  @override
  Future<void> saveTransferHistoryBatch(
    List<TransferHistory> histories,
  ) async {}
}

class _RecordingHistory extends TransferHistoryManager {
  final saved = <TransferHistory>[];

  @override
  Future<void> saveTransferHistoryBatch(List<TransferHistory> histories) async {
    saved.addAll(histories);
  }
}

/// The widget binding answers every [HttpClient] with HTTP 400. These tests
/// talk to a local server, so they put the real client back.
class _RealHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttp();

  late Directory workspace;
  late HttpServer server;
  late _CountingSender sender;
  var acceptTransfers = false;
  var acceptNames = <String>{};
  var responseDelays = <String, Duration>{};
  var finishedOrder = <String>[];
  Completer<void>? holdConfirm;
  late Completer<void> confirmArrived;
  late Completer<Map<String, dynamic>> cancelBody;

  setUp(() async {
    acceptTransfers = false;
    acceptNames = {};
    responseDelays = {};
    finishedOrder = [];
    holdConfirm = null;
    confirmArrived = Completer<void>();
    cancelBody = Completer<Map<String, dynamic>>();
    HttpOverrides.global = _RealHttp();
    SharedPreferences.setMockInitialValues({
      'concurrent_transfers': 2,
      'device_name': 'tester',
    });
    workspace = await Directory.systemTemp.createTemp('batch_concurrency');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    sender = _CountingSender();

    server.listen((request) async {
      final path = request.uri.path;
      if (path == '/health') {
        await _writeJson(request, {'status': 'ok', 'deviceName': 'tester'});
        return;
      }
      if (path == '/batch-confirm-receive') {
        final body = await utf8.decoder.bind(request).join();
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final files = decoded['files'] as List<dynamic>;
        final ids = <String, String>{
          for (final entry in files)
            (entry as Map)['fileName'] as String: 'id-${entry['fileName']}',
        };
        if (!confirmArrived.isCompleted) confirmArrived.complete();
        await holdConfirm?.future;
        await _writeJson(request, {'accepted': true, 'transferIds': ids});
        return;
      }
      if (path == '/batch-cancel') {
        final body = await utf8.decoder.bind(request).join();
        if (!cancelBody.isCompleted) {
          cancelBody.complete(jsonDecode(body) as Map<String, dynamic>);
        }
        await _writeJson(request, {'success': true});
        return;
      }
      if (path == '/transfer-status') {
        await _writeJson(request, {'state': 'unknown'});
        return;
      }
      if (path == '/transfer') {
        final name = request.uri.queryParameters['fileName']!;
        if (acceptTransfers || acceptNames.contains(name)) {
          await request.drain<void>();
          await Future<void>.delayed(responseDelays[name] ?? Duration.zero);
          finishedOrder.add(name);
          await _writeJson(request, {'savedPath': 'ok'});
          return;
        }
        // Stop reading after the first chunk so the body cannot finish.
        // The sender has to close that socket before the next file starts.
        late StreamSubscription<List<int>> subscription;
        subscription = request.listen((_) {
          subscription.pause();
        });
        return;
      }
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  test('a stalled upload is cancelled before the next wave starts', () async {
    final files = <TransferFileItem>[];
    for (final name in ['a.bin', 'b.bin', 'c.bin', 'd.bin']) {
      final file = File('${workspace.path}/$name');
      await file.writeAsBytes(List<int>.filled(4 * 1024 * 1024, 7));
      files.add(TransferFileItem(file: file, transferName: name));
    }

    final manager = BatchTransferManager(
      fileSender: sender,
      preferencesService: PreferencesService(),
      historyManager: _NoHistory(),
    );

    final results = await manager.sendFilesWithBatchConfirm(
      targetIP: '127.0.0.1:${server.port}',
      files: files,
    );

    expect(results, hasLength(4));
    expect(results.values.every((result) => result.isFailure), isTrue);
    // Both slots of the first wave must actually be occupied. A health-check
    // failure returns before any upload and would otherwise look like success.
    expect(
      sender.maxInFlight,
      2,
      reason: results.values.map((result) => result.errorMessage).join(' | '),
    );
    expect(sender.inFlight, 0);
  });

  test('a slow upload that keeps moving is not failed', () async {
    acceptTransfers = true;
    final file = File('${workspace.path}/slow.bin');
    await file.writeAsBytes(List<int>.filled(64 * 1024, 3));

    final manager = BatchTransferManager(
      fileSender: sender,
      preferencesService: PreferencesService(),
      historyManager: _NoHistory(),
    );

    final results = await manager.sendFilesWithBatchConfirm(
      targetIP: '127.0.0.1:${server.port}',
      files: [TransferFileItem(file: file, transferName: 'slow.bin')],
    );

    expect(
      results['slow.bin']?.isSuccess,
      isTrue,
      reason: results['slow.bin']?.errorMessage,
    );
  });

  test('cancel all leaves a file that already arrived out of the receiver '
      'notification', () async {
    acceptNames = {'done.bin'};
    final done = File('${workspace.path}/done.bin');
    await done.writeAsBytes(List<int>.filled(1024, 1));
    final stuck = File('${workspace.path}/stuck.bin');
    await stuck.writeAsBytes(List<int>.filled(4 * 1024 * 1024, 2));
    final items = [
      TransferFileItem(file: done, transferName: 'done.bin'),
      TransferFileItem(file: stuck, transferName: 'stuck.bin'),
    ];

    final cancellation = TransferCancellation();
    final manager = BatchTransferManager(
      fileSender: FileSender(stallTimeout: const Duration(seconds: 10)),
      preferencesService: PreferencesService(),
      historyManager: _NoHistory(),
    );

    double? lastOverall;
    final results = await manager.sendFilesWithBatchConfirm(
      targetIP: '127.0.0.1:${server.port}',
      files: items,
      cancellation: cancellation,
      onProgress: (fraction, _, _) => lastOverall = fraction,
      onFileProgress: (index, progress, _, _) {
        if (index == 0 && progress >= 1.0) {
          // A tap on "cancel all" arrives as its own event, after the
          // finished file has been settled.
          Timer(
            const Duration(milliseconds: 50),
            () => cancellation.cancelAll(items.map((i) => i.transferName)),
          );
        }
      },
    );

    expect(results['done.bin']?.isSuccess, isTrue);
    expect(results['stuck.bin']?.errorMessage, appText.transferCancelled);
    final body = await cancelBody.future.timeout(const Duration(seconds: 5));
    expect(body['transferIds'], ['id-stuck.bin']);
    // The cancelled file's unsent bytes left the total, so the bar closes.
    expect(lastOverall, 1.0);
  });

  test('history is saved even if a sent file is deleted before the batch '
      'ends', () async {
    acceptTransfers = true;
    final gone = File('${workspace.path}/gone.bin');
    await gone.writeAsBytes(List<int>.filled(1000, 1));
    final kept = File('${workspace.path}/kept.bin');
    await kept.writeAsBytes(List<int>.filled(2000, 2));
    final history = _RecordingHistory();
    final manager = BatchTransferManager(
      fileSender: FileSender(),
      preferencesService: PreferencesService(),
      historyManager: history,
    );

    await manager.sendFilesWithBatchConfirm(
      targetIP: '127.0.0.1:${server.port}',
      files: [
        TransferFileItem(file: gone, transferName: 'gone.bin'),
        TransferFileItem(file: kept, transferName: 'kept.bin'),
      ],
      onFileProgress: (index, progress, _, _) {
        if (index == 0 && progress >= 1.0 && gone.existsSync()) {
          gone.deleteSync();
        }
      },
    );

    expect(gone.existsSync(), isFalse);
    final sizes = {for (final h in history.saved) h.fileName: h.fileSize};
    expect(sizes, {'gone.bin': 1000, 'kept.bin': 2000});
  });

  test('a slow file holds one slot, not the whole next wave', () async {
    responseDelays = {'slow.bin': const Duration(milliseconds: 800)};
    acceptNames = {'slow.bin', 'quick1.bin', 'quick2.bin'};
    final items = <TransferFileItem>[];
    for (final name in ['slow.bin', 'quick1.bin', 'quick2.bin']) {
      final file = File('${workspace.path}/$name');
      await file.writeAsBytes(List<int>.filled(1024, 5));
      items.add(TransferFileItem(file: file, transferName: name));
    }

    final manager = BatchTransferManager(
      fileSender: FileSender(),
      preferencesService: PreferencesService(),
      historyManager: _NoHistory(),
    );
    final results = await manager.sendFilesWithBatchConfirm(
      targetIP: '127.0.0.1:${server.port}',
      files: items,
    );

    expect(results.values.every((r) => r.isSuccess), isTrue);
    // With two slots, the third file starts as soon as the first quick one
    // ends, and so finishes before the slow one rather than after it.
    expect(finishedOrder.last, 'slow.bin');
  });

  test('cancel all while the receiver is deciding stops waiting and '
      'withdraws the request', () async {
    holdConfirm = Completer<void>();
    final file = File('${workspace.path}/pending.bin');
    await file.writeAsBytes(List<int>.filled(1024, 1));
    final cancellation = TransferCancellation();
    final manager = BatchTransferManager(
      fileSender: FileSender(),
      preferencesService: PreferencesService(),
      historyManager: _NoHistory(),
    );

    final pending = manager.sendFilesWithBatchConfirm(
      targetIP: '127.0.0.1:${server.port}',
      files: [TransferFileItem(file: file, transferName: 'pending.bin')],
      cancellation: cancellation,
    );
    await confirmArrived.future;
    cancellation.cancelAll(['pending.bin']);
    final results = await pending.timeout(const Duration(seconds: 5));

    expect(results['pending.bin']?.errorMessage, appText.transferCancelled);
    final body = await cancelBody.future.timeout(const Duration(seconds: 5));
    expect(body['requestId'], isA<String>());
    expect(body['transferIds'], isEmpty);
    holdConfirm!.complete();
  });
}

Future<void> _writeJson(HttpRequest request, Object body) async {
  final bytes = utf8.encode(jsonEncode(body));
  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..contentLength = bytes.length
    ..add(bytes);
  await request.response.close();
}
