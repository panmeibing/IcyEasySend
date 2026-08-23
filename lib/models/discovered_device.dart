/// A device discovered on the local network running Icy Easy Send.
///
/// [deviceId] and [publicKey] are present when the peer speaks
/// `icy-relay-v1` (or later). Pre-identity builds omit them; those peers can
/// still be reached over the LAN but cannot be merged with a relay presence
/// entry, because there is nothing to merge on.
class DiscoveredDevice {
  final String ip;
  final int port;
  final String deviceName;
  final String? deviceId;
  final String? publicKey;

  const DiscoveredDevice({
    required this.ip,
    required this.port,
    required this.deviceName,
    this.deviceId,
    this.publicKey,
  });

  String get displayAddress => '$ip:$port';

  bool get hasIdentity => deviceId != null && deviceId!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! DiscoveredDevice) {
      return false;
    }
    // Identity beats address: the same phone may change IP between scans.
    if (hasIdentity && other.hasIdentity) {
      return deviceId == other.deviceId;
    }
    return ip == other.ip && port == other.port;
  }

  @override
  int get hashCode =>
      hasIdentity ? deviceId.hashCode : Object.hash(ip, port);

  @override
  String toString() =>
      'DiscoveredDevice($deviceName, $displayAddress'
      '${hasIdentity ? ', $deviceId' : ''})';
}
