import 'dart:async';
import 'dart:collection';

import '../models/discovered_device.dart';
import '../utils/constants.dart';
import '../utils/http_helper.dart';
import '../utils/log_util.dart';
import '../utils/network_util.dart';
import 'multicast_discovery_service.dart';

/// Scans the local network for devices running Icy Easy Send.
///
/// Strategy (LocalSend-style):
/// 1. UDP multicast — fast (~2.6s), devices respond automatically
/// 2. HTTP subnet scan — fallback only when multicast finds nothing
class DeviceDiscoveryService {
  static final Duration _fastProbeTimeout = Duration(
    milliseconds: AppConstants.deviceScanDiscoveryTimeoutMs,
  );
  static final Duration _reliableProbeTimeout = Duration(
    seconds: AppConstants.deviceScanProbeTimeoutSeconds,
  );

  final MulticastDiscoveryService _multicast;
  final String logTag = LogTags.network;

  bool _cancelled = false;

  DeviceDiscoveryService({MulticastDiscoveryService? multicast})
    : _multicast = multicast ?? MulticastDiscoveryService.instance;

  void cancel() {
    _cancelled = true;
  }

  Future<List<DiscoveredDevice>> scan({
    required Set<String> localIps,
    void Function(int scanned, int total, List<DiscoveredDevice> found)?
        onProgress,
  }) async {
    _cancelled = false;

    final found = <DiscoveredDevice>[];
    final foundIps = <String>{};
    StreamSubscription<DiscoveredDevice>? multicastSubscription;

    void reportProgress({required int scanned, required int total}) {
      onProgress?.call(scanned, total, List.unmodifiable(found));
    }

    void addDevice(DiscoveredDevice device) {
      if (foundIps.add(device.ip)) {
        found.add(device);
        LogUtil.iTag(
          logTag,
          '发现设备: ${device.deviceName} (${device.displayAddress})',
        );
      }
    }

    multicastSubscription = _multicast.deviceStream.listen(addDevice);

    try {
      LogUtil.iTag(logTag, '阶段 0: UDP 组播发现');
      reportProgress(scanned: 0, total: 0);

      await _multicast.runDiscoveryRound(
        localIps: localIps,
        isCancelled: () => _cancelled,
      );

      reportProgress(scanned: 0, total: 0);

      if (_cancelled) {
        LogUtil.iTag(logTag, '设备扫描已取消, 已发现 ${found.length} 台设备');
        return found;
      }

      if (found.isNotEmpty) {
        LogUtil.iTag(
          logTag,
          '组播发现 ${found.length} 台设备，跳过 HTTP 全量扫描',
        );
        reportProgress(scanned: 1, total: 1);
        return found;
      }

      await _scanViaHttp(
        localIps: localIps,
        foundIps: foundIps,
        onDeviceFound: addDevice,
        reportProgress: reportProgress,
      );

      return found;
    } finally {
      await multicastSubscription.cancel();
    }
  }

  Future<void> _scanViaHttp({
    required Set<String> localIps,
    required Set<String> foundIps,
    required void Function(DiscoveredDevice device) onDeviceFound,
    required void Function({required int scanned, required int total})
        reportProgress,
  }) async {
    final ips = await NetworkUtil.getSubnetIPsForScan(excludeIps: localIps);
    if (ips.isEmpty) {
      LogUtil.wTag(logTag, '未找到可扫描的子网 IP');
      reportProgress(scanned: 1, total: 1);
      return;
    }

    LogUtil.iTag(logTag, '组播未发现设备，开始 HTTP 扫描: ${ips.length} 个 IP');

    final total = ips.length;
    var scanned = 0;

    await _scanIpsStreaming(
      ips: ips,
      ports: const [AppConstants.defaultPort],
      localIps: localIps,
      foundIps: foundIps,
      onDeviceFound: (device) {
        onDeviceFound(device);
        reportProgress(scanned: scanned, total: total);
      },
      concurrency: AppConstants.deviceScanFallbackConcurrency,
      timeout: _fastProbeTimeout,
      maxAttempts: 1,
      onScanned: (count) {
        scanned = count;
        reportProgress(scanned: scanned, total: total);
      },
    );

    if (_cancelled) {
      return;
    }

    final missedAfterFastPass =
        ips.where((ip) => !foundIps.contains(ip)).toList();
    if (missedAfterFastPass.isNotEmpty) {
      LogUtil.dTag(
        logTag,
        'HTTP 重试: ${missedAfterFastPass.length} 个 IP 的默认端口',
      );

      await _scanIpsStreaming(
        ips: missedAfterFastPass,
        ports: const [AppConstants.defaultPort],
        localIps: localIps,
        foundIps: foundIps,
        onDeviceFound: (device) {
          onDeviceFound(device);
          reportProgress(scanned: scanned, total: total);
        },
        concurrency: AppConstants.deviceScanRetryConcurrency,
        timeout: _reliableProbeTimeout,
        maxAttempts: AppConstants.deviceScanDefaultPortRetryAttempts,
        onScanned: (_) {
          reportProgress(scanned: scanned, total: total);
        },
      );
    }

    if (_cancelled) {
      return;
    }

    if (foundIps.isEmpty) {
      final alternatePorts = [
        for (
          var port = AppConstants.defaultPort + 1;
          port <= AppConstants.maxServerPort;
          port++
        )
          port,
      ];

      LogUtil.dTag(
        logTag,
        'HTTP 备用端口扫描: ${alternatePorts.first}-${alternatePorts.last}',
      );

      await _scanIpsStreaming(
        ips: ips,
        ports: alternatePorts,
        localIps: localIps,
        foundIps: foundIps,
        onDeviceFound: (device) {
          onDeviceFound(device);
          reportProgress(scanned: scanned, total: total);
        },
        concurrency: AppConstants.deviceScanRetryConcurrency,
        timeout: _reliableProbeTimeout,
        maxAttempts: AppConstants.deviceScanMaxAttempts,
        parallelPorts: true,
        onScanned: (count) {
          scanned = count;
          reportProgress(scanned: scanned, total: total);
        },
      );
    }

    LogUtil.iTag(logTag, '设备扫描完成, 发现 ${foundIps.length} 台设备');
    reportProgress(scanned: total, total: total);
  }

