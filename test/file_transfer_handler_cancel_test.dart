import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/transfer_data.dart';
import 'package:icy_easy_send/models/transfer_history.dart';
import 'package:icy_easy_send/services/batch_receive_manager.dart';
import 'package:icy_easy_send/services/file_transfer_handler.dart';
import 'package:icy_easy_send/services/file_transfer_service.dart';
import 'package:icy_easy_send/services/transfer/transfer_history_manager.dart';
import 'package:icy_easy_send/utils/operation_result.dart';
import 'package:icy_easy_send/utils/peer_error.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';

/// A file the receiver called off must stay refused for as long as its ticket
/// exists, not only while the progress dialog is on screen. The dialog closes
/// by itself once every file has ended, and cancelled files count as ended.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secret = 'shared-secret';
  const senderAddress = '192.168.1.7';

  setUp(() {
    // A matching secret key lets the confirmation go through headless, with
    // no dialog and so no UI to stand up here.
    SharedPreferences.setMockInitialValues({'device_secret_key': secret});
  });

  Future<Map<String, String>> confirm(
    FileTransferHandler handler,
    List<String> names, {
    String? requestId,
  }) async {
    final response = await handler.handleBatchConfirmReceive(
      Request(
        'POST',
        Uri.parse('http://localhost:9527/batch-confirm-receive'),
        headers: {'x-secret-key': secret},
        body: jsonEncode({
          'senderIP': senderAddress,
          'files': [
            for (final name in names) {'fileName': name, 'fileSize': 5},
          ],
          'requestId': ?requestId,
        }),
        context: {'shelf.io.connection_info': _Connection(senderAddress)},
      ),
    );
    expect(response.statusCode, 200);
    final body = jsonDecode(await response.readAsString()) as Map;
    return Map<String, String>.from(body['transferIds'] as Map);
  }

  Request transfer(String name, String transferId) {
    return Request(
      'POST',
      Uri.parse(
        'http://localhost:9527/transfer'
        '?fileName=$name&fileSize=5'
        '&senderIP=$senderAddress&transferId=$transferId',
      ),
      body: 'hello',
      context: {'shelf.io.connection_info': _Connection(senderAddress)},
    );
  }

  Future<Response> batchCancel(
    FileTransferHandler handler, {
    List<String> transferIds = const [],
    String? requestId,
    String from = senderAddress,
  }) {
    return handler.handleBatchCancel(
      Request(
        'POST',
        Uri.parse('http://localhost:9527/batch-cancel'),
        body: jsonEncode({'transferIds': transferIds, 'requestId': ?requestId}),
        context: {'shelf.io.connection_info': _Connection(from)},
      ),
    );
  }

  Future<String> statusOf(
    FileTransferHandler handler,
    String transferId, {
    String from = senderAddress,
  }) async {
    final response = await handler.handleTransferStatus(
      Request(
        'GET',
        Uri.parse(
          'http://localhost:9527/transfer-status?transferId=$transferId',
        ),
        context: {'shelf.io.connection_info': _Connection(from)},
      ),
    );
    final body = jsonDecode(await response.readAsString()) as Map;
    return body['state'] as String;
  }

  test('a sender that withdraws its request takes back every ticket it was '
      'given', () async {
    final handler = FileTransferHandler(contextGetter: () => null);
    final ids = await confirm(handler, ['w.txt'], requestId: 'req-1');

    final withdrawn = await batchCancel(handler, requestId: 'req-1');
    expect(withdrawn.statusCode, 200);
    final response = await handler.handleFileTransfer(
      transfer('w.txt', ids['w.txt']!),
    );

    expect(response.statusCode, 403);
    final body = jsonDecode(await response.readAsString()) as Map;
    expect(body['code'], PeerError.notConfirmed.code);
  });

  test('a withdrawal from another address is ignored', () async {
    final handler = FileTransferHandler(
      contextGetter: () => null,
      fileTransferService: _DrainingService(),
      historyManager: _RecordingHistory(),
    );
    final ids = await confirm(handler, ['keep.txt'], requestId: 'req-2');

    await batchCancel(handler, requestId: 'req-2', from: '192.168.1.99');
    final response = await handler.handleFileTransfer(
      transfer('keep.txt', ids['keep.txt']!),
    );

    expect(response.statusCode, 200);
  });

  test('the status endpoint tells the sender a refused file was cancelled, '
      'and nobody else', () async {
    final handler = FileTransferHandler(contextGetter: () => null);
    final ids = await confirm(handler, ['s.txt']);
    final id = ids['s.txt']!;
    expect(await statusOf(handler, id), 'unknown');

    BatchReceiveManager().cancelTransfer(id);
    await handler.handleFileTransfer(transfer('s.txt', id));

    expect(await statusOf(handler, id), 'cancelled');
    expect(await statusOf(handler, id, from: '192.168.1.99'), 'unknown');
    expect(await statusOf(handler, 'no-such-id'), 'unknown');
  });

  test('history is saved once the last file is cancelled instead of '
      'arriving', () async {
    final history = _RecordingHistory();
    final handler = FileTransferHandler(
      contextGetter: () => null,
      fileTransferService: _DrainingService(),
      historyManager: history,
    );
    final ids = await confirm(handler, ['got.txt', 'dropped.txt']);

    final received = await handler.handleFileTransfer(
      transfer('got.txt', ids['got.txt']!),
    );
    expect(received.statusCode, 200);
    expect(history.saved, isEmpty);

    await batchCancel(handler, transferIds: [ids['dropped.txt']!]);

    expect(history.saved.map((h) => h.fileName), ['got.txt']);
  });

  test('a file cancelled before it arrived is refused after the batch is '
      'no longer tracked', () async {
    final handler = FileTransferHandler(contextGetter: () => null);
    final ids = await confirm(handler, ['late.txt']);

    BatchReceiveManager().cancelTransfer(ids['late.txt']!);
    // What the dialog closing does to the manager's bookkeeping.
    BatchReceiveManager().clearPendingForSender(senderAddress);

    final response = await handler.handleFileTransfer(
      transfer('late.txt', ids['late.txt']!),
    );

    expect(response.statusCode, 409);
    final body = jsonDecode(await response.readAsString()) as Map;
    expect(body['code'], PeerError.cancelled.code);
  });

  test('a refused cancelled file does not leave its ticket behind', () async {
    final handler = FileTransferHandler(contextGetter: () => null);
    final ids = await confirm(handler, ['once.txt']);
    BatchReceiveManager().cancelTransfer(ids['once.txt']!);

    await handler.handleFileTransfer(transfer('once.txt', ids['once.txt']!));
    final again = await handler.handleFileTransfer(
      transfer('once.txt', ids['once.txt']!),
    );

    expect(again.statusCode, 403);
    final body = jsonDecode(await again.readAsString()) as Map;
    expect(body['code'], PeerError.notConfirmed.code);
  });
}

/// Takes the body and reports it saved, without touching the disk.
class _DrainingService extends FileTransferService {
  @override
  Future<OperationResult<TransferData>> receiveFileDirectly({
    required Stream<List<int>> fileStream,
    required String fileName,
    required int fileSize,
    required String senderIP,
    String? senderDeviceName,
    void Function(double progress, int bytesReceived, int totalBytes)?
    onProgress,
    Future<void>? cancel,
  }) async {
    await fileStream.drain<void>();
    return OperationResult.success(
      data: TransferData(savedPath: 'mem', bytesTransferred: fileSize),
    );
  }
}

class _RecordingHistory extends TransferHistoryManager {
  final saved = <TransferHistory>[];

  @override
  Future<void> saveTransferHistoryBatch(List<TransferHistory> histories) async {
    saved.addAll(histories);
  }
}

class _Connection implements HttpConnectionInfo {
  _Connection(String address) : remoteAddress = InternetAddress(address);

  @override
  final InternetAddress remoteAddress;

  @override
  int get remotePort => 51234;

  @override
  int get localPort => 9527;
}
