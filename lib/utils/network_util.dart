import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
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

      // Store addresses with their interface info for better selection
      List<_NetworkAddressInfo> privateAddresses = [];
      List<_NetworkAddressInfo> otherAddresses = [];

      // Categorize addresses
      for (var interface in interfaces) {
        LogUtil.dTag(logTag, '检查接口: ${interface.name}');
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;
            final interfaceName = interface.name.toLowerCase();

            // Check if it's a private network address
            if (isPrivateNetwork(ip)) {
              LogUtil.dTag(logTag, '发现私有网络地址: $ip (${interface.name})');
              privateAddresses.add(
                _NetworkAddressInfo(ip: ip, interfaceName: interfaceName),
              );
            } else {
              LogUtil.dTag(logTag, '发现其他地址: $ip (${interface.name})');
              otherAddresses.add(
                _NetworkAddressInfo(ip: ip, interfaceName: interfaceName),
              );
            }
          }
        }
      }

      // Prefer private network addresses (typical LAN)
      if (privateAddresses.isNotEmpty) {
        // Sort by priority: physical adapters > virtual adapters, and 192.168 > 172 > 10
        privateAddresses.sort((a, b) {
          // 1. Priority: Physical network card>Virtual network card
          final aIsVirtual = _isVirtualInterface(a.interfaceName);
          final bIsVirtual = _isVirtualInterface(b.interfaceName);
          if (aIsVirtual != bIsVirtual) {
            return aIsVirtual ? 1 : -1;
          }
          // 2. Priority：192.168 > 172 > 10
          final aPriority = _getIPPriority(a.ip);
          final bPriority = _getIPPriority(b.ip);
          return aPriority.compareTo(bPriority);
        });

        final selectedIP = privateAddresses.first.ip;
        LogUtil.iTag(
          logTag,
          '本地IP地址: $selectedIP (${privateAddresses.first.interfaceName})',
        );
        return selectedIP;
      }

      // Use other addresses if no private network found
      if (otherAddresses.isNotEmpty) {
        final selectedIP = otherAddresses.first.ip;
        LogUtil.iTag(
          logTag,
          '本地IP地址: $selectedIP (${otherAddresses.first.interfaceName})',
        );
        return selectedIP;
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

  /// Check if a network interface is likely a virtual adapter
  ///
  /// Virtual adapters include VPN, virtual machines, Docker, etc.
  static bool _isVirtualInterface(String interfaceName) {
    final name = interfaceName.toLowerCase();

    // Common virtual interface patterns
    final virtualPatterns = [
      'vmware',
      'virtualbox',
      'vbox',
      'vethernet',
      'veth',
      'hyper-v',
      'docker',
      'vnic',
      'tap',
      'tun',
      'vpn',
      'virtual',
      'loopback',
      'tunnel',
      'bridge',
      'vmbr',
      'meta',
      'wintun',
      'clash',
      'sing-box',
      'tailscale',
      'zerotier',
      'virbr',
      'br-',
      'vmnet',
      'vboxnet',
      'utun',
      'lo',
      'dummy',
    ];

    return virtualPatterns.any((pattern) => name.contains(pattern));
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

  static int _getIPPriority(String ip) {
    if (ip.startsWith('192.168.')) return 1;
    if (ip.startsWith('172.')) return 2;
    if (ip.startsWith('10.')) return 3;
    return 4; // other
  }

  /// Check if the device is connected to WiFi
  ///
  /// Returns true if connected to WiFi, false otherwise
  /// This is used to detect hotspot scenarios where the device may not be connected to WiFi
  static Future<bool> isConnectedToWiFi() async {
    try {
      LogUtil.dTag(logTag, '检查WiFi连接状态...');

      final connectivity = Connectivity();
      final connectivityResults = await connectivity.checkConnectivity();

      // Check if any of the connectivity results is WiFi
      final isWiFi = connectivityResults.contains(ConnectivityResult.wifi);

      LogUtil.iTag(logTag, 'WiFi连接状态: $isWiFi, 连接类型: $connectivityResults');
      return isWiFi;
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '检查WiFi连接状态失败: $e', e, stackTrace);
      // If we can't determine, assume connected to be safe
      return true;
    }
  }

  /// Check if a network interface is likely a cellular/mobile data adapter.
  static bool isCellularInterface(String interfaceName) {
    final name = interfaceName.toLowerCase();
    const cellularPatterns = [
      'rmnet',
      'pdp_ip',
      'ccmni',
      'wwan',
      'clat',
      'radio',
    ];
    return cellularPatterns.any((pattern) => name.contains(pattern));
  }

  /// Check if a network interface is suitable for LAN device discovery.
  static bool isLanDiscoveryInterface(String interfaceName) {
    if (isCellularInterface(interfaceName)) {
      return false;
    }
    if (_isVirtualInterface(interfaceName)) {
      return false;
    }
    return true;
  }

  /// Get all private IPv4 addresses assigned to this device.
  static Future<Set<String>> getLocalPrivateIPs() async {
    final ips = <String>{};

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback &&
              addr.type == InternetAddressType.IPv4 &&
              isPrivateNetwork(addr.address)) {
            ips.add(addr.address);
          }
        }
      }
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '获取本机私有 IP 失败: $e', e, stackTrace);
    }

    return ips;
  }

  /// Build the /24 subnet prefix from an IPv4 address.
  static String? getSubnetPrefix(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) {
      return null;
    }
    return '${parts[0]}.${parts[1]}.${parts[2]}.';
  }

  /// Broadcast address for a /24 private IPv4 subnet (e.g. 10.92.31.255).
  static String? getSubnetBroadcast(String ip) {
    final prefix = getSubnetPrefix(ip);
    if (prefix == null) {
      return null;
    }
    return '${prefix}255';
  }

  /// Returns the first private IPv4 address on [interface], if any.
  static String? getPrimaryPrivateIpv4(NetworkInterface interface) {
    for (final addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 &&
          !addr.isLoopback &&
          isPrivateNetwork(addr.address)) {
        return addr.address;
      }
    }
    return null;
  }

  /// Returns LAN-capable IPv4 network interfaces.
  static Future<List<NetworkInterface>> getLanNetworkInterfaces() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    return interfaces
        .where((interface) => isLanDiscoveryInterface(interface.name))
        .toList();
  }

  /// Collect unique scan targets from LAN-capable private IPv4 interfaces.
  ///
  /// Cellular interfaces (e.g. Android rmnet) are excluded because they are
  /// not useful for LAN discovery and would match this device's own server.
  static Future<List<String>> getSubnetIPsForScan({
    Set<String>? excludeIps,
  }) async {
    final localIps = excludeIps ?? await getLocalPrivateIPs();
    final prefixes = <String>{};

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        if (!isLanDiscoveryInterface(interface.name)) {
          LogUtil.dTag(logTag, '跳过非局域网扫描接口: ${interface.name}');
          continue;
        }

        for (final addr in interface.addresses) {
          if (!addr.isLoopback &&
              addr.type == InternetAddressType.IPv4 &&
              isPrivateNetwork(addr.address)) {
            final prefix = getSubnetPrefix(addr.address);
            if (prefix != null) {
              prefixes.add(prefix);
              LogUtil.dTag(
                logTag,
                '加入扫描子网: $prefix* (${interface.name}: ${addr.address})',
              );
            }
          }
        }
      }
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '获取扫描子网失败: $e', e, stackTrace);
    }

    if (prefixes.isEmpty) {
      LogUtil.wTag(logTag, '未找到可用于局域网扫描的网络接口');
      return [];
    }

    final ips = <String>{};
    for (final prefix in prefixes) {
      for (var host = 1; host <= 254; host++) {
        final ip = '$prefix$host';
        if (!localIps.contains(ip)) {
          ips.add(ip);
        }
      }
    }

    final sortedIps = ips.toList()..sort(_compareIpv4);
    return sortedIps;
  }

  /// Check if the IP address starts with 10.x.x.x
  ///
  /// This is commonly used for hotspot networks
  static bool isHotspotIP(String ip) {
    return ip.startsWith('10.');
  }

  static int _compareIpv4(String a, String b) {
    final aParts = a.split('.').map(int.parse).toList();
    final bParts = b.split('.').map(int.parse).toList();
    for (var i = 0; i < 4; i++) {
      final diff = aParts[i].compareTo(bParts[i]);
      if (diff != 0) {
        return diff;
      }
    }
    return 0;
  }
}

/// Helper class to store network address information
class _NetworkAddressInfo {
  final String ip;
  final String interfaceName;

  _NetworkAddressInfo({required this.ip, required this.interfaceName});
}
