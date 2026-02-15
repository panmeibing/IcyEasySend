import 'package:flutter/material.dart';

import '../../services/clipboard_service.dart';
import '../../services/preferences_service.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/log_util.dart';
import '../../utils/network_util.dart';
import '../../utils/toast_helper.dart';

/// Controller for handling clipboard sync logic
class ClipboardController {
  final ClipboardService _clipboardService;
  final PreferencesService _preferencesService;
  final String logTag = LogTags.clipboard;

  ClipboardController({
    ClipboardService? clipboardService,
    PreferencesService? preferencesService,
  }) : _clipboardService = clipboardService ?? ClipboardService(),
       _preferencesService = preferencesService ?? PreferencesService();

  /// Request and sync clipboard content from target device
  ///
  /// This method handles the complete clipboard sync workflow:
  /// 1. Shows loading dialog
  /// 2. Gets device name
  /// 3. Requests clipboard from target device
  /// 4. Writes to local clipboard
  /// 5. Shows result to user
  /// 6. Saves IP to history on success
  Future<void> syncClipboard({
    required BuildContext context,
    required String targetIP,
    required int targetPort,
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) async {
    try {
      // Show loading dialog
      if (context.mounted) {
        DialogHelper.showLoadingDialog(context, message: '正在请求剪切板...');
      }

      // Get device name for the request
      final deviceName = await NetworkUtil.getDeviceName();

      // Request clipboard from target device
      final result = await _clipboardService.syncClipboardFromDevice(
        targetIP: targetIP,
        port: targetPort,
        deviceName: deviceName,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.isSuccess) {
        if (context.mounted) {
          // Get clipboard data type
          final data = result.data;
          String successMessage = '剪切板同步成功';

          // Show different message based on type
          if (data != null) {
            if (data.type.name == 'text') {
              successMessage = '文本剪切板同步成功';
            } else if (data.type.name == 'file') {
              successMessage = '文件剪切板同步成功\n可在应用或文件管理器中粘贴';
            }
          }

          ToastHelper.showSuccess(context, successMessage);

          // Save IP to history
          await _preferencesService.saveLastUsedIP(targetIP);

          onSuccess();
        }
      } else {
        if (context.mounted) {
          await DialogHelper.showErrorDialog(
            context,
            message: result.errorMessage ?? '剪切板同步失败',
            title: '同步失败',
          );
        }
        onError();
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        await DialogHelper.showErrorDialog(
          context,
          message: '请求剪切板时发生错误: $e',
          title: '错误',
        );
      }
      onError();
    }
  }
}
