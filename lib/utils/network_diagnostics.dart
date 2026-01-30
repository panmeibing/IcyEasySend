import 'dart:io';

import 'package:icy_easy_send/utils/constants.dart';

import 'http_helper.dart';
import 'log_util.dart';
import 'network_util.dart';

/// Network diagnostics utility to help troubleshoot connection issues
class NetworkDiagnostics {
  static final String logTag = LogTags.network;

  /// Perform comprehensive network diagnostics
  ///
  /// Returns a detailed report of network status
  static Future<DiagnosticsReport> runDiagnostics({
    String? targetIP,
    int? targetPort,
  }) async {
    LogUtil.iTag(logTag, '开始网络诊断: 目标=$targetIP:$targetPort');

    final report = DiagnosticsReport();

    // 1. Check local network interfaces
    report.localInterfaces = await _checkLocalInterfaces();
    LogUtil.dTag(logTag, '本地网络接口: ${report.localInterfaces.length}个');

    // 2. Check if we can reach the target (if provided)
    if (targetIP != null && targetPort != null) {
      report.targetReachable = await _checkTargetReachability(
        targetIP,
        targetPort,
      );
      LogUtil.iTag(
        logTag,
        '目标可达性: ${report.targetReachable == true ? "可达" : "不可达"}',
      );

      report.healthCheckResult = await _testHealthEndpoint(
        targetIP,
        targetPort,
      );
      LogUtil.iTag(
        logTag,
        '健康检查: ${report.healthCheckResult?.success == true ? "成功" : "失败"}',
      );
    }

    // 3. Check internet connectivity
    report.hasInternetConnection = await _checkInternetConnection();
    LogUtil.dTag(logTag, '互联网连接: ${report.hasInternetConnection ? "有" : "无"}');

    LogUtil.iTag(logTag, '网络诊断完成');
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
            interfaces.add(
              NetworkInterfaceInfo(
                name: interface.name,
                address: addr.address,
                isPrivateNetwork: NetworkUtil.isPrivateNetwork(addr.address),
              ),
            );
            LogUtil.dTag(logTag, '发现网络接口: ${interface.name} - ${addr.address}');
          }
        }
      }

      if (interfaces.isEmpty) {
        LogUtil.wTag(logTag, '未找到有效的网络接口');
      }
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '获取网络接口失败: $e', e, stackTrace);
    }

    return interfaces;
  }

  /// Check if target is reachable via socket connection
  static Future<bool> _checkTargetReachability(String ip, int port) async {
    LogUtil.dTag(logTag, '检查目标可达性: $ip:$port');

    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 3),
      );
      await socket.close();
      LogUtil.dTag(logTag, '目标可达: $ip:$port');
      return true;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '目标不可达: $ip:$port, 错误=$e', e, stackTrace);
      return false;
    }
  }

  /// Test health endpoint
  static Future<HealthCheckTestResult> _testHealthEndpoint(
    String ip,
    int port,
  ) async {
    final url = NetworkUtil.buildHttpUrl(ip, '/health', targetPort: port);
    LogUtil.dTag(logTag, '测试健康检查端点: $url');

    // Use HttpHelper for GET request
    final result = await HttpHelper.get(
      url,
      timeout: const Duration(seconds: 5),
    );

    if (!result.isSuccess) {
      LogUtil.wTag(logTag, '健康检查失败: ${result.errorMessage}');
      return HealthCheckTestResult(success: false, error: result.errorMessage);
    }

    final response = result.data!;
    final success = HttpHelper.isSuccessResponse(response);

    if (success) {
      LogUtil.dTag(logTag, '健康检查成功: 状态码=${response.statusCode}');
    } else {
      LogUtil.wTag(logTag, '健康检查返回错误状态码: ${response.statusCode}');
    }

    return HealthCheckTestResult(
      success: success,
      statusCode: response.statusCode,
      responseBody: response.body,
    );
  }

  /// Check internet connectivity
  static Future<bool> _checkInternetConnection() async {
    LogUtil.dTag(logTag, '检查互联网连接');

    try {
      final result = await InternetAddress.lookup('www.baidu.com');
      final hasConnection =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      LogUtil.dTag(logTag, '互联网连接: ${hasConnection ? "有" : "无"}');
      return hasConnection;
    } catch (e, stackTrace) {
      LogUtil.dTag(logTag, '互联网连接检查失败: $e', e, stackTrace);
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
    String separator = AppConstants.diagInfoSeparator;
    final buffer = StringBuffer();
    buffer.writeln('$separator 网络诊断报告 $separator');
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

    buffer.writeln(separator * 3);

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
