import 'package:flutter/material.dart';
import 'package:icy_easy_send/utils/constants.dart';

import '../utils/format_util.dart';

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
  int _remainingSeconds = AppConstants.receiveConfirmationCountdown;
  bool _disposed = false;
  bool _autoAcceptRemaining = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(AppConstants.countdownInterval, () {
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
    final formattedSize = FormatUtil.formatBytes(widget.fileSize);
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
              '已接收: ${FormatUtil.formatBytes(bytesReceived)} / ${FormatUtil.formatBytes(totalBytes)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }
}
