import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:icy_easy_send/utils/constants.dart';

import '../models/clipboard_data_model.dart';
import '../utils/http_helper.dart';
import '../utils/log_util.dart';
import '../utils/operation_result.dart';

/// 增强的剪切板服务类
///
/// 支持文本和图片的剪切板操作
class EnhancedClipboardService {
  final String logTag = LogTags.clipboard;
  
  // Platform channel for image clipboard operations
  static const MethodChannel _channel = MethodChannel('com.icyhope.icy_easy_send/clipboard');

  /// 获取本地剪切板内容
  ///
  /// 返回剪切板中的内容（文本或图片），如果剪切板为空或出错则返回null
  Future<ClipboardDataModel?> getClipboardContent() async {
    try {
      LogUtil.dTag(logTag, '正在读取本地剪切板...');
      
      // 首先尝试读取文本
      final textData = await Clipboard.getData(Clipboard.kTextPlain);
      if (textData?.text != null && textData!.text!.isNotEmpty) {
        LogUtil.iTag(logTag, '成功读取文本剪切板，长度: ${textData.text!.length}');
        return ClipboardDataModel(
          type: ClipboardDataType.text,
          textContent: textData.text,
        );
      }
      
      // 尝试读取图片（通过 platform channel）
      try {
        final result = await _channel.invokeMethod<Map>('getImageFromClipboard');
        if (result != null) {
          final imageBytes = result['imageData'] as Uint8List?;
          final format = result['format'] as String? ?? 'png';
          
          if (imageBytes != null && imageBytes.isNotEmpty) {
            LogUtil.iTag(logTag, '成功读取图片剪切板，大小: ${imageBytes.length} bytes');
            return ClipboardDataModel(
              type: ClipboardDataType.image,
              imageData: imageBytes,
              imageFormat: format,
            );
          }
        }
      } catch (e) {
        // Platform channel not implemented, image clipboard not supported
        LogUtil.dTag(logTag, '图片剪切板不支持或未实现: $e');
      }
      
      LogUtil.wTag(logTag, '剪切板为空');
      return null;
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '读取剪切板失败: $e', e, stackTrace);
      return null;
    }
  }

  /// 设置本地剪切板内容
  ///
  /// 将指定的内容写入剪切板（文本或图片）
  Future<bool> setClipboardContent(ClipboardDataModel data) async {
    try {
      LogUtil.dTag(logTag, '正在写入剪切板，类型: ${data.typeDescription}');
      
      if (data.type == ClipboardDataType.text && data.textContent != null) {
        await Clipboard.setData(ClipboardData(text: data.textContent!));
        LogUtil.iTag(logTag, '成功写入文本剪切板');
        return true;
      } else if (data.type == ClipboardDataType.image && data.imageData != null) {
        // 尝试通过 platform channel 写入图片
        try {
          await _channel.invokeMethod('setImageToClipboard', {
            'imageData': data.imageData,
            'format': data.imageFormat ?? 'png',
          });
          LogUtil.iTag(logTag, '成功写入图片剪切板');
          return true;
        } catch (e) {
          LogUtil.wTag(logTag, '图片剪切板写入不支持: $e');
          return false;
        }
      }
      
      LogUtil.wTag(logTag, '无效的剪切板数据');
      return false;
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '写入剪切板失败: $e', e, stackTrace);
      return false;
    }
  }

  /// 请求目标设备的剪切板内容
  ///
  /// 向目标设备发送HTTP请求，请求获取其剪切板内容
  /// 目标设备会弹出确认对话框，用户同意后返回剪切板内容
  ///
  /// 参数:
  /// - [targetIP]: 目标设备的IP地址
  /// - [port]: 目标设备的端口号
  /// - [deviceName]: 本设备的名称（可选）
  ///
  /// 返回: [OperationResult<ClipboardDataModel>] 包含剪切板内容或错误信息
  Future<OperationResult<ClipboardDataModel>> requestClipboardFromDevice({
    required String targetIP,
    required int port,
    String? deviceName,
  }) async {
    try {
      LogUtil.iTag(logTag, '向 $targetIP:$port 请求剪切板内容...');

      final url = 'http://$targetIP:$port/clipboard-request';
      
      // 构建请求体
      final requestBody = jsonEncode({
        'requesterDeviceName': deviceName ?? '未知设备',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // 发送POST请求
      final result = await HttpHelper.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
        timeout: AppConstants.confirmTimeout,
      );

      if (!result.isSuccess) {
        LogUtil.eTag(logTag, '请求剪切板失败: ${result.errorMessage}');
        return OperationResult.failure(
          result.errorMessage ?? '请求失败',
        );
      }

      final response = result.data!;

      // 解析响应
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final accepted = responseData['accepted'] as bool? ?? false;
          
          if (accepted) {
            final clipboardDataJson = responseData['clipboardData'] as Map<String, dynamic>?;
            
            if (clipboardDataJson != null) {
              final clipboardData = ClipboardDataModel.fromJson(clipboardDataJson);
              
              LogUtil.iTag(
                logTag,
                '成功获取剪切板内容，类型: ${clipboardData.typeDescription}, 大小: ${clipboardData.sizeInMB.toStringAsFixed(2)} MB',
              );
              return OperationResult.success(data: clipboardData);
            } else {
              LogUtil.wTag(logTag, '目标设备剪切板为空');
              return OperationResult.failure('目标设备剪切板为空');
            }
          } else {
            final message = responseData['message'] as String? ?? '用户拒绝了请求';
            LogUtil.wTag(logTag, '请求被拒绝: $message');
            return OperationResult.failure(message);
          }
        } catch (e) {
          LogUtil.eTag(logTag, '解析响应失败: $e');
          return OperationResult.failure('解析响应失败: $e');
        }
      } else if (response.statusCode == 413) {
        // Content too large
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final message = responseData['message'] as String? ?? '剪切板内容过大';
          LogUtil.wTag(logTag, '剪切板内容过大: $message');
          return OperationResult.failure(message);
        } catch (e) {
          return OperationResult.failure('剪切板内容过大');
        }
      } else {
        LogUtil.eTag(logTag, '请求失败，状态码: ${response.statusCode}');
        return OperationResult.failure(
          '请求失败 (${response.statusCode})',
        );
      }
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '请求剪切板异常: $e', e, stackTrace);
      return OperationResult.failure('请求异常: $e');
    }
  }

  /// 同步目标设备的剪切板到本地
  ///
  /// 这是一个便捷方法，组合了请求和写入操作
  Future<OperationResult<ClipboardDataModel>> syncClipboardFromDevice({
    required String targetIP,
    required int port,
    String? deviceName,
  }) async {
    // 1. 请求目标设备的剪切板
    final requestResult = await requestClipboardFromDevice(
      targetIP: targetIP,
      port: port,
      deviceName: deviceName,
    );

    if (!requestResult.isSuccess) {
      return OperationResult.failure(
        requestResult.errorMessage ?? '请求失败',
      );
    }

    final clipboardData = requestResult.data!;

    // 2. 写入本地剪切板
    final writeSuccess = await setClipboardContent(clipboardData);

    if (writeSuccess) {
      LogUtil.iTag(logTag, '剪切板同步成功');
      return OperationResult.success(data: clipboardData);
    } else {
      return OperationResult.failure('写入本地剪切板失败');
    }
  }
}
