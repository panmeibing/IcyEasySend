import 'dart:convert';

import 'package:icy_easy_send/utils/log_util.dart';
import 'package:shelf/shelf.dart';

import '../utils/network_util.dart';

/// Handler for health check endpoint
///
/// Provides a RESTful endpoint to check if the device is online and ready
/// to receive files.
class HealthCheckHandler {
  final String logTag = LogTags.server;

  /// Handle GET /health requests
  ///
  /// Returns a JSON response with:
  /// - status: "ok" indicating the device is healthy
  /// - timestamp: current timestamp in milliseconds
  /// - deviceName: name of the device
  Future<Response> handleHealthCheck(Request request) async {
    LogUtil.dTag(LogTags.server, '收到健康检查请求: ${request.url}');

    try {
      final deviceName = await NetworkUtil.getDeviceName();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final response = {
        'status': 'ok',
        'timestamp': timestamp,
        'deviceName': deviceName,
      };

      LogUtil.dTag(logTag, '健康检查响应: 设备名=$deviceName');

      return Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '健康检查处理异常: $e', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'status': 'error', 'message': '服务器内部错误'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
