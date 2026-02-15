import 'dart:convert';
import 'dart:typed_data';

import 'package:icy_easy_send/utils/constants.dart';
import 'package:path/path.dart' as path;

/// 剪切板数据类型
enum ClipboardDataType { text, file, unknown }

/// 剪切板数据模型
///
/// 用于在设备之间传输剪切板内容
class ClipboardDataModel {
  final ClipboardDataType type;
  final String? textContent;
  final Uint8List? fileData;
  final String? fileName;
  final String? mimeType; // 文件的 MIME 类型

  ClipboardDataModel({
    required this.type,
    this.textContent,
    this.fileData,
    this.fileName,
    this.mimeType,
  });

  /// 转换为JSON（用于HTTP传输）
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'textContent': textContent,
      'fileData': fileData != null ? base64Encode(fileData!) : null,
      'fileName': fileName,
      'mimeType': mimeType,
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
      fileData: json['fileData'] != null
          ? base64Decode(json['fileData'] as String)
          : null,
      fileName: json['fileName'] as String?,
      mimeType: json['mimeType'] as String?,
    );
  }

  /// 获取数据大小（字节）
  int get sizeInBytes {
    if (type == ClipboardDataType.text && textContent != null) {
      return textContent!.length;
    } else if (type == ClipboardDataType.file && fileData != null) {
      return fileData!.length;
    }
    return 0;
  }

  /// 获取数据大小（MB）
  double get sizeInMB {
    return sizeInBytes / AppConstants.bytesPerMB;
  }

  /// 获取类型描述
  String get typeDescription {
    switch (type) {
      case ClipboardDataType.text:
        return '文本';
      case ClipboardDataType.file:
        return fileName != null ? '文件: $fileName' : '文件';
      case ClipboardDataType.unknown:
        return '未知';
    }
  }

  /// 判断是否为图片文件
  bool get isImage {
    if (type != ClipboardDataType.file) return false;
    if (mimeType != null && mimeType!.startsWith('image/')) return true;
    if (fileName != null) {
      final ext = path.extension(fileName!).toLowerCase();
      final extWithoutDot = ext.isEmpty ? '' : ext.substring(1);
      return [
        'png',
        'jpg',
        'jpeg',
        'gif',
        'bmp',
        'webp',
        'svg',
      ].contains(extWithoutDot);
    }
    return false;
  }

  @override
  String toString() {
    return 'ClipboardDataModel(type: $type, size: ${sizeInMB.toStringAsFixed(2)} MB)';
  }
}
