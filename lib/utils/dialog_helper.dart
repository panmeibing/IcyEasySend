import 'package:flutter/material.dart';
import 'package:icy_easy_send/utils/constants.dart';

/// Dialogue box tool class - provides a unified dialog box style and behavior
class DialogHelper {
  /// Display confirmation dialog box
  ///
  /// Return true to indicate user clicks confirm, false to indicate cancel
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '确认',
    String cancelText = '取消',
    IconData? icon,
    Color? iconColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        return AlertDialog(
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? Colors.blue),
                const SizedBox(width: 12),
              ],
              Expanded(child: Text(title)),
            ],
          ),
          content: SizedBox(
            width: screenWidth * AppConstants.dialogWidthPercent,
            child: Text(message),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor ?? Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Display error dialog box
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String message,
    String title = '错误',
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          content: SizedBox(
            width: screenWidth * AppConstants.dialogWidthPercent,
            child: Text(message),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// Display successful dialog box
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String message,
    String title = '成功',
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          content: SizedBox(
            width: screenWidth * AppConstants.dialogWidthPercent,
            child: Text(message),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// Display Information Dialogue Box
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String message,
    String title = '提示',
  }) async {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          content: SizedBox(
            width: screenWidth * AppConstants.dialogWidthPercent,
            child: Text(message),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// Display loading dialog with message
  static void showLoadingDialog(
    BuildContext context, {
    required String message,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        return AlertDialog(
          content: SizedBox(
            width: screenWidth * AppConstants.dialogWidthPercent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Display custom dialog with custom content and actions
  static Future<T?> showCustomDialog<T>(
    BuildContext context, {
    Widget? title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        return AlertDialog(
          title: title,
          content: SizedBox(
            width: screenWidth * AppConstants.dialogWidthPercent,
            child: content,
          ),
          actions: actions,
        );
      },
    );
  }
}
