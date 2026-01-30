/// Equipment Information Model
///
/// Contains basic information about the device
class DeviceInfo {
  /// Device Name
  final String deviceName;

  /// IP address
  final String ipAddress;

  /// Platform（Android, iOS, Windows, macOS, Linux）
  final String platform;

  DeviceInfo({
    required this.deviceName,
    required this.ipAddress,
    required this.platform,
  });

  /// Convert objects to JSON format
  Map<String, dynamic> toJson() {
    return {
      'deviceName': deviceName,
      'ipAddress': ipAddress,
      'platform': platform,
    };
  }

  /// Create objects from JSON
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceName: json['deviceName'] as String,
      ipAddress: json['ipAddress'] as String,
      platform: json['platform'] as String,
    );
  }

  @override
  String toString() {
    return 'DeviceInfo(deviceName: $deviceName, ipAddress: $ipAddress, platform: $platform)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeviceInfo &&
        other.deviceName == deviceName &&
        other.ipAddress == ipAddress &&
        other.platform == platform;
  }

  @override
  int get hashCode {
    return deviceName.hashCode ^ ipAddress.hashCode ^ platform.hashCode;
  }
}
