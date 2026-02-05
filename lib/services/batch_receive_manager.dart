import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/format_util.dart';

/// Information about a file pending receive confirmation
class PendingFileInfo {
  final String fileName;
  final int fileSize;
  final String senderIP;
  final String? senderDeviceName;
  final Completer<bool> completer;
  final String transferId;

  // Progress tracking
  double progress = 0.0;
  int bytesReceived = 0;
  String status = '等待确认...';
  bool isAccepted = false;
  bool isCompleted = false;

  PendingFileInfo({
    required this.fileName,
    required this.fileSize,
    required this.senderIP,
    this.senderDeviceName,
    required this.completer,
    required this.transferId,
  });
}

/// Manages batch file receive requests from the same sender
class BatchReceiveManager {
  // Singleton instance
  static final BatchReceiveManager _instance = BatchReceiveManager._internal();

  factory BatchReceiveManager() => _instance;

  BatchReceiveManager._internal();

  // Pending files grouped by sender IP
  final Map<String, List<PendingFileInfo>> _pendingFilesBySender = {};

  // Active batch dialogs by sender IP (stores the state key for updating)
  final Map<String, GlobalKey<_BatchReceiveDialogState>> _activeDialogKeys = {};

  // Timer to batch requests within a short time window
  final Map<String, Timer> _batchTimers = {};

  /// Request batch receive confirmation for multiple files at once
  /// This is the preferred method when sending multiple files
  Future<bool> requestBatchReceiveConfirmation({
    required BuildContext context,
    required List<PendingFileInfo> files,
    required String senderIP,
    String? senderDeviceName,
  }) async {
    if (files.isEmpty) return false;

    // Add all files to pending list
    _pendingFilesBySender.putIfAbsent(senderIP, () => []).addAll(files);

    // Cancel any existing timer for this sender
    _batchTimers[senderIP]?.cancel();

    // Show dialog immediately with all files
    // Don't await here, let it run in background
    _showBatchDialog(context, senderIP);

    // Wait for all files to be confirmed or rejected
    // This will block until user clicks accept or reject
    final results = await Future.wait(
      files.map((file) => file.completer.future),
    );

    // Return true if all files were accepted
    return results.every((accepted) => accepted);
  }

  /// Show batch receive dialog for all pending files from a sender
  Future<void> _showBatchDialog(BuildContext context, String senderIP) async {
    if (!context.mounted) return;

    final pendingFiles = _pendingFilesBySender[senderIP];
    if (pendingFiles == null || pendingFiles.isEmpty) return;

    // Create a global key for the dialog state
    final dialogKey = GlobalKey<_BatchReceiveDialogState>();
    _activeDialogKeys[senderIP] = dialogKey;

    // Show dialog (it will handle its own lifecycle)
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _BatchReceiveDialog(
        key: dialogKey,
        senderIP: senderIP,
        senderDeviceName: pendingFiles.first.senderDeviceName,
        pendingFiles: pendingFiles,
        onAccept: () {
          // User accepted, update status and complete futures
          for (final fileInfo in pendingFiles) {
            if (!fileInfo.completer.isCompleted) {
              fileInfo.isAccepted = true;
              fileInfo.status = '准备接收...';
              fileInfo.completer.complete(true);
            }
          }
        },
        onReject: () {
          // User rejected, update status and complete futures
          for (final fileInfo in pendingFiles) {
            if (!fileInfo.completer.isCompleted) {
              fileInfo.isAccepted = false;
              fileInfo.status = '已拒绝';
              fileInfo.isCompleted = true;
              fileInfo.completer.complete(false);
            }
          }
          // Close dialog immediately on reject
          Navigator.of(dialogContext).pop();
        },
      ),
    );

    // Mark dialog as inactive
    _activeDialogKeys.remove(senderIP);

    // Clear pending files for this sender
    _pendingFilesBySender.remove(senderIP);
    _batchTimers.remove(senderIP);
  }

  /// Update progress for a specific transfer
  void updateProgress(
    String transferId,
    double progress,
    int bytesReceived,
    int totalBytes,
  ) {
    // Find the file info
    for (final files in _pendingFilesBySender.values) {
      for (final fileInfo in files) {
        if (fileInfo.transferId == transferId) {
          fileInfo.progress = progress;
          fileInfo.bytesReceived = bytesReceived;
          if (progress >= 1.0) {
            fileInfo.status = '接收完成';
            fileInfo.isCompleted = true;
          } else {
            fileInfo.status = '接收中... ${(progress * 100).toStringAsFixed(1)}%';
          }

          // Notify the dialog to update if it's active
          final senderIP = fileInfo.senderIP;
          if (_activeDialogKeys.containsKey(senderIP)) {
            final dialogKey = _activeDialogKeys[senderIP];
            dialogKey?.currentState?._notifyProgressUpdate();
          }
          return;
        }
      }
    }
  }

  /// Get pending files for a sender
  List<PendingFileInfo>? getPendingFiles(String senderIP) {
    return _pendingFilesBySender[senderIP];
  }

  /// Clear all pending files
  void clear() {
    for (final timer in _batchTimers.values) {
      timer.cancel();
    }
    _batchTimers.clear();
    _pendingFilesBySender.clear();
    _activeDialogKeys.clear();
  }
}

