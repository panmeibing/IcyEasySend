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

  /// Base64 Ed25519 public key, null on peers older than the identity release.
  ///
  /// Broadcasting it lets a discovered device be recognised as already paired
  /// without a round trip, and lets pairing start straight from the device
  /// list.
  final String? publicKey;

  /// Null on peers that predate [AppConstants.protocolVersion].
  final String? protocolVersion;

  const MulticastAnnouncement({
    required this.app,
    required this.deviceName,
    required this.version,
    required this.deviceId,
    required this.port,
    required this.announcement,
    this.publicKey,
    this.protocolVersion,
  });

  /// Build a payload describing this device.
  factory MulticastAnnouncement.forDevice({
    required String deviceName,
    required String deviceId,
    required int port,
    required bool announcement,
    String? publicKey,
  }) {
    return MulticastAnnouncement(
      app: AppConstants.projectNameTight,
      deviceName: deviceName,
      version: AppConstants.version,
      deviceId: deviceId,
      port: port,
      announcement: announcement,
      publicKey: publicKey,
      protocolVersion: AppConstants.protocolVersion,
    );
  }

  Map<String, dynamic> toJson() => {
    'app': app,
    'deviceName': deviceName,
    'version': version,
    'deviceId': deviceId,
    'port': port,
    'announcement': announcement,
    if (publicKey != null) 'publicKey': publicKey,
    if (protocolVersion != null) 'protocolVersion': protocolVersion,
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
        publicKey: json['publicKey'] as String?,
        protocolVersion: json['protocolVersion'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
