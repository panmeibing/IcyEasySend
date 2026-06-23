import 'dart:convert';

import '../utils/constants.dart';

/// UDP multicast payload for LAN device discovery.
class MulticastAnnouncement {
  final String app;
  final String deviceName;
  final String version;
  final String deviceId;
  final int port;
  final bool announcement;

  const MulticastAnnouncement({
    required this.app,
    required this.deviceName,
    required this.version,
    required this.deviceId,
    required this.port,
    required this.announcement,
  });

  /// Build a payload describing this device.
  factory MulticastAnnouncement.forDevice({
    required String deviceName,
    required String deviceId,
    required int port,
    required bool announcement,
  }) {
    return MulticastAnnouncement(
      app: AppConstants.projectNameTight,
      deviceName: deviceName,
      version: AppConstants.version,
      deviceId: deviceId,
      port: port,
      announcement: announcement,
    );
  }

  Map<String, dynamic> toJson() => {
    'app': app,
    'deviceName': deviceName,
    'version': version,
    'deviceId': deviceId,
    'port': port,
    'announcement': announcement,
  };

  List<int> toBytes() => utf8.encode(jsonEncode(toJson()));

  static MulticastAnnouncement? tryParse(List<int> data) {
    try {
      final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      final app = json['app'] as String?;
      if (app != null && app != AppConstants.projectNameTight) {
        return null;
      }

      final deviceId = json['deviceId'] as String?;
      final deviceName = json['deviceName'] as String?;
      final port = json['port'];
      if (deviceId == null || deviceName == null || port is! num) {
        return null;
      }

      return MulticastAnnouncement(
        app: app ?? AppConstants.projectNameTight,
        deviceName: deviceName,
        version: json['version'] as String? ?? AppConstants.version,
        deviceId: deviceId,
        port: port.toInt(),
        announcement: json['announcement'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}