/// Dialog widget for batch file receive confirmation
class _BatchReceiveDialog extends StatefulWidget {
  final String senderIP;
  final String? senderDeviceName;
  final List<PendingFileInfo> pendingFiles;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BatchReceiveDialog({
    super.key,
    required this.senderIP,
    this.senderDeviceName,
    required this.pendingFiles,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_BatchReceiveDialog> createState() => _BatchReceiveDialogState();
}

class _BatchReceiveDialogState extends State<_BatchReceiveDialog> {
  int _remainingSeconds = AppConstants.receiveConfirmationCountdown;
  bool _disposed = false;
  bool _isAccepted = false;
  bool _allCompleted = false;
  Timer? _countdownTimer;
  Timer? _updateTimer;

  // Local copy of pending files (can be updated dynamically)
  late List<PendingFileInfo> _displayedFiles;

  @override
  void initState() {
    super.initState();
    _displayedFiles = List.from(widget.pendingFiles);
    _startCountdown();
    _startProgressUpdates();
  }

  /// Add a new file to the dialog (called when new file request arrives)
  void addNewFile(PendingFileInfo fileInfo) {
    if (mounted) {
      setState(() {
        _displayedFiles.add(fileInfo);

        // If already accepted, auto-accept the new file
        if (_isAccepted) {
          fileInfo.isAccepted = true;
          fileInfo.status = '准备接收...';
          fileInfo.completer.complete(true);
        }
      });
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(AppConstants.countdownInterval, (timer) {
      if (!_disposed && mounted) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 0) {
          timer.cancel();
          // Auto-reject on timeout
          _handleReject();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _startProgressUpdates() {
    // Update UI periodically to show progress
    _updateTimer = Timer.periodic(AppConstants.progressUpdateInterval, (timer) {
      if (!_disposed && mounted && _isAccepted) {
        setState(() {
          // Check if all files are completed
          _allCompleted = _displayedFiles.every((file) => file.isCompleted);
        });

        // Auto-close dialog when all files are completed
        if (_allCompleted) {
          timer.cancel();
          Future.delayed(AppConstants.autoCloseDelay, () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      } else if (!_disposed && !_isAccepted) {
        // Just keep the timer running if not accepted yet
      } else {
        timer.cancel();
      }
    });
  }

  /// Notify that progress has been updated (called from BatchReceiveManager)
  void _notifyProgressUpdate() {
    if (mounted && _isAccepted) {
      setState(() {
        // Check if all files are completed
        _allCompleted = _displayedFiles.every((file) => file.isCompleted);
      });

      // Auto-close dialog when all files are completed
      if (_allCompleted) {
        _updateTimer?.cancel();
        Future.delayed(AppConstants.autoCloseDelay, () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  void _handleAccept() {
    setState(() {
      _isAccepted = true;
      _countdownTimer?.cancel(); // Stop countdown
    });

    // Accept all current files
    for (final fileInfo in _displayedFiles) {
      if (!fileInfo.completer.isCompleted) {
        fileInfo.isAccepted = true;
        fileInfo.status = '准备接收...';
        fileInfo.completer.complete(true);
      }
    }

    widget.onAccept();
  }

  void _handleReject() {
    // Reject all files
    for (final fileInfo in _displayedFiles) {
      if (!fileInfo.completer.isCompleted) {
        fileInfo.isAccepted = false;
        fileInfo.status = '已拒绝';
        fileInfo.isCompleted = true;
        fileInfo.completer.complete(false);
      }
    }

    widget.onReject();
  }

  int _getTotalSize() {
    return _displayedFiles.fold(0, (sum, file) => sum + file.fileSize);
  }

  @override
  void dispose() {
    _disposed = true;
    _countdownTimer?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSize = _getTotalSize();
    final fileCount = _displayedFiles.length;

    return PopScope(
      canPop: !_isAccepted || _allCompleted,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              _isAccepted ? Icons.downloading : Icons.file_download,
              color: _isAccepted ? Colors.green : Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isAccepted ? '正在接收 $fileCount 个文件' : '接收 $fileCount 个文件',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender info
              if (widget.senderDeviceName != null) ...[
                Text(
                  '发送者: ${widget.senderDeviceName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
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

              // Total size
              Text(
                '总大小: ${FormatUtil.formatBytes(totalSize)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // File list
              const Text(
                '文件列表:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _displayedFiles.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey[300]),
                    itemBuilder: (context, index) {
                      final file = _displayedFiles[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.insert_drive_file,
                          size: 20,
                          color: file.isAccepted
                              ? (file.isCompleted ? Colors.green : Colors.blue)
                              : Colors.grey,
                        ),
                        title: Text(
                          file.fileName,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FormatUtil.formatBytes(file.fileSize),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (file.isAccepted) ...[
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: file.progress,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  file.isCompleted ? Colors.green : Colors.blue,
                                ),
                                minHeight: 3,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                file.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: file.isCompleted
                                      ? Colors.green
                                      : Colors.blue[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Status message
              if (_isAccepted) ...[
                if (_allCompleted) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '所有文件接收完成！',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[700]!,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '正在接收文件...',
                        style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                // Timeout warning (only show when not accepted)
                Text(
                  '是否接收这些文件？($_remainingSeconds 秒后自动拒绝)',
                  style: TextStyle(
                    color: _remainingSeconds <= 10
                        ? Colors.red
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: _isAccepted
            ? null // Hide buttons when files are being received
            : <Widget>[
                TextButton(onPressed: _handleReject, child: const Text('全部拒绝')),
                ElevatedButton(
                  onPressed: _handleAccept,
                  child: const Text('全部接受'),
                ),
              ],
      ),
    );
  }
}
