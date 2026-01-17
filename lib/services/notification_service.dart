import 'package:flutter/material.dart';

/// Result of a receive confirmation dialog
class ReceiveConfirmationResult {
  final bool accepted;
  final bool timedOut;

  ReceiveConfirmationResult({
    required this.accepted,
    this.timedOut = false,
  });
}

/// NotificationService provides user notification and dialog functionality
class NotificationService {
  /// Show an error dialog with the given message
  /// 
  /// `context` - BuildContext for showing the dialog
  /// `message` - Error message to display
  Future<void> showError(BuildContext context, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('错误'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Show a success message dialog
  /// 
  /// `context` - BuildContext for showing the dialog
  /// `message` - Success message to display
  Future<void> showSuccess(BuildContext context, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('成功'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Show a file receive confirmation dialog with 30-second timeout
  /// 
  /// `context` - BuildContext for showing the dialog
  /// `senderIP` - IP address of the sender device
  /// `fileName` - Name of the file being received
  /// `fileSize` - Size of the file in bytes
  /// 
  /// Returns a Future of ReceiveConfirmationResult indicating whether the user
  /// accepted or rejected the file, or if the dialog timed out
  Future<ReceiveConfirmationResult> showReceiveConfirmation({
    required BuildContext context,
    required String senderIP,
    required String fileName,
    required int fileSize,
  }) async {
    bool? result;
    bool timedOut = false;

    // Create a completer to handle the timeout
    final dialogFuture = showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _ReceiveConfirmationDialog(
          senderIP: senderIP,
          fileName: fileName,
          fileSize: fileSize,
        );
      },
    );

    // Wait for either the dialog result or timeout (30 seconds)
    try {
      result = await dialogFuture.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          // Timeout occurred, close the dialog and return null
          timedOut = true;
          // Use a post-frame callback to safely close the dialog
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop(false);
          }
          return false;
        },
      );
    } catch (e) {
      // Handle any errors during dialog display
      result = false;
    }

    return ReceiveConfirmationResult(
      accepted: result ?? false,
      timedOut: timedOut,
    );
  }

  /// Format file size in human-readable format
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

/// Internal widget for the receive confirmation dialog
class _ReceiveConfirmationDialog extends StatefulWidget {
  final String senderIP;
  final String fileName;
  final int fileSize;

  const _ReceiveConfirmationDialog({
    required this.senderIP,
    required this.fileName,
    required this.fileSize,
  });

  @override
  State<_ReceiveConfirmationDialog> createState() =>
      _ReceiveConfirmationDialogState();
}

class _ReceiveConfirmationDialogState
    extends State<_ReceiveConfirmationDialog> {
  int _remainingSeconds = 30;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!_disposed && mounted) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds > 0) {
          _startCountdown();
        }
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedSize = NotificationService._formatFileSize(widget.fileSize);

    return AlertDialog(
      title: const Text('接收文件确认'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('发送者 IP: ${widget.senderIP}'),
          const SizedBox(height: 8),
          Text('文件名: ${widget.fileName}'),
          const SizedBox(height: 8),
          Text('文件大小: $formattedSize'),
          const SizedBox(height: 16),
          Text(
            '是否接收此文件？($_remainingSeconds 秒后自动拒绝)',
            style: TextStyle(
              color: _remainingSeconds <= 10 ? Colors.red : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('拒绝'),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        ElevatedButton(
          child: const Text('接受'),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}
