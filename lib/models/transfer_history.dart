/// 传输历史记录模型
/// 
/// 记录文件传输的历史信息
class TransferHistory {
  /// 文件名
  final String fileName;
  
  /// 文件大小（字节）
  final int fileSize;
  
  /// 对方设备 IP 地址
  final String peerIP;
  
  /// 传输时间戳
  final DateTime timestamp;
  
  /// 是否为接收（true: 接收, false: 发送）
  final bool isReceived;
  
  /// 传输是否成功
  final bool success;
  
  /// 文件保存路径（仅接收的文件有此字段）
  final String? savedPath;

  TransferHistory({
    required this.fileName,
    required this.fileSize,
    required this.peerIP,
    required this.timestamp,
    required this.isReceived,
    required this.success,
    this.savedPath,
  });

  /// 将对象转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSize': fileSize,
      'peerIP': peerIP,
      'timestamp': timestamp.toIso8601String(),
      'isReceived': isReceived,
      'success': success,
      if (savedPath != null) 'savedPath': savedPath,
    };
  }

  /// 从 JSON 创建对象
  factory TransferHistory.fromJson(Map<String, dynamic> json) {
    return TransferHistory(
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      peerIP: json['peerIP'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isReceived: json['isReceived'] as bool,
      success: json['success'] as bool,
      savedPath: json['savedPath'] as String?,
    );
  }

  @override
  String toString() {
    return 'TransferHistory(fileName: $fileName, fileSize: $fileSize, peerIP: $peerIP, timestamp: $timestamp, isReceived: $isReceived, success: $success, savedPath: $savedPath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TransferHistory &&
        other.fileName == fileName &&
        other.fileSize == fileSize &&
        other.peerIP == peerIP &&
        other.timestamp == timestamp &&
        other.isReceived == isReceived &&
        other.success == success &&
        other.savedPath == savedPath;
  }

  @override
  int get hashCode {
    return fileName.hashCode ^
        fileSize.hashCode ^
        peerIP.hashCode ^
        timestamp.hashCode ^
        isReceived.hashCode ^
        success.hashCode ^
        savedPath.hashCode;
  }
}
