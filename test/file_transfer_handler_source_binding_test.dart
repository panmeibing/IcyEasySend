import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/file_transfer_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';

/// `/transfer` writes straight into the download folder with no further
/// prompting, on the strength of a transferId handed out by
/// `/batch-confirm-receive`. These tests cover the two things that keep that
/// from being an open door on a shared network: the ticket is unguessable, and
/// it only works from the address that was given it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secret = 'shared-secret';
  const senderAddress = '192.168.1.5';

  setUp(() {
    // A matching secret key is what lets the confirmation go through headless,
    // with no dialog and so no UI to stand up here.
    SharedPreferences.setMockInitialValues({'device_secret_key': secret});
  });

  Request confirmRequest({
    required String from,
    String fileName = 'report.pdf',
    int fileSize = 5,
  }) {
    return Request(
      'POST',
      Uri.parse('http://localhost:9527/batch-confirm-receive'),
      headers: {'x-secret-key': secret},
      body: jsonEncode({
        'senderIP': senderAddress,
        'senderDeviceName': 'Laptop',
        'files': [
          {'fileName': fileName, 'fileSize': fileSize},
        ],
      }),
      context: {'shelf.io.connection_info': _Connection(from)},
    );
  }

  Request transferRequest({
    required String from,
    required String transferId,
    String fileName = 'report.pdf',
    int fileSize = 5,
  }) {
    return Request(
      'POST',
      Uri.parse(
        'http://localhost:9527/transfer'
        '?fileName=$fileName&fileSize=$fileSize'
        '&senderIP=$senderAddress&transferId=$transferId',
      ),
      body: 'hello',
      context: {'shelf.io.connection_info': _Connection(from)},
    );
  }

  Future<String> confirmAndTakeTicket(
    FileTransferHandler handler, {
    required String from,
  }) async {
    final response = await handler.handleBatchConfirmReceive(
      confirmRequest(from: from),
    );
    expect(response.statusCode, 200);
    final body = jsonDecode(await response.readAsString()) as Map;
    expect(body['accepted'], isTrue);
    return (body['transferIds'] as Map)['report.pdf'] as String;
  }

  test('a ticket presented from another address is refused', () async {
    final handler = FileTransferHandler(contextGetter: () => null);
    final ticket = await confirmAndTakeTicket(handler, from: senderAddress);

    final response = await handler.handleFileTransfer(
      transferRequest(from: '192.168.1.99', transferId: ticket),
    );

    expect(response.statusCode, 403);
    final body = jsonDecode(await response.readAsString()) as Map;
    expect(body['message'], contains('传输来源与确认来源不符'));
  });

  test('refusing an impostor does not burn the real sender\'s ticket',
      () async {
    final handler = FileTransferHandler(contextGetter: () => null);
    final ticket = await confirmAndTakeTicket(handler, from: senderAddress);

    await handler.handleFileTransfer(
      transferRequest(from: '192.168.1.99', transferId: ticket),
    );

    // The sender gets past the source check; what happens after it is the file
    // service's business and needs platform plugins this test has not got.
    final response = await handler.handleFileTransfer(
      transferRequest(from: senderAddress, transferId: ticket),
    );

    final body = jsonDecode(await response.readAsString()) as Map;
    expect(body['message'], isNot(contains('传输来源与确认来源不符')));
    expect(body['message'], isNot(contains('未找到确认记录')));
  });

  test('tickets are unguessable rather than derived from the request', () async {
    final handler = FileTransferHandler(contextGetter: () => null);

    final first = await confirmAndTakeTicket(handler, from: senderAddress);
    final second = await confirmAndTakeTicket(handler, from: senderAddress);

    expect(first, isNot(second));
    // The old scheme was senderIP_fileName_millis, which anyone watching the
    // network could reconstruct.
    for (final ticket in [first, second]) {
      expect(ticket, isNot(contains(senderAddress)));
      expect(ticket, isNot(contains('report.pdf')));
      expect(ticket, matches(RegExp(r'^[0-9a-f]{32}$')));
    }
  });
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
