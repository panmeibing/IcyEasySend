import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import '../models/discovered_device.dart';
import '../models/multicast_announcement.dart';
import '../utils/log_util.dart';
import 'multicast_discovery_service.dart';

/// Handles HTTP discovery registration (LocalSend-style TCP response).
///
/// When a peer receives a UDP announcement it POSTs its device info to the
/// scanner's `/discover/register` endpoint so discovery works even when UDP
/// responses are blocked by firewalls.
class DiscoverRegisterHandler {
  final String logTag = LogTags.network;

  Future<Response> handleRegister(Request request) async {
    final connectionInfo = request.context['shelf.io.connection_info'];
    final remoteAddress = connectionInfo == null
        ? null
        : (connectionInfo as dynamic).remoteAddress as InternetAddress?;
    final clientIp = remoteAddress?.address;

    if (clientIp == null) {
      LogUtil.wTag(logTag, '发现注册请求缺少客户端 IP');
      return Response.badRequest(
        body: jsonEncode({'status': 'error', 'message': 'missing client ip'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    try {
      final body = await request.readAsString();
      final announcement = MulticastAnnouncement.tryParse(utf8.encode(body));
      if (announcement == null) {
        return Response.badRequest(
          body: jsonEncode({'status': 'error', 'message': 'invalid payload'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final device = DiscoveredDevice(
        ip: clientIp,
        port: announcement.port,
        deviceName: announcement.deviceName,
      );

      final accepted = MulticastDiscoveryService.instance
          .notifyDeviceFromRegister(device, announcement.deviceId);

      if (accepted) {
        LogUtil.iTag(
          logTag,
          '[DISCOVER/TCP] ${device.deviceName} (${device.displayAddress})',
        );
      }

      return Response.ok(
        jsonEncode({'status': 'ok'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '发现注册处理失败: $e', e, stackTrace);
      return Response.internalServerError(
        body: jsonEncode({'status': 'error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
