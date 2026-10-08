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
/// Strategy (LocalSend staged scan):
/// 1. UDP multicast announcement, overlapped with a 1s grace period.
///    Peers answer with one HTTP register and show up as soon as it arrives.
/// 2. HTTP subnet scan of [AppConstants.defaultPort] only when that grace
///    period ends with nobody — 500ms per host, 50 at a time.
class DeviceDiscoveryService {
  static final Duration _probeTimeout = Duration(
    milliseconds: AppConstants.deviceScanDiscoveryTimeoutMs,
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
    final foundIds = <String>{};
    StreamSubscription<DiscoveredDevice>? multicastSubscription;
    var progressScanned = 0;
    var progressTotal = 0;

    void reportProgress() {
      onProgress?.call(
        progressScanned,
        progressTotal,
        List.unmodifiable(found),
      );
    }

    void addDevice(DiscoveredDevice device) {
      if (device.hasIdentity) {
        final id = device.deviceId!;
        final existingIndex = found.indexWhere((d) => d.deviceId == id);
        if (existingIndex >= 0) {
          // Same device, possibly a fresher name or address.
          foundIps.remove(found[existingIndex].ip);
          found[existingIndex] = device;
          foundIps.add(device.ip);
          reportProgress();
          return;
        }
        if (!foundIds.add(id)) {
          return;
        }
        // Drop a prior anonymous entry that occupied this IP.
        found.removeWhere((d) => !d.hasIdentity && d.ip == device.ip);
        foundIps.add(device.ip);
        found.add(device);
        LogUtil.iTag(
          logTag,
          '发现设备: ${device.deviceName} (${device.displayAddress}, id=${id.substring(0, 8)})',
        );
        reportProgress();
        return;
      }

      if (foundIps.add(device.ip)) {
        found.add(device);
        LogUtil.iTag(
          logTag,
          '发现设备: ${device.deviceName} (${device.displayAddress})',
        );
        reportProgress();
      }
    }

    multicastSubscription = _multicast.deviceStream.listen(addDevice);

    try {
      LogUtil.iTag(logTag, '阶段 0: UDP 组播发现');
      reportProgress();

      final round = Stopwatch()..start();
      await _multicast.runDiscoveryRound(
        localIps: localIps,
        isCancelled: () => _cancelled,
        hasPeer: () => found.isNotEmpty,
      );
      LogUtil.iTag(
        logTag,
        'UDP 组播发现结束 ${round.elapsedMilliseconds}ms, 已发现 ${found.length} 台设备',
      );

      if (_cancelled) {
        LogUtil.iTag(logTag, '设备扫描已取消, 已发现 ${found.length} 台设备');
        return found;
      }

      if (found.isNotEmpty) {
        LogUtil.iTag(logTag, '组播发现 ${found.length} 台设备，跳过 HTTP 全量扫描');
        progressScanned = 1;
        progressTotal = 1;
        reportProgress();
        return found;
      }

      await _scanViaHttp(
        localIps: localIps,
        foundIps: foundIps,
        onDeviceFound: addDevice,
        onScanned: (scanned, total) {
          progressScanned = scanned;
          progressTotal = total;
          reportProgress();
        },
      );

      return found;
    } finally {
      _multicast.stopAcceptingRegistrations();
      await multicastSubscription.cancel();
    }
  }

  Future<void> _scanViaHttp({
    required Set<String> localIps,
    required Set<String> foundIps,
    required void Function(DiscoveredDevice device) onDeviceFound,
    required void Function(int scanned, int total) onScanned,
  }) async {
    final ips = await NetworkUtil.getSubnetIPsForScan(excludeIps: localIps);
    if (ips.isEmpty) {
      LogUtil.wTag(logTag, '未找到可扫描的子网 IP');
      onScanned(1, 1);
      return;
    }

    LogUtil.iTag(
      logTag,
      '组播未发现设备，开始 HTTP 扫描: ${ips.length} 个 IP '
      '(端口 ${AppConstants.defaultPort}, 超时 ${_probeTimeout.inMilliseconds}ms)',
    );

    final total = ips.length;
    var scanned = 0;
    final queue = Queue<String>.from(ips);

    Future<void> worker() async {
      while (queue.isNotEmpty && !_cancelled) {
        final ip = queue.removeFirst();
        if (localIps.contains(ip) || foundIps.contains(ip)) {
          scanned++;
          onScanned(scanned, total);
          continue;
        }

        final device = await _probe(
          ip,
          AppConstants.defaultPort,
          timeout: _probeTimeout,
        );

        scanned++;
        onScanned(scanned, total);

        if (device != null) {
          onDeviceFound(device);
        }
      }
    }

    await Future.wait(
      List.generate(
        AppConstants.deviceScanFallbackConcurrency,
        (_) => worker(),
      ),
    );

    if (_cancelled) {
      return;
    }

    LogUtil.iTag(logTag, '设备扫描完成, 发现 ${foundIps.length} 台设备');
    onScanned(total, total);
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
    final deviceId = data['deviceId'] as String?;
    final publicKey = data['publicKey'] as String?;
    LogUtil.dTag(logTag, 'HTTP 探测成功 $ip:$resolvedPort ($deviceName)');
    return DiscoveredDevice(
      ip: ip,
      port: resolvedPort,
      deviceName: deviceName,
      deviceId: deviceId != null && deviceId.isNotEmpty ? deviceId : null,
      publicKey: publicKey != null && publicKey.isNotEmpty ? publicKey : null,
    );
  }
}
