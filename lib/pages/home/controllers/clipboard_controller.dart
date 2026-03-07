import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/clipboard_service.dart';
import '../../../services/preferences_service.dart';
import '../../../services/transfer/health_checker.dart';
import '../../../utils/dialog_helper.dart';
import '../../../utils/log_util.dart';
import '../../../utils/network_util.dart';
import '../../../utils/toast_helper.dart';

/// Controller for handling clipboard sync logic
class ClipboardController {
  final ClipboardService _clipboardService;
  final PreferencesService _preferencesService;
  final HealthChecker _healthChecker;
  final String logTag = LogTags.clipboard;

  ClipboardController({
    ClipboardService? clipboardService,
    PreferencesService? preferencesService,
    HealthChecker? healthChecker,
  }) : _clipboardService = clipboardService ?? ClipboardService(),
       _preferencesService = preferencesService ?? PreferencesService(),
       _healthChecker = healthChecker ?? HealthChecker();

  /// Request and sync clipboard content from target device
  ///
  /// This method handles the complete clipboard sync workflow:
  /// 1. Shows loading dialog
  /// 2. Performs health check on target device
  /// 3. Gets device name
  /// 4. Requests clipboard from target device
  /// 5. Writes to local clipboard
  /// 6. Shows result to user
  /// 7. Saves IP to history on success
  Future<void> syncClipboard({
    required BuildContext context,
    required String targetIP,
    required int targetPort,
    String? secretKey,
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) async {
    try {
      final l10n = AppLocalizations.of(context);
      // Show loading dialog
      if (context.mounted) {
        DialogHelper.showLoadingDialog(
          context,
          message: l10n.checkingTargetDevice,
        );
      }

      // Step 1: Health check
      final targetAddress = '$targetIP:$targetPort';
      LogUtil.iTag(logTag, '开始健康检查: $targetAddress');

      final healthResult = await _healthChecker.checkHealth(targetAddress);

      if (!healthResult.isSuccess) {
        LogUtil.wTag(logTag, '健康检查失败: ${healthResult.errorMessage}');

        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (context.mounted) {
          await DialogHelper.showErrorDialog(
            context,
            message: l10n.targetDeviceError(healthResult.errorMessage ?? ''),
            title: l10n.connectionFailed,
            confirmText: l10n.confirm,
          );
        }
        onError();
        return;
      }

      LogUtil.iTag(logTag, '健康检查成功，设备: ${healthResult.data?.deviceName}');

      // Update loading message
      if (context.mounted) {
        Navigator.of(context).pop();
        DialogHelper.showLoadingDialog(
          context,
          message: l10n.requestingClipboard,
        );
      }

      // Step 2: Get device name for the request
      final deviceName = await NetworkUtil.getDeviceName();

      // Step 3: Request clipboard from target device
      final result = await _clipboardService.syncClipboardFromDevice(
        targetIP: targetIP,
        port: targetPort,
        deviceName: deviceName,
        secretKey: secretKey,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.isSuccess) {
        if (context.mounted) {
          // Get clipboard data type
          final data = result.data;
          String successMessage = l10n.clipboardSyncSuccess;

          // Show different message based on type
          if (data != null) {
            if (data.type.name == 'text') {
              successMessage = l10n.textClipboardSyncSuccess;
            } else if (data.type.name == 'file') {
              successMessage = l10n.fileClipboardSyncSuccess;
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
            message: result.errorMessage ?? l10n.clipboardSyncFailed,
            title: l10n.syncFailed,
            confirmText: l10n.confirm,
          );
        }
        onError();
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        final l10n = AppLocalizations.of(context);
        await DialogHelper.showErrorDialog(
          context,
          message: l10n.clipboardRequestError(e.toString()),
          title: l10n.error,
          confirmText: l10n.confirm,
        );
      }
      onError();
    }
  }
}
