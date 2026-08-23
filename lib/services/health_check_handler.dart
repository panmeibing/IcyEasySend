import 'dart:convert';

import 'package:icy_easy_send/utils/log_util.dart';
import 'package:shelf/shelf.dart';

import '../utils/constants.dart';
import '../utils/network_util.dart';
import 'identity_service.dart';

/// Handler for health check endpoint
///
/// Provides a RESTful endpoint to check if the device is online and ready
/// to receive files.
class HealthCheckHandler {
  final String logTag = LogTags.server;
  int? Function()? serverPortGetter;
  final IdentityService _identityService;

  HealthCheckHandler({this.serverPortGetter, IdentityService? identityService})
    : _identityService = identityService ?? IdentityService.instance;

  /// Handle GET /health requests
  ///
  /// Returns a JSON response with:
  /// - status: "ok" indicating the device is healthy
  /// - timestamp: current timestamp in milliseconds
  /// - deviceName: name of the device
  /// - deviceId / publicKey / protocolVersion: this device's Ed25519 identity,
  ///   which a peer needs before it can start pairing
  ///
  /// Publishing the public key here is intentional: it is public by
  /// definition, and letting the initiator fetch it up front means both
  /// devices can display the same pairing code at the same time.
  Future<Response> handleHealthCheck(Request request) async {
    LogUtil.dTag(LogTags.server, '收到健康检查请求: ${request.url}');

    try {
      final deviceName = await NetworkUtil.getDeviceName();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final port = _resolvePort(request);

      final response = {
        'status': 'ok',
        'timestamp': timestamp,
        'deviceName': deviceName,
        'app': AppConstants.projectNameTight,
        'version': AppConstants.version,
        'port': port,
        'protocolVersion': AppConstants.protocolVersion,
      };

      // A failure here must not take the endpoint down: legacy transfers work
      // fine without an identity, so degrade to the old payload instead.
      try {
        response['deviceId'] = await _identityService.getDeviceId();
        response['publicKey'] = await _identityService.getPublicKeyBase64();
      } catch (e) {
        LogUtil.wTag(logTag, '健康检查未能附带设备身份: $e');
      }

      LogUtil.dTag(logTag, '健康检查响应: 设备名=$deviceName, 端口=$port');

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

  int _resolvePort(Request request) {
    if (request.url.hasPort && request.url.port > 0) {
      return request.url.port;
    }

    final host = request.headers['host'];
    if (host != null) {
      final hostParts = host.split(':');
      if (hostParts.length == 2) {
        final parsedPort = int.tryParse(hostParts[1]);
        if (parsedPort != null) {
          return parsedPort;
        }
      }
    }

    return serverPortGetter?.call() ?? AppConstants.defaultPort;
  }
}
