import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/dialog_helper.dart';
import '../../../utils/platform_util.dart';
import '../../../utils/toast_helper.dart';
import '../controllers/developer_controller.dart';

/// Developer info dialog (unlocked via version tap on AboutCard).
class DeveloperInfoDialog {
  DeveloperInfoDialog._();

  /// Loads and shows developer paths / log copy actions.
  static Future<void> show(
    BuildContext context, {
    required DeveloperController developerController,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (!context.mounted) return;
    DialogHelper.showLoadingDialog(context, message: l10n.loadingDevInfo);

    try {
      final devInfo = await developerController.getDeveloperInfo();
      final logPath = await PlatformUtil.getLoggerFilePath();

      if (!context.mounted) return;

      Navigator.of(context).pop();

      await DialogHelper.showCustomDialog(
        context,
        title: Row(
          children: [
            const Icon(Icons.developer_mode, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.devInfo),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                devInfo,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _copyLogContent(
                  context,
                  developerController: developerController,
                  logPath: logPath,
                ),
                icon: const Icon(Icons.copy, size: 18),
                label: Text(l10n.copyLog),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: devInfo));
              ToastHelper.showSuccess(context, l10n.copied);
            },
            child: Text(l10n.copy),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(l10n.close),
          ),
        ],
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ToastHelper.showError(context, '${l10n.error}: $e');
      }
    }
  }

  static Future<void> _copyLogContent(
    BuildContext context, {
    required DeveloperController developerController,
    required String logPath,
  }) async {
    final l10n = AppLocalizations.of(context);
    final result = await developerController.copyLogContent(logPath);

    if (!context.mounted) return;

    if (result['success']) {
      await Clipboard.setData(ClipboardData(text: result['content']));
      if (!context.mounted) return;
      ToastHelper.showSuccess(context, l10n.logCopied(result['lineCount']));
    } else {
      final message = result['message'] as String;
      if (message == l10n.logFileEmpty) {
        ToastHelper.showWarning(context, message);
      } else {
        ToastHelper.showError(context, message);
      }
    }
  }
}
