import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/transfer_data.dart';
import 'package:icy_easy_send/models/transfer_file_item.dart';
import 'package:icy_easy_send/services/transfer/batch_transfer_manager.dart';
import 'package:icy_easy_send/services/transfer/health_checker.dart';
import 'package:icy_easy_send/transport/lan_channel.dart';
import 'package:icy_easy_send/transport/transport_channel.dart';
import 'package:icy_easy_send/utils/operation_result.dart' show OperationResult;
import 'package:icy_easy_send/utils/transfer_status_provider.dart';

class _FakeHealthChecker implements HealthChecker {
  _FakeHealthChecker(this.result);

  final OperationResult<HealthCheckData> result;

  int calls = 0;
  String? lastTargetIP;
  Duration? lastTimeout;
  Object? throwOnCall;

  @override
  String logTag = 'fake';

  @override
  Future<OperationResult<HealthCheckData>> checkHealth(
    String targetIP, {
    Duration? timeout,
  }) async {
    calls++;
    lastTargetIP = targetIP;
    lastTimeout = timeout;
    final error = throwOnCall;
    if (error != null) {
      throw error;
    }
    return result;
  }
}

class _FakeBatchTransferManager implements BatchTransferManager {
  _FakeBatchTransferManager(this.results);

  final Map<String, OperationResult<TransferData>> results;

  int calls = 0;
  String? lastTargetIP;
  List<TransferFileItem>? lastFiles;
  String? lastSecretKey;
  bool sawProgressCallback = false;
  bool sawFileProgressCallback = false;
  bool sawStatusCallback = false;
  bool sawHistoryCallback = false;

  @override
  String get logTag => 'fake';

  @override
  Future<Map<String, OperationResult<TransferData>>> sendFilesWithBatchConfirm({
    required String targetIP,
    required List<TransferFileItem> files,
    String? secretKey,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    void Function(
      int fileIndex,
      double progress,
      int bytesTransferred,
      int totalBytes,
    )?
    onFileProgress,
    void Function(String status)? onStatusChange,
    VoidCallback? onHistoryUpdated,
  }) async {
    calls++;
    lastTargetIP = targetIP;
    lastFiles = files;
    lastSecretKey = secretKey;
    sawProgressCallback = onProgress != null;
    sawFileProgressCallback = onFileProgress != null;
    sawStatusCallback = onStatusChange != null;
    sawHistoryCallback = onHistoryUpdated != null;
    return results;
  }
}

TransferFileItem _item(String name) {
  return TransferFileItem(file: File(name), transferName: name);
}

