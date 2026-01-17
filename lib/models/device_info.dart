/// 设备信息模型
/// 
/// 包含设备的基本信息
class DeviceInfo {
  /// 设备名称
  final String deviceName;
  
  /// IP 地址
  final String ipAddress;
  
  /// 平台（Android, iOS, Windows, macOS, Linux）
  final String platform;

  DeviceInfo({
    required this.deviceName,
    required this.ipAddress,
    required this.platform,
  });

  /// 将对象转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'deviceName': deviceName,
      'ipAddress': ipAddress,
      'platform': platform,
    };
  }

  /// 从 JSON 创建对象
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
    return deviceName.hashCode ^
        ipAddress.hashCode ^
        platform.hashCode;
  }
}
