import 'package:flutter/foundation.dart';

import '../models/transfer_data.dart';
import '../models/transfer_file_item.dart';
import '../services/transfer/batch_transfer_manager.dart';
import '../services/transfer/health_checker.dart';
import '../utils/log_util.dart';
import '../utils/operation_result.dart';
import '../utils/transfer_status_provider.dart';
import 'transport_channel.dart';

/// Direct device-to-device transfer over the local network.
///
/// Wraps the existing plain-HTTP implementation: [BatchTransferManager] drives
/// the `/batch-confirm-receive` handshake and the `/transfer` uploads, while
/// [HealthChecker] backs [probe] via `/health`.
class LanChannel implements TransportChannel {
  final BatchTransferManager _batchTransferManager;
  final HealthChecker _healthChecker;
  final TransferStatusProvider _statusProvider;
  final String logTag = LogTags.transfer;

  LanChannel({
    BatchTransferManager? batchTransferManager,
    HealthChecker? healthChecker,
    TransferStatusProvider? statusProvider,
  }) : _batchTransferManager = batchTransferManager ?? BatchTransferManager(),
       _healthChecker = healthChecker ?? HealthChecker(),
       _statusProvider = statusProvider ?? TransferStatusProvider();

  @override
  TransportKind get kind => TransportKind.lan;

  /// The inbound side is the shelf server owned by `HTTPServerManager`, which
  /// has its own lifecycle, so there is nothing to bring up here.
  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<ProbeResult> probe(PeerRef peer, {Duration? timeout}) async {
    final lan = peer.lan;
    if (lan == null) {
      return ProbeResult.unavailable(
        kind: kind,
        errorMessage: _statusProvider.lanRouteUnavailable,
      );
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = await _healthChecker.checkHealth(
        lan.address,
        timeout: timeout,
      );
      stopwatch.stop();

      if (!result.isSuccess) {
        return ProbeResult.unreachable(
          kind: kind,
          errorMessage: result.errorMessage ?? '',
        );
      }

      return ProbeResult.reachable(
        kind: kind,
        rtt: stopwatch.elapsed,
        deviceName: result.data?.deviceName,
      );
    } catch (e) {
      stopwatch.stop();
      LogUtil.wTag(logTag, 'LAN probe failed for ${lan.address}: $e');
      return ProbeResult.unreachable(kind: kind, errorMessage: e.toString());
    }
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
    final lan = peer.lan;
    if (lan == null) {
      LogUtil.wTag(logTag, 'sendFiles() peer has no LAN endpoint: $peer');
      return {
        for (final item in files)
          item.transferName: OperationResult<TransferData>.failure(
            _statusProvider.lanRouteUnavailable,
          ),
      };
    }

    return _batchTransferManager.sendFilesWithBatchConfirm(
      targetIP: lan.address,
      files: files,
      secretKey: secretKey,
      onProgress: onProgress,
      onFileProgress: onFileProgress,
      onStatusChange: onStatusChange,
      onHistoryUpdated: onHistoryUpdated,
    );
  }
}