  Future<void> _scanIpsStreaming({
    required List<String> ips,
    required List<int> ports,
    required Set<String> localIps,
    required Set<String> foundIps,
    required void Function(DiscoveredDevice device) onDeviceFound,
    required void Function(int scanned) onScanned,
    required int concurrency,
    required Duration timeout,
    required int maxAttempts,
    bool parallelPorts = false,
  }) async {
    final queue = Queue<String>.from(ips);
    var scanned = 0;

    Future<void> worker() async {
      while (queue.isNotEmpty && !_cancelled) {
        final ip = queue.removeFirst();
        if (foundIps.contains(ip)) {
          scanned++;
          onScanned(scanned);
          continue;
        }

        final device = await _probeIp(
          ip,
          ports,
          localIps: localIps,
          timeout: timeout,
          maxAttempts: maxAttempts,
          parallelPorts: parallelPorts,
        );

        scanned++;
        onScanned(scanned);

        if (device != null) {
          onDeviceFound(device);
        }
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));
  }

  Future<DiscoveredDevice?> _probeIp(
    String ip,
    List<int> ports, {
    required Set<String> localIps,
    required Duration timeout,
    required int maxAttempts,
    bool parallelPorts = false,
  }) async {
    if (localIps.contains(ip)) {
      return null;
    }

    if (parallelPorts && ports.length > 1) {
      final results = await Future.wait(
        ports.map(
          (port) => _probeWithRetry(
            ip,
            port,
            timeout: timeout,
            maxAttempts: maxAttempts,
          ),
        ),
      );
      for (final device in results) {
        if (device != null) {
          return device;
        }
      }
      return null;
    }

    for (final port in ports) {
      if (_cancelled) {
        return null;
      }

      final device = await _probeWithRetry(
        ip,
        port,
        timeout: timeout,
        maxAttempts: maxAttempts,
      );
      if (device != null) {
        return device;
      }
    }
    return null;
  }

  Future<DiscoveredDevice?> _probeWithRetry(
    String ip,
    int port, {
    required Duration timeout,
    required int maxAttempts,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (_cancelled) {
        return null;
      }

      final device = await _probe(ip, port, timeout: timeout);
      if (device != null) {
        return device;
      }

      if (attempt < maxAttempts) {
        await Future.delayed(AppConstants.deviceScanRetryDelay);
      }
    }
    return null;
  }

  Future<DiscoveredDevice?> _probe(
    String ip,
    int port, {
    required Duration timeout,
  }) async {
    final url = NetworkUtil.buildHttpUrl(ip, '/health', targetPort: port);
    final result = await HttpHelper.get(url, timeout: timeout);
    if (!result.isSuccess) {
      return null;
    }

    final response = result.data!;
    if (!HttpHelper.isSuccessResponse(response)) {
      return null;
    }

    final jsonResult = HttpHelper.parseJsonResponse(response);
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
    final resolvedPort = (data['port'] as num?)?.toInt() ?? port;
    LogUtil.dTag(logTag, 'HTTP 探测成功 $ip:$resolvedPort ($deviceName)');
    return DiscoveredDevice(
      ip: ip,
      port: resolvedPort,
      deviceName: deviceName,
    );
  }
}