OperationResult<HealthCheckData> _healthy(String deviceName) {
  return OperationResult.success(
    data: HealthCheckData(
      deviceName: deviceName,
      version: 'v1.4.0',
      isReady: true,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHealthChecker healthChecker;
  late _FakeBatchTransferManager manager;
  late LanChannel channel;

  setUp(() {
    healthChecker = _FakeHealthChecker(_healthy('Desktop'));
    manager = _FakeBatchTransferManager({});
    channel = LanChannel(
      batchTransferManager: manager,
      healthChecker: healthChecker,
    );
  });

  test('reports the lan kind', () {
    expect(channel.kind, TransportKind.lan);
  });

  test('start and stop are no-ops', () async {
    await expectLater(channel.start(), completes);
    await expectLater(channel.stop(), completes);
  });

  group('probe', () {
    test(
      'returns unavailable without calling out when there is no endpoint',
      () async {
        final result = await channel.probe(const PeerRef(deviceId: 'a3f2'));

        expect(result.ok, isFalse);
        expect(result.attempted, isFalse);
        expect(result.kind, TransportKind.lan);
        expect(
          result.errorMessage,
          TransferStatusProvider().lanRouteUnavailable,
        );
        expect(healthChecker.calls, 0);
      },
    );

    test('reports a healthy peer as reachable', () async {
      final result = await channel.probe(
        PeerRef.lanAddress('192.168.1.10:9527'),
      );

      expect(result.ok, isTrue);
      expect(result.attempted, isTrue);
      expect(result.deviceName, 'Desktop');
      expect(result.rtt, isNotNull);
      expect(healthChecker.lastTargetIP, '192.168.1.10:9527');
    });

    test('forwards the timeout to the health checker', () async {
      await channel.probe(
        PeerRef.lanAddress('192.168.1.10:9527'),
        timeout: const Duration(milliseconds: 600),
      );

      expect(healthChecker.lastTimeout, const Duration(milliseconds: 600));
    });

    test(
      'leaves the timeout unset so the health checker keeps its default',
      () async {
        await channel.probe(PeerRef.lanAddress('192.168.1.10:9527'));

        expect(healthChecker.lastTimeout, isNull);
      },
    );

    test('maps a failed health check to unreachable', () async {
      healthChecker = _FakeHealthChecker(OperationResult.failure('boom'));
      channel = LanChannel(
        batchTransferManager: manager,
        healthChecker: healthChecker,
      );

      final result = await channel.probe(
        PeerRef.lanAddress('192.168.1.10:9527'),
      );

      expect(result.ok, isFalse);
      expect(result.attempted, isTrue);
      expect(result.errorMessage, 'boom');
    });

    test('never throws, even when the health checker does', () async {
      healthChecker.throwOnCall = const SocketException('no route');

      final result = await channel.probe(
        PeerRef.lanAddress('192.168.1.10:9527'),
      );

      expect(result.ok, isFalse);
      expect(result.attempted, isTrue);
      expect(result.errorMessage, contains('no route'));
    });
  });

  group('sendFiles', () {
    test('delegates to the batch manager using the peer address', () async {
      final files = [_item('a.txt'), _item('nested/b.txt')];
      manager = _FakeBatchTransferManager({
        'a.txt': OperationResult.success(
          data: TransferData(savedPath: '/tmp/a.txt', bytesTransferred: 5),
        ),
        'nested/b.txt': OperationResult.failure('nope'),
      });
      channel = LanChannel(
        batchTransferManager: manager,
        healthChecker: healthChecker,
      );

      final results = await channel.sendFiles(
        peer: PeerRef.lanAddress('192.168.1.10:9527'),
        files: files,
        secretKey: 'shhh',
        onProgress: (_, _, _) {},
        onFileProgress: (_, _, _, _) {},
        onStatusChange: (_) {},
        onHistoryUpdated: () {},
      );

      expect(manager.calls, 1);
      expect(manager.lastTargetIP, '192.168.1.10:9527');
      expect(manager.lastFiles, same(files));
      expect(manager.lastSecretKey, 'shhh');
      expect(manager.sawProgressCallback, isTrue);
      expect(manager.sawFileProgressCallback, isTrue);
      expect(manager.sawStatusCallback, isTrue);
      expect(manager.sawHistoryCallback, isTrue);

      expect(results.keys, containsAll(<String>['a.txt', 'nested/b.txt']));
      expect(results['a.txt']!.data!.savedPath, '/tmp/a.txt');
      expect(results['nested/b.txt']!.errorMessage, 'nope');
    });

    test('passes a bare ip through unchanged', () async {
      await channel.sendFiles(
        peer: PeerRef.lanAddress('192.168.1.10'),
        files: [_item('a.txt')],
      );

      // Transfer history records this string, so it must not gain a port.
      expect(manager.lastTargetIP, '192.168.1.10');
    });

    test('fails every file when the peer has no endpoint', () async {
      final results = await channel.sendFiles(
        peer: const PeerRef(deviceId: 'a3f2'),
        files: [_item('a.txt'), _item('b.txt')],
      );

      expect(manager.calls, 0);
      expect(results.length, 2);
      for (final result in results.values) {
        expect(result.isFailure, isTrue);
        expect(
          result.errorMessage,
          TransferStatusProvider().lanRouteUnavailable,
        );
      }
    });
  });
}
