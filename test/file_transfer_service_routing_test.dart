import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/transfer_data.dart';
import 'package:icy_easy_send/models/transfer_file_item.dart';
import 'package:icy_easy_send/services/file_transfer_service.dart';
import 'package:icy_easy_send/transport/transport_channel.dart';
import 'package:icy_easy_send/utils/operation_result.dart';

class _RecordingChannel implements TransportChannel {
  _RecordingChannel({
    this.kind = TransportKind.lan,
    this.results = const {},
  });

  @override
  final TransportKind kind;

  final Map<String, OperationResult<TransferData>> results;
  bool probeOk = true;

  PeerRef? lastPeer;
  List<TransferFileItem>? lastFiles;
  String? lastSecretKey;
  PeerRef? lastProbedPeer;
  Duration? lastProbeTimeout;
  int probeCalls = 0;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> start() async => startCalls++;

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<ProbeResult> probe(PeerRef peer, {Duration? timeout}) async {
    probeCalls++;
    lastProbedPeer = peer;
    lastProbeTimeout = timeout;
    if (!probeOk) {
      return ProbeResult.unreachable(
        kind: kind,
        errorMessage: '${kind.name} down',
      );
    }
    return ProbeResult.reachable(
      kind: kind,
      rtt: const Duration(milliseconds: 1),
    );
  }

  @override
  Future<Map<String, OperationResult<TransferData>>> sendFiles({
    required PeerRef peer,
    required List<TransferFileItem> files,
    String? secretKey,
    TransferProgressCallback? onProgress,
    FileProgressCallback? onFileProgress,
    void Function(String status)? onStatusChange,
    VoidCallback? onHistoryUpdated,
  }) async {
    lastPeer = peer;
    lastFiles = files;
    lastSecretKey = secretKey;
    return results;
  }
}

TransferFileItem _item(String name) {
  return TransferFileItem(file: File(name), transferName: name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingChannel channel;
  late _RecordingChannel relayChannel;
  late FileTransferService service;

  setUp(() {
    channel = _RecordingChannel();
    relayChannel = _RecordingChannel(kind: TransportKind.relay);
    service = FileTransferService(
      lanChannel: channel,
      relayChannel: relayChannel,
    );
  });

  test(
    'the legacy targetIP entry point routes through the LAN channel',
    () async {
      await service.sendFilesWithBatchConfirm(
        targetIP: '192.168.1.10:9527',
        files: [_item('a.txt')],
        secretKey: 'shhh',
      );

      expect(channel.lastPeer, isNotNull);
      expect(channel.lastPeer!.lan!.address, '192.168.1.10:9527');
      expect(channel.lastSecretKey, 'shhh');
      expect(channel.lastFiles!.single.transferName, 'a.txt');
    },
  );

  test('a bare targetIP reaches the channel unchanged', () async {
    await service.sendFilesWithBatchConfirm(
      targetIP: '192.168.1.10',
      files: [_item('a.txt')],
    );

    expect(channel.lastPeer!.lan!.address, '192.168.1.10');
  });

  test('results are returned exactly as the channel produced them', () async {
    final produced = <String, OperationResult<TransferData>>{
      'a.txt': OperationResult.success(
        data: TransferData(savedPath: '/tmp/a.txt', bytesTransferred: 12),
      ),
      'b.txt': OperationResult.failure('nope'),
    };
    channel = _RecordingChannel(results: produced);
    service = FileTransferService(
      lanChannel: channel,
      relayChannel: relayChannel,
    );

    final results = await service.sendFilesWithBatchConfirm(
      targetIP: '192.168.1.10:9527',
      files: [_item('a.txt'), _item('b.txt')],
    );

    expect(results.length, 2);
    expect(results['a.txt']!.isSuccess, isTrue);
    expect(results['a.txt']!.data!.savedPath, '/tmp/a.txt');
    expect(results['a.txt']!.data!.bytesTransferred, 12);
    expect(results['b.txt']!.isFailure, isTrue);
    expect(results['b.txt']!.errorMessage, 'nope');
  });

  test('sendFilesTo forwards the peer untouched', () async {
    final peer = PeerRef(
      deviceId: 'a3f2',
      deviceName: 'Laptop',
      lan: LanEndpoint.parse('192.168.1.10:9527'),
    );

    await service.sendFilesTo(peer: peer, files: [_item('a.txt')]);

    expect(channel.lastPeer, same(peer));
  });

  test('a peer without a LAN endpoint goes over the relay', () async {
    const peer = PeerRef(
      deviceId: 'a3f2',
      deviceName: 'Laptop',
      relayOnline: true,
    );

    await service.sendFilesTo(peer: peer, files: [_item('a.txt')]);

    expect(relayChannel.lastPeer, same(peer));
    expect(channel.lastPeer, isNull);
  });

  test('a LAN endpoint wins even when the peer is also on the relay', () async {
    final peer = PeerRef(
      deviceId: 'a3f2',
      lan: LanEndpoint.parse('192.168.1.10:9527'),
      relayOnline: true,
    );

    await service.sendFilesTo(peer: peer, files: [_item('a.txt')]);

    expect(channel.lastPeer!.deviceId, peer.deviceId);
    expect(channel.lastPeer!.lan!.address, peer.lan!.address);
    expect(relayChannel.lastPeer, isNull);
  });

  test('falls back to the relay when the LAN probe fails', () async {
    channel.probeOk = false;
    final peer = PeerRef(
      deviceId: 'a3f2',
      lan: LanEndpoint.parse('192.168.1.10:9527'),
      relayOnline: true,
    );

    await service.sendFilesTo(peer: peer, files: [_item('a.txt')]);

    expect(relayChannel.lastPeer!.deviceId, 'a3f2');
    expect(channel.lastPeer, isNull);
  });

  test('fails every file when neither channel can reach the peer', () async {
    channel.probeOk = false;
    relayChannel.probeOk = false;
    final peer = PeerRef(
      deviceId: 'a3f2',
      lan: LanEndpoint.parse('192.168.1.10:9527'),
      relayOnline: true,
    );

    final results = await service.sendFilesTo(
      peer: peer,
      files: [_item('a.txt')],
    );

    expect(results['a.txt']!.isSuccess, isFalse);
    expect(channel.lastPeer, isNull);
    expect(relayChannel.lastPeer, isNull);
  });

  test('probe races the same way a send would', () async {
    final peer = PeerRef.lanAddress('192.168.1.10:9527');

    final result = await service.probe(
      peer,
      timeout: const Duration(milliseconds: 600),
    );

    expect(result.ok, isTrue);
    expect(channel.lastProbedPeer!.lan!.address, '192.168.1.10:9527');
    expect(channel.lastProbeTimeout, const Duration(milliseconds: 600));
  });

  test('probe of a relay-only peer goes to the relay channel', () async {
    const peer = PeerRef(deviceId: 'a3f2', relayOnline: true);

    final result = await service.probe(peer);

    expect(result.kind, TransportKind.relay);
    expect(result.ok, isTrue);
    expect(relayChannel.lastProbedPeer!.deviceId, 'a3f2');
    expect(channel.probeCalls, 0);
  });
}
