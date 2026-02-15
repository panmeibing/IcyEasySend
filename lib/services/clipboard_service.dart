import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:icy_easy_send/utils/constants.dart';

import '../utils/http_helper.dart';
import '../utils/log_util.dart';
import '../utils/operation_result.dart';

/// 剪切板服务类
///
/// 提供剪切板的读取、写入和同步功能
class ClipboardService {
  final String logTag = LogTags.clipboard;

  /// 获取本地剪切板内容
  ///
  /// 返回剪切板中的文本内容，如果剪切板为空或出错则返回null
  Future<String?> getClipboardContent() async {
    try {
      LogUtil.dTag(logTag, '正在读取本地剪切板...');
      
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final content = clipboardData?.text;
      
      if (content != null && content.isNotEmpty) {
        LogUtil.iTag(logTag, '成功读取剪切板内容，长度: ${content.length}');
        return content;
      } else {
        LogUtil.wTag(logTag, '剪切板为空');
        return null;
      }
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '读取剪切板失败: $e', e, stackTrace);
      return null;
    }
  }

  /// 设置本地剪切板内容
  ///
  /// 将指定的文本内容写入剪切板
  Future<bool> setClipboardContent(String content) async {
    try {
      LogUtil.dTag(logTag, '正在写入剪切板，内容长度: ${content.length}');
      
      await Clipboard.setData(ClipboardData(text: content));
      
      LogUtil.iTag(logTag, '成功写入剪切板');
      return true;
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
  /// 返回: [OperationResult<String>] 包含剪切板内容或错误信息
  Future<OperationResult<String>> requestClipboardFromDevice({
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
            final clipboardContent = responseData['content'] as String?;
            
            if (clipboardContent != null && clipboardContent.isNotEmpty) {
              LogUtil.iTag(
                logTag,
                '成功获取剪切板内容，长度: ${clipboardContent.length}',
              );
              return OperationResult.success(data: clipboardContent);
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
          return OperationResult.failure('解析响应失败');
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
  Future<OperationResult<void>> syncClipboardFromDevice({
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

    final clipboardContent = requestResult.data!;

    // 2. 写入本地剪切板
    final writeSuccess = await setClipboardContent(clipboardContent);

    if (writeSuccess) {
      LogUtil.iTag(logTag, '剪切板同步成功');
      return OperationResult.success(data: null);
    } else {
      return OperationResult.failure('写入本地剪切板失败');
    }
  }
}
