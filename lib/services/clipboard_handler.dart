import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:icy_easy_send/utils/constants.dart';
import 'package:shelf/shelf.dart';

import '../models/clipboard_data_model.dart';
import '../services/enhanced_clipboard_service.dart';
import '../services/preferences_service.dart';
import '../utils/log_util.dart';

/// 剪切板请求处理器
///
/// 处理来自其他设备的剪切板请求
class ClipboardHandler {
  final BuildContext? Function()? contextGetter;
  final EnhancedClipboardService _clipboardService;
  final PreferencesService _preferencesService;
  final String logTag = LogTags.clipboard;

  ClipboardHandler({
    this.contextGetter,
    EnhancedClipboardService? clipboardService,
    PreferencesService? preferencesService,
  }) : _clipboardService = clipboardService ?? EnhancedClipboardService(),
       _preferencesService = preferencesService ?? PreferencesService();

  /// 处理 POST /clipboard-request 请求
  ///
  /// 当其他设备请求本设备的剪切板内容时，会弹出确认对话框
  /// 用户同意后返回剪切板内容
  ///
  /// 请求体格式:
  /// {
  ///   "requesterDeviceName": "设备名称",
  ///   "timestamp": "2024-01-01T00:00:00.000Z"
  /// }
  ///
  /// 响应格式:
  /// {
  ///   "accepted": true/false,
  ///   "content": "剪切板内容" (仅当accepted为true时),
  ///   "message": "消息"
  /// }
  Future<Response> handleClipboardRequest(Request request) async {
    LogUtil.iTag(logTag, '收到剪切板请求: /clipboard-request');

    try {
      // 解析请求体
      final bodyString = await request.readAsString();
      final Map<String, dynamic> body;

      try {
        body = jsonDecode(bodyString) as Map<String, dynamic>;
      } catch (e) {
        LogUtil.wTag(logTag, '无效的JSON格式: $bodyString');
        return _buildErrorResponse('无效的JSON格式');
      }

      // 提取参数
      final requesterDeviceName = body['requesterDeviceName'] as String? ?? '未知设备';
      
      LogUtil.dTag(logTag, '请求设备: $requesterDeviceName');

      // 检查上下文是否可用
      final ctx = contextGetter?.call();

      if (ctx == null || !ctx.mounted) {
        LogUtil.eTag(logTag, '无法显示确认对话框：缺少上下文');
        return _buildErrorResponse('服务器内部错误');
      }

      // 显示确认对话框
      final userAccepted = await _showClipboardRequestDialog(
        ctx,
        requesterDeviceName,
      );

      if (!userAccepted) {
        LogUtil.iTag(logTag, '用户拒绝了剪切板请求');
        return _buildRejectedResponse();
      }

      // 用户同意，获取剪切板内容
      final clipboardData = await _clipboardService.getClipboardContent();

      if (clipboardData == null) {
        LogUtil.wTag(logTag, '剪切板为空，无法分享');
        return _buildEmptyClipboardResponse();
      }

      // 检查剪切板大小
      final contentSizeMB = clipboardData.sizeInMB;

      // 获取最大剪切板大小设置
      final maxSizeMB = await _preferencesService.getMaxClipboardSize();

      LogUtil.dTag(
        logTag,
        '剪切板内容: ${clipboardData.typeDescription}, 大小: ${contentSizeMB.toStringAsFixed(2)} MB, 限制: $maxSizeMB MB',
      );

      if (contentSizeMB > maxSizeMB) {
        LogUtil.wTag(
          logTag,
          '剪切板内容过大: ${contentSizeMB.toStringAsFixed(2)} MB > $maxSizeMB MB',
        );
        return _buildContentTooLargeResponse(contentSizeMB, maxSizeMB);
      }

      LogUtil.iTag(
        logTag,
        '用户同意分享剪切板，类型: ${clipboardData.typeDescription}, 大小: ${contentSizeMB.toStringAsFixed(2)} MB',
      );

      return _buildSuccessResponse(clipboardData);
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '处理剪切板请求异常: $e', e, stackTrace);
      return _buildErrorResponse('处理请求时发生错误');
    }
  }

  /// 显示剪切板请求确认对话框
  ///
  /// 返回用户是否同意分享剪切板
  Future<bool> _showClipboardRequestDialog(
    BuildContext context,
    String requesterDeviceName,
  ) async {
    // 使用 Completer 来处理超时
    final completer = Completer<bool>();
    bool dialogClosed = false;

    // 设置超时定时器
    final timeoutTimer = Timer(
      AppConstants.receiveConfirmationTimeout,
      () {
        if (!dialogClosed && !completer.isCompleted) {
          dialogClosed = true;
          Navigator.of(context, rootNavigator: true).pop();
          completer.complete(false);
          LogUtil.wTag(logTag, '剪切板请求确认超时');
        }
      },
    );

    try {
      if (!context.mounted) {
        return false;
      }

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _ClipboardRequestDialog(
          requesterDeviceName: requesterDeviceName,
          onAccept: () {
            if (!dialogClosed) {
              dialogClosed = true;
              Navigator.of(dialogContext).pop(true);
            }
          },
          onReject: () {
            if (!dialogClosed) {
              dialogClosed = true;
              Navigator.of(dialogContext).pop(false);
            }
          },
        ),
      );

      timeoutTimer.cancel();
      return result ?? false;
    } catch (e) {
      timeoutTimer.cancel();
      LogUtil.eTag(logTag, '显示确认对话框失败: $e');
      return false;
    }
  }

  /// 构建成功响应
  Response _buildSuccessResponse(ClipboardDataModel data) {
    return Response(
      200,
      body: jsonEncode({
        'accepted': true,
        'clipboardData': data.toJson(),
        'message': '成功获取剪切板内容',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 构建拒绝响应
  Response _buildRejectedResponse() {
    return Response(
      200,
      body: jsonEncode({
        'accepted': false,
        'message': '用户拒绝了剪切板请求',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 构建剪切板为空的响应
  Response _buildEmptyClipboardResponse() {
    return Response(
      200,
      body: jsonEncode({
        'accepted': false,
        'message': '剪切板为空',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 构建内容过大的响应
  Response _buildContentTooLargeResponse(double actualSizeMB, int maxSizeMB) {
    return Response(
      413, // Payload Too Large
      body: jsonEncode({
        'accepted': false,
        'message': '剪切板内容过大 (${actualSizeMB.toStringAsFixed(2)} MB)，超过限制 ($maxSizeMB MB)。建议使用文件传输功能。',
        'actualSizeMB': actualSizeMB,
        'maxSizeMB': maxSizeMB,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 构建错误响应
  Response _buildErrorResponse(String message) {
    return Response(
      400,
      body: jsonEncode({
        'accepted': false,
        'message': message,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

/// 剪切板请求确认对话框
class _ClipboardRequestDialog extends StatefulWidget {
  final String requesterDeviceName;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ClipboardRequestDialog({
    required this.requesterDeviceName,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_ClipboardRequestDialog> createState() =>
      _ClipboardRequestDialogState();
}

class _ClipboardRequestDialogState extends State<_ClipboardRequestDialog> {
  int _countdown = AppConstants.receiveConfirmationCountdown;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(
      AppConstants.countdownInterval,
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _countdown--;
        });

        if (_countdown <= 0) {
          timer.cancel();
          widget.onReject();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.content_paste, color: Colors.blue[700]),
          const SizedBox(width: 12),
          const Expanded(child: Text('剪切板请求')),
        ],
      ),
      content: SizedBox(
        width: screenWidth * AppConstants.dialogWidthPercent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设备 "${widget.requesterDeviceName}" 请求获取您的剪切板内容',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              '是否允许？',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _countdown / AppConstants.receiveConfirmationCountdown,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _countdown > 10 ? Colors.blue : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_countdown 秒后自动拒绝',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onReject,
          child: const Text('拒绝'),
        ),
        ElevatedButton(
          onPressed: widget.onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('允许'),
        ),
      ],
    );
  }
}
