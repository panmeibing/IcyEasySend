import '../models/discovered_device.dart';
import '../utils/constants.dart';
import '../utils/http_helper.dart';
import '../utils/log_util.dart';
import '../utils/network_util.dart';

/// Scans the local subnet for devices running Icy Easy Send.
class DeviceDiscoveryService {
  static const int _concurrency = 40;
  static const Duration _probeTimeout = Duration(seconds: 2);

  final String logTag = LogTags.network;

  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
  }

  /// Scan the local network in two phases: default port first, then the rest.
  Future<List<DiscoveredDevice>> scan({
    required Set<String> localIps,
    void Function(int scanned, int total, List<DiscoveredDevice> found)?
        onProgress,
  }) async {
    _cancelled = false;

    final ips = await NetworkUtil.getSubnetIPsForScan(excludeIps: localIps);
    if (ips.isEmpty) {
      LogUtil.wTag(logTag, '未找到可扫描的子网 IP');
      return [];
    }

    LogUtil.iTag(
      logTag,
      '开始设备扫描: 子网 ${ips.length} 个 IP, 本机 IP=${localIps.join(", ")}',
    );

    final found = <DiscoveredDevice>[];
    final foundIps = <String>{};
    var scanned = 0;
    final total = ips.length;

    void reportProgress() {
      onProgress?.call(scanned, total, List.unmodifiable(found));
    }

    // Phase 1: scan default port on all IPs.
    await _scanIpsOnPorts(
      ips: ips,
      ports: const [AppConstants.defaultPort],
      localIps: localIps,
      found: found,
      foundIps: foundIps,
      onBatchComplete: (batchSize) {
        scanned += batchSize;
        reportProgress();
      },
    );

    if (_cancelled) {
      LogUtil.iTag(logTag, '设备扫描已取消, 已发现 ${found.length} 台设备');
      return found;
    }

    // Phase 2: scan remaining ports for IPs not found in phase 1.
    final remainingIps = ips.where((ip) => !foundIps.contains(ip)).toList();
    if (remainingIps.isNotEmpty) {
      final remainingPorts = [
        for (
          var port = AppConstants.defaultPort + 1;
          port <= AppConstants.maxServerPort;
          port++
        )
          port,
      ];

      LogUtil.dTag(
        logTag,
        '阶段 2: 扫描 ${remainingIps.length} 个 IP 的端口 '
        '${remainingPorts.first}-${remainingPorts.last}',
      );

      await _scanIpsOnPorts(
        ips: remainingIps,
        ports: remainingPorts,
        localIps: localIps,
        found: found,
        foundIps: foundIps,
        onBatchComplete: (_) {
          reportProgress();
        },
      );
    }

    LogUtil.iTag(logTag, '设备扫描完成, 发现 ${found.length} 台设备');
    reportProgress();
    return found;
  }

  Future<void> _scanIpsOnPorts({
    required List<String> ips,
    required List<int> ports,
    required Set<String> localIps,
    required List<DiscoveredDevice> found,
    required Set<String> foundIps,
    required void Function(int batchSize) onBatchComplete,
  }) async {
    for (var i = 0; i < ips.length; i += _concurrency) {
      if (_cancelled) break;

      final batch = ips.skip(i).take(_concurrency).toList();
      final results = await Future.wait(
        batch.map((ip) => _probeIp(ip, ports, localIps: localIps)),
      );

      for (final device in results) {
        if (device != null && foundIps.add(device.ip)) {
          found.add(device);
          LogUtil.iTag(
            logTag,
            '发现设备: ${device.deviceName} (${device.displayAddress})',
          );
        }
      }

      onBatchComplete(batch.length);
    }
  }

  Future<DiscoveredDevice?> _probeIp(
    String ip,
    List<int> ports, {
    required Set<String> localIps,
  }) async {
    if (localIps.contains(ip)) {
      return null;
    }

    for (final port in ports) {
      if (_cancelled) return null;

      final device = await _probe(ip, port, localIps: localIps);
      if (device != null) {
        return device;
      }
    }
    return null;
  }

  Future<DiscoveredDevice?> _probe(
    String ip,
    int port, {
    required Set<String> localIps,
  }) async {
    if (localIps.contains(ip)) {
      return null;
    }

    final url = NetworkUtil.buildHttpUrl(ip, '/health', targetPort: port);
    final result = await HttpHelper.get(url, timeout: _probeTimeout);
    if (!result.isSuccess || !HttpHelper.isSuccessResponse(result.data!)) {
      return null;
    }

    final jsonResult = HttpHelper.parseJsonResponse(result.data!);
    if (!jsonResult.isSuccess) {
      return null;
    }

    final data = jsonResult.data!;
    if (data['status'] != 'ok') {
      return null;
    }

    final app = data['app'] as String?;
    if (app != null && app != AppConstants.projectNameTight) {
      return null;
    }

    final deviceName = data['deviceName'] as String? ?? ip;
    return DiscoveredDevice(ip: ip, port: port, deviceName: deviceName);
  }
}
