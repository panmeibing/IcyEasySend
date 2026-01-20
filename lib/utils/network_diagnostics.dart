import 'dart:io';
import 'package:http/http.dart' as http;

/// Network diagnostics utility to help troubleshoot connection issues
class NetworkDiagnostics {
  /// Perform comprehensive network diagnostics
  /// 
  /// Returns a detailed report of network status
  static Future<DiagnosticsReport> runDiagnostics({
    String? targetIP,
    int? targetPort,
  }) async {
    final report = DiagnosticsReport();
    
    // 1. Check local network interfaces
    report.localInterfaces = await _checkLocalInterfaces();
    
    // 2. Check if we can reach the target (if provided)
    if (targetIP != null && targetPort != null) {
      report.targetReachable = await _checkTargetReachability(targetIP, targetPort);
      report.healthCheckResult = await _testHealthEndpoint(targetIP, targetPort);
    }
    
    // 3. Check internet connectivity
    report.hasInternetConnection = await _checkInternetConnection();
    
    return report;
  }
  
  /// Check local network interfaces
  static Future<List<NetworkInterfaceInfo>> _checkLocalInterfaces() async {
    final List<NetworkInterfaceInfo> interfaces = [];
    
    try {
      final networkInterfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      for (var interface in networkInterfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            interfaces.add(NetworkInterfaceInfo(
              name: interface.name,
              address: addr.address,
              isPrivateNetwork: _isPrivateNetwork(addr.address),
            ));
          }
        }
      }
    } catch (e) {
      print('[Diagnostics] 获取网络接口失败: $e');
    }
    
    return interfaces;
  }
  
  /// Check if target is reachable via socket connection
  static Future<bool> _checkTargetReachability(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 3),
      );
      await socket.close();
      return true;
    } catch (e) {
      print('[Diagnostics] 目标不可达: $e');
      return false;
    }
  }
  
  /// Test health endpoint
  static Future<HealthCheckTestResult> _testHealthEndpoint(String ip, int port) async {
    try {
      final url = 'http://$ip:$port/health';
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 5));
      
      return HealthCheckTestResult(
        success: response.statusCode == 200,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    } catch (e) {
      return HealthCheckTestResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Check internet connectivity
  static Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('www.google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if an IP address is in a private network range
  static bool _isPrivateNetwork(String ip) {
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
    } catch (e) {
      return false;
    }
  }
}

/// Diagnostics report
class DiagnosticsReport {
  List<NetworkInterfaceInfo> localInterfaces = [];
  bool? targetReachable;
  HealthCheckTestResult? healthCheckResult;
  bool hasInternetConnection = false;
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('========== 网络诊断报告 ==========');
    buffer.writeln();
    
    buffer.writeln('本地网络接口:');
    if (localInterfaces.isEmpty) {
      buffer.writeln('  ❌ 未找到有效的网络接口');
    } else {
      for (var interface in localInterfaces) {
        buffer.writeln('  ✅ ${interface.name}: ${interface.address}');
        if (interface.isPrivateNetwork) {
          buffer.writeln('     (私有网络地址)');
        }
      }
    }
    buffer.writeln();
    
    if (targetReachable != null) {
      buffer.writeln('目标设备可达性:');
      buffer.writeln(targetReachable! ? '  ✅ 可以连接到目标设备' : '  ❌ 无法连接到目标设备');
      buffer.writeln();
    }
    
    if (healthCheckResult != null) {
      buffer.writeln('健康检查测试:');
      if (healthCheckResult!.success) {
        buffer.writeln('  ✅ 健康检查成功');
        buffer.writeln('  状态码: ${healthCheckResult!.statusCode}');
        buffer.writeln('  响应: ${healthCheckResult!.responseBody}');
      } else {
        buffer.writeln('  ❌ 健康检查失败');
        if (healthCheckResult!.statusCode != null) {
          buffer.writeln('  状态码: ${healthCheckResult!.statusCode}');
        }
        if (healthCheckResult!.error != null) {
          buffer.writeln('  错误: ${healthCheckResult!.error}');
        }
      }
      buffer.writeln();
    }
    
    buffer.writeln('互联网连接:');
    buffer.writeln(hasInternetConnection ? '  ✅ 有互联网连接' : '  ❌ 无互联网连接');
    buffer.writeln();
    
    buffer.writeln('==================================');
    
    return buffer.toString();
  }
}

/// Network interface information
class NetworkInterfaceInfo {
  final String name;
  final String address;
  final bool isPrivateNetwork;
  
  NetworkInterfaceInfo({
    required this.name,
    required this.address,
    required this.isPrivateNetwork,
  });
}

/// Health check test result
class HealthCheckTestResult {
  final bool success;
  final int? statusCode;
  final String? responseBody;
  final String? error;
  
  HealthCheckTestResult({
    required this.success,
    this.statusCode,
    this.responseBody,
    this.error,
  });
}
