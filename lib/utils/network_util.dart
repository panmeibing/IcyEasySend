import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import 'constants.dart';
import 'log_util.dart';

/// Utility class for network-related operations
class NetworkUtil {
  static final String logTag = LogTags.network;

  /// Get the local IP address of the device
  ///
  /// Priority order:
  /// 1. Private network addresses (192.168.x.x, 172.16-31.x.x, 10.x.x.x)
  /// 2. Other non-loopback IPv4 addresses
  /// 3. Fallback to 127.0.0.1
  static Future<String> getLocalIPAddress() async {
    try {
      LogUtil.dTag(logTag, '获取本地IP地址...');

      // Get all network interfaces
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      LogUtil.dTag(logTag, '找到${interfaces.length}个网络接口');

      List<String> privateAddresses = [];
      List<String> otherAddresses = [];

      // Categorize addresses
      for (var interface in interfaces) {
        LogUtil.dTag(logTag, '检查接口: ${interface.name}');
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;

            // Check if it's a private network address
            if (isPrivateNetwork(ip)) {
              LogUtil.dTag(logTag, '发现私有网络地址: $ip (${interface.name})');
              privateAddresses.add(ip);
            } else {
              LogUtil.dTag(logTag, '发现其他地址: $ip (${interface.name})');
              otherAddresses.add(ip);
            }
          }
        }
      }

      // Prefer private network addresses (typical LAN)
      if (privateAddresses.isNotEmpty) {
        // Sort to prefer 192.168.x.x over 10.x.x.x
        privateAddresses.sort((a, b) {
          if (a.startsWith('192.168.')) return -1;
          if (b.startsWith('192.168.')) return 1;
          if (a.startsWith('172.')) return -1;
          if (b.startsWith('172.')) return 1;
          return 0;
        });
        LogUtil.iTag(logTag, '本地IP地址: ${privateAddresses.first}');
        return privateAddresses.first;
      }

      // Use other addresses if no private network found
      if (otherAddresses.isNotEmpty) {
        LogUtil.iTag(logTag, '本地IP地址: ${otherAddresses.first}');
        return otherAddresses.first;
      }

      // Fallback to localhost if no network interface found
      LogUtil.wTag(logTag, '未找到有效网络接口，使用回环地址: 127.0.0.1');
      return '127.0.0.1';
    } catch (e, stackTrace) {
      // If error, return localhost
      LogUtil.eTag(logTag, '获取IP地址失败，使用回环地址: $e', e, stackTrace);
      return '127.0.0.1';
    }
  }

  /// Check if an IP address is in a private network range
  ///
  /// Private network ranges:
  /// - 192.168.0.0/16 (192.168.0.0 - 192.168.255.255)
  /// - 172.16.0.0/12 (172.16.0.0 - 172.31.255.255)
  /// - 10.0.0.0/8 (10.0.0.0 - 10.255.255.255)
  static bool isPrivateNetwork(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    try {
      final first = int.parse(parts[0]);
      final second = int.parse(parts[1]);

      // 192.168.x.x
      if (first == 192 && second == 168) {
        return true;
      }

      // 172.16.x.x - 172.31.x.x
      if (first == 172 && second >= 16 && second <= 31) {
        return true;
      }

      // 10.x.x.x
      if (first == 10) {
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '检查私有网络失败: $ip, 错误=$e', e, stackTrace);
      return false;
    }
  }

  /// Get device name/model
  ///
  /// Returns the device model name using device_info_plus package.
  /// Falls back to Platform.localHostname if device info is unavailable.
  static Future<String> getDeviceName() async {
    LogUtil.dTag(logTag, '获取设备名称...');

    try {
      final deviceInfo = DeviceInfoPlugin();

      String deviceName;
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        deviceName = macInfo.computerName;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceName = windowsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceName = linuxInfo.name;
      } else {
        // Fallback to hostname
        try {
          deviceName = Platform.localHostname;
          LogUtil.dTag(logTag, '使用主机名作为设备名: $deviceName');
        } catch (e, stackTrace) {
          LogUtil.wTag(logTag, '无法获取主机名: $e', e, stackTrace);
          deviceName = 'Unknown Device';
        }
      }

      LogUtil.iTag(logTag, '设备名称: $deviceName');
      return deviceName;
    } catch (e, stackTrace) {
      // If device_info_plus fails, try hostname
      LogUtil.wTag(logTag, '获取设备信息失败，尝试使用主机名: $e', e, stackTrace);
      try {
        final hostname = Platform.localHostname;
        LogUtil.iTag(logTag, '设备名称(主机名): $hostname');
        return hostname;
      } catch (e2, stackTrace2) {
        LogUtil.eTag(logTag, '无法获取设备名称: $e2', e2, stackTrace2);
        return 'Unknown Device';
      }
    }
  }

  /// Build HTTP URL with IP and port
  /// If targetIP already contains port, use it; otherwise use default port
  static String buildHttpUrl(
    String targetIP,
    String endpoint, {
    int? targetPort,
  }) {
    final port = targetPort ?? AppConstants.defaultPort;
    final baseUrl = targetIP.contains(':')
        ? 'http://$targetIP'
        : 'http://$targetIP:$port';
    final url = '$baseUrl$endpoint';
    LogUtil.dTag(logTag, '构建URL: $url');
    return url;
  }
}
