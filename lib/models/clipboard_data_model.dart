import 'dart:convert';
import 'dart:typed_data';

/// 剪切板数据类型
enum ClipboardDataType {
  text,
  image,
  unknown,
}

/// 剪切板数据模型
///
/// 用于在设备之间传输剪切板内容
class ClipboardDataModel {
  final ClipboardDataType type;
  final String? textContent;
  final Uint8List? imageData;
  final String? imageFormat; // png, jpeg, etc.

  ClipboardDataModel({
    required this.type,
    this.textContent,
    this.imageData,
    this.imageFormat,
  });

  /// 转换为JSON（用于HTTP传输）
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'textContent': textContent,
      'imageData': imageData != null ? base64Encode(imageData!) : null,
      'imageFormat': imageFormat,
    };
  }

  /// 从JSON创建
  factory ClipboardDataModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = ClipboardDataType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ClipboardDataType.unknown,
    );

    return ClipboardDataModel(
      type: type,
      textContent: json['textContent'] as String?,
      imageData: json['imageData'] != null
          ? base64Decode(json['imageData'] as String)
          : null,
      imageFormat: json['imageFormat'] as String?,
    );
  }

  /// 获取数据大小（字节）
  int get sizeInBytes {
    if (type == ClipboardDataType.text && textContent != null) {
      return textContent!.length;
    } else if (type == ClipboardDataType.image && imageData != null) {
      return imageData!.length;
    }
    return 0;
  }

  /// 获取数据大小（MB）
  double get sizeInMB {
    return sizeInBytes / (1024 * 1024);
  }

  /// 获取类型描述
  String get typeDescription {
    switch (type) {
      case ClipboardDataType.text:
        return '文本';
      case ClipboardDataType.image:
        return '图片';
      case ClipboardDataType.unknown:
        return '未知';
    }
  }

  @override
  String toString() {
    return 'ClipboardDataModel(type: $type, size: ${sizeInMB.toStringAsFixed(2)} MB)';
  }
}
