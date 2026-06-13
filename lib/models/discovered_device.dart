/// A device discovered on the local network running Icy Easy Send.
class DiscoveredDevice {
  final String ip;
  final int port;
  final String deviceName;

  const DiscoveredDevice({
    required this.ip,
    required this.port,
    required this.deviceName,
  });

  String get displayAddress => '$ip:$port';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DiscoveredDevice && other.ip == ip && other.port == port;
  }

  @override
  int get hashCode => Object.hash(ip, port);
}
