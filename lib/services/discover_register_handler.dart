import 'package:shelf/shelf.dart';

import '../models/discovered_device.dart';
import '../models/multicast_announcement.dart';
import '../utils/log_util.dart';
import '../utils/server_http_util.dart';
import 'multicast_discovery_service.dart';

/// Handles HTTP discovery registration (LocalSend-style TCP response).
///
/// When a peer receives a UDP announcement it POSTs its device info to the
/// scanner's `/discover/register` endpoint so discovery works even when UDP
/// responses are blocked by firewalls.
class DiscoverRegisterHandler {
  final String logTag = LogTags.network;

  Future<Response> handleRegister(Request request) async {
    final clientIp = ServerHttpUtil.remoteAddress(request);

    if (clientIp == null) {
      LogUtil.wTag(logTag, '发现注册请求缺少客户端 IP');
      return ServerHttpUtil.json({
        'status': 'error',
        'message': 'missing client ip',
      }, status: 400);
    }

    try {
      final announcement = MulticastAnnouncement.tryParse(
        await ServerHttpUtil.readBytes(request),
      );
      if (announcement == null) {
        return ServerHttpUtil.json({
          'status': 'error',
          'message': 'invalid payload',
        }, status: 400);
      }

      final device = DiscoveredDevice(
        ip: clientIp,
        port: announcement.port,
        deviceName: announcement.deviceName,
        deviceId: announcement.deviceId,
        publicKey: announcement.publicKey,
      );

      final accepted = MulticastDiscoveryService.instance
          .notifyDeviceFromRegister(device, announcement.deviceId);

      if (accepted) {
        LogUtil.iTag(
          logTag,
          '[DISCOVER/TCP] ${device.deviceName} (${device.displayAddress})',
        );
      }

      return ServerHttpUtil.json({'status': 'ok'});
    } on RequestBodyTooLargeException {
      return ServerHttpUtil.json({
        'status': 'error',
        'message': 'payload too large',
      }, status: 413);
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '发现注册处理失败: $e', e, stackTrace);
      return ServerHttpUtil.json({'status': 'error'}, status: 500);
    }
  }
}
