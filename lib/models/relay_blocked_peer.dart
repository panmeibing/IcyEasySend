/// A peer this device has explicitly blocked from relay pairing.
class RelayBlockedPeer {
  final String deviceId;
  final String deviceName;
  final DateTime blockedAt;

  const RelayBlockedPeer({
    required this.deviceId,
    required this.deviceName,
    required this.blockedAt,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'blockedAt': blockedAt.toIso8601String(),
  };

  static RelayBlockedPeer? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final deviceId = map['deviceId'];
    if (deviceId is! String || deviceId.isEmpty) return null;
    final name = map['deviceName'];
    final at = map['blockedAt'];
    return RelayBlockedPeer(
      deviceId: deviceId,
      deviceName: name is String ? name : '',
      blockedAt: at is String
          ? (DateTime.tryParse(at) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
