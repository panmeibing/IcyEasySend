import 'package:flutter/material.dart';

/// Result of a receive confirmation dialog
class ReceiveConfirmationResult {
  final bool accepted;
  final bool timedOut;
  final bool autoAcceptRemaining; // 是否自动接收后续文件

  ReceiveConfirmationResult({
    required this.accepted,
    this.timedOut = false,
    this.autoAcceptRemaining = false,
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
  /// `remainingFiles` - Number of remaining files in the batch (optional)
  ///
  /// Returns a Future of ReceiveConfirmationResult indicating whether the user
  /// accepted or rejected the file, or if the dialog timed out
  Future<ReceiveConfirmationResult> showReceiveConfirmation({
    required BuildContext context,
    required String senderIP,
    String? senderDeviceName,
    required String fileName,
    required int fileSize,
    int? remainingFiles,
  }) async {
    Map<String, dynamic>? result;
    bool timedOut = false;

    // Create a completer to handle the timeout
    final dialogFuture = showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _ReceiveConfirmationDialog(
          senderIP: senderIP,
          senderDeviceName: senderDeviceName,
          fileName: fileName,
          fileSize: fileSize,
          remainingFiles: remainingFiles,
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
            Navigator.of(
              context,
              rootNavigator: true,
            ).pop({'accepted': false, 'autoAccept': false});
          }
          return {'accepted': false, 'autoAccept': false};
        },
      );
    } catch (e) {
      // Handle any errors during dialog display
      result = {'accepted': false, 'autoAccept': false};
    }

    return ReceiveConfirmationResult(
      accepted: result?['accepted'] ?? false,
      timedOut: timedOut,
      autoAcceptRemaining: result?['autoAccept'] ?? false,
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

  /// Show a receiving progress dialog
  ///
  /// Returns a function to update the progress and a function to close the dialog
  Future<ReceiveProgressController> showReceiveProgress({
    required BuildContext context,
    required String fileName,
    required int fileSize,
    required String senderIP,
    String? senderDeviceName,
    bool isAutoAccept = false,
  }) async {
    final controller = ReceiveProgressController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _ReceiveProgressDialog(
          fileName: fileName,
          fileSize: fileSize,
          senderIP: senderIP,
          senderDeviceName: senderDeviceName,
          controller: controller,
          isAutoAccept: isAutoAccept,
        );
      },
    ).then((_) {
      // Dialog closed
      controller._dialogClosed = true;
    });

    return controller;
  }
}

/// Controller for receive progress dialog
class ReceiveProgressController {
  double _progress = 0.0;
  int _bytesReceived = 0;
  int _totalBytes = 0;
  bool _dialogClosed = false;
  void Function()? _updateCallback;

  /// Update the progress
  void updateProgress(double progress, int bytesReceived, int totalBytes) {
    if (_dialogClosed) return;

    _progress = progress;
    _bytesReceived = bytesReceived;
    _totalBytes = totalBytes;
    _updateCallback?.call();
  }

  /// Close the dialog
  void close(BuildContext context) {
    if (!_dialogClosed) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogClosed = true;
    }
  }

  void _setUpdateCallback(void Function() callback) {
    _updateCallback = callback;
  }
}

/// Internal widget for the receive confirmation dialog
class _ReceiveConfirmationDialog extends StatefulWidget {
  final String senderIP;
  final String? senderDeviceName;
  final String fileName;
  final int fileSize;
  final int? remainingFiles;

  const _ReceiveConfirmationDialog({
    required this.senderIP,
    this.senderDeviceName,
    required this.fileName,
    required this.fileSize,
    this.remainingFiles,
  });

  @override
  State<_ReceiveConfirmationDialog> createState() =>
      _ReceiveConfirmationDialogState();
}

class _ReceiveConfirmationDialogState
    extends State<_ReceiveConfirmationDialog> {
  int _remainingSeconds = 30;
  bool _disposed = false;
  bool _autoAcceptRemaining = false;

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
    final hasRemainingFiles =
        widget.remainingFiles != null && widget.remainingFiles! > 0;

    return AlertDialog(
      title: const Text('接收文件确认'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.senderDeviceName != null) ...[
            Text(
              '发送者: ${widget.senderDeviceName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'IP: ${widget.senderIP}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ] else ...[
            Text('发送者 IP: ${widget.senderIP}'),
          ],
          const SizedBox(height: 8),
          Text('文件名: ${widget.fileName}'),
          const SizedBox(height: 8),
          Text('文件大小: $formattedSize'),
          if (hasRemainingFiles) ...[
            const SizedBox(height: 8),
            Text(
              '后续还有 ${widget.remainingFiles} 个文件',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            '是否接收此文件？($_remainingSeconds 秒后自动拒绝)',
            style: TextStyle(
              color: _remainingSeconds <= 10 ? Colors.red : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          if (hasRemainingFiles) ...[
            const SizedBox(height: 12),
            CheckboxListTile(
              title: Text(
                '自动接收后续 ${widget.remainingFiles} 个文件',
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: const Text('勾选后将不再询问', style: TextStyle(fontSize: 12)),
              value: _autoAcceptRemaining,
              onChanged: (bool? value) {
                setState(() {
                  _autoAcceptRemaining = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('拒绝'),
          onPressed: () {
            Navigator.of(context).pop({'accepted': false, 'autoAccept': false});
          },
        ),
        ElevatedButton(
          child: const Text('接受'),
          onPressed: () {
            Navigator.of(
              context,
            ).pop({'accepted': true, 'autoAccept': _autoAcceptRemaining});
          },
        ),
      ],
    );
  }
}

/// Internal widget for the receive progress dialog
class _ReceiveProgressDialog extends StatefulWidget {
  final String fileName;
  final int fileSize;
  final String senderIP;
  final String? senderDeviceName;
  final ReceiveProgressController controller;
  final bool isAutoAccept;

  const _ReceiveProgressDialog({
    required this.fileName,
    required this.fileSize,
    required this.senderIP,
    this.senderDeviceName,
    required this.controller,
    this.isAutoAccept = false,
  });

  @override
  State<_ReceiveProgressDialog> createState() => _ReceiveProgressDialogState();
}

class _ReceiveProgressDialogState extends State<_ReceiveProgressDialog> {
  @override
  void initState() {
    super.initState();
    widget.controller._setUpdateCallback(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.controller._progress;
    final bytesReceived = widget.controller._bytesReceived;
    final totalBytes = widget.controller._totalBytes;

    return AlertDialog(
      title: Row(
        children: [
          const Text('正在接收文件'),
          if (widget.isAutoAccept) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '自动接收',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.senderDeviceName != null) ...[
            Text(
              '发送者: ${widget.senderDeviceName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'IP: ${widget.senderIP}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ] else ...[
            Text('发送者 IP: ${widget.senderIP}'),
          ],
          const SizedBox(height: 8),
          Text('文件名: ${widget.fileName}'),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          if (totalBytes > 0) ...[
            const SizedBox(height: 8),
            Text(
              '已接收: ${_formatBytes(bytesReceived)} / ${_formatBytes(totalBytes)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }
}
