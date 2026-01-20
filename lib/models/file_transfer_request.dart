/// 文件传输请求模型
///
/// 包含文件传输请求的所有必要信息
class FileTransferRequest {
  /// 文件名
  final String fileName;

  /// 文件大小（字节）
  final int fileSize;

  /// 发送者 IP 地址
  final String senderIP;

  /// 发送者设备名
  final String? senderDeviceName;

  /// 请求时间戳
  final DateTime timestamp;

  FileTransferRequest({
    required this.fileName,
    required this.fileSize,
    required this.senderIP,
    this.senderDeviceName,
    required this.timestamp,
  });

  /// 将对象转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSize': fileSize,
      'senderIP': senderIP,
      if (senderDeviceName != null) 'senderDeviceName': senderDeviceName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// 从 JSON 创建对象
  factory FileTransferRequest.fromJson(Map<String, dynamic> json) {
    return FileTransferRequest(
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      senderIP: json['senderIP'] as String,
      senderDeviceName: json['senderDeviceName'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'FileTransferRequest(fileName: $fileName, fileSize: $fileSize, senderIP: $senderIP, senderDeviceName: $senderDeviceName, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FileTransferRequest &&
        other.fileName == fileName &&
        other.fileSize == fileSize &&
        other.senderIP == senderIP &&
        other.senderDeviceName == senderDeviceName &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return fileName.hashCode ^
        fileSize.hashCode ^
        senderIP.hashCode ^
        senderDeviceName.hashCode ^
        timestamp.hashCode;
  }
}
