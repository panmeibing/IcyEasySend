import '../services/identity_service.dart';

/// A peer whose Ed25519 public key this device has confirmed out of band.
///
/// Everything except [publicKey] is advisory: [deviceName] is refreshed
/// whenever the peer is seen again, and [lastSeenLan] is only a hint for
/// choosing a transport. The public key is the part that must never change,
/// because it is what a future connection is authenticated against.
class PairedDevice {
  /// Fingerprint of [publicKey]; see [IdentityService.deviceIdFromPublicKey].
  final String deviceId;

  /// Base64-encoded 32-byte Ed25519 public key.
  final String publicKey;

  final String deviceName;
  final String platform;
  final DateTime pairedAt;

  /// Accept incoming transfers from this peer without a confirmation dialog.
  ///
  /// Persisted but not yet honoured: skipping the dialog is only safe once
  /// transfer requests are signed, so nothing reads this until the sender can
  /// actually be authenticated.
  final bool autoAccept;

  /// Last known `ip` or `ip:port`, used to try the LAN before the relay.
  final String? lastSeenLan;

  const PairedDevice({
    required this.deviceId,
    required this.publicKey,
    required this.deviceName,
    required this.pairedAt,
    this.platform = '',
    this.autoAccept = false,
    this.lastSeenLan,
  });

  PairedDevice copyWith({
    String? deviceName,
    String? platform,
    DateTime? pairedAt,
    bool? autoAccept,
    String? lastSeenLan,
    bool clearLastSeenLan = false,
  }) {
    return PairedDevice(
      deviceId: deviceId,
      publicKey: publicKey,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      pairedAt: pairedAt ?? this.pairedAt,
      autoAccept: autoAccept ?? this.autoAccept,
      lastSeenLan:
          clearLastSeenLan ? null : (lastSeenLan ?? this.lastSeenLan),
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'publicKey': publicKey,
    'deviceName': deviceName,
    'platform': platform,
    'pairedAt': pairedAt.millisecondsSinceEpoch,
    'autoAccept': autoAccept,
    if (lastSeenLan != null) 'lastSeenLan': lastSeenLan,
  };

  /// Returns null for entries that are unusable, so a partially corrupted
  /// trust file degrades to "fewer paired devices" instead of a crash.
  static PairedDevice? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = raw.cast<String, dynamic>();
    final deviceId = json['deviceId'];
    final publicKey = json['publicKey'];
    if (deviceId is! String || deviceId.isEmpty) {
      return null;
    }
    if (publicKey is! String || IdentityService.decodePublicKey(publicKey) == null) {
      return null;
    }

    final pairedAt = json['pairedAt'];
    return PairedDevice(
      deviceId: deviceId,
      publicKey: publicKey,
      deviceName: json['deviceName'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      pairedAt: pairedAt is num
          ? DateTime.fromMillisecondsSinceEpoch(pairedAt.toInt())
          : DateTime.fromMillisecondsSinceEpoch(0),
      autoAccept: json['autoAccept'] as bool? ?? false,
      lastSeenLan: json['lastSeenLan'] as String?,
    );
  }

  /// Short, human-comparable form of the device id shown in the UI.
  String get shortDeviceId => deviceId.length <= 8
      ? deviceId
      : '${deviceId.substring(0, 4)}-${deviceId.substring(4, 8)}';

  @override
  bool operator ==(Object other) =>
      other is PairedDevice &&
      other.deviceId == deviceId &&
      other.publicKey == publicKey &&
      other.deviceName == deviceName &&
      other.platform == platform &&
      other.pairedAt == pairedAt &&
      other.autoAccept == autoAccept &&
      other.lastSeenLan == lastSeenLan;

  @override
  int get hashCode => Object.hash(
    deviceId,
    publicKey,
    deviceName,
    platform,
    pairedAt,
    autoAccept,
    lastSeenLan,
  );

  @override
  String toString() => 'PairedDevice($deviceId, $deviceName)';
}
