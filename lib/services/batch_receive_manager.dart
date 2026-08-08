import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/constants.dart';
import '../utils/format_util.dart';
import '../utils/transfer_progress_throttle.dart';
import '../utils/transfer_status_provider.dart';
import 'screen_wake_lock_service.dart';

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
  String status = ''; // Will be set based on current language
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
  final TransferProgressThrottle _receiveProgressThrottle =
      TransferProgressThrottle();

  /// Request batch receive confirmation for multiple files at once
  /// This is the preferred method when sending multiple files
  ///
  /// The onComplete callback is called after the dialog closes (all files received or rejected)
  /// 
  /// If autoAccept is true, the dialog will automatically accept all files immediately
  /// but still show progress (used for secret key authentication)
  Future<bool> requestBatchReceiveConfirmation({
    required BuildContext context,
    required List<PendingFileInfo> files,
    required String senderIP,
    String? senderDeviceName,
    bool autoAccept = false,
    Future<void> Function()? onComplete,
  }) async {
    if (files.isEmpty) return false;

    // Add all files to pending list
    _pendingFilesBySender.putIfAbsent(senderIP, () => []).addAll(files);

    // Cancel and remove any existing timer for this sender
    _batchTimers[senderIP]?.cancel();
    _batchTimers.remove(senderIP);

    // Show dialog immediately with all files
    // Don't await here, let it run in background
    _showBatchDialog(context, senderIP, autoAccept, onComplete);

    // Wait for all files to be confirmed or rejected
    // This will block until user clicks accept or reject (or auto-accept)
    final results = await Future.wait(
      files.map((file) => file.completer.future),
    );

    // Return true if all files were accepted
    return results.every((accepted) => accepted);
  }

  /// Accept a batch without showing any UI (background + secret-key path).
  Future<bool> acceptBatchHeadless({
    required List<PendingFileInfo> files,
    required String senderIP,
  }) async {
    if (files.isEmpty) return false;

    _pendingFilesBySender.putIfAbsent(senderIP, () => []).addAll(files);
    _batchTimers[senderIP]?.cancel();
    _batchTimers.remove(senderIP);

    for (final fileInfo in files) {
      fileInfo.isAccepted = true;
      if (fileInfo.status.isEmpty) {
        fileInfo.status = '准备接收...';
      }
      if (!fileInfo.completer.isCompleted) {
        fileInfo.completer.complete(true);
      }
    }

    return true;
  }

  /// Remove pending entries for a sender after headless transfers finish.
  void clearPendingForSender(String senderIP) {
    _batchTimers[senderIP]?.cancel();
    _batchTimers.remove(senderIP);
    _activeDialogKeys.remove(senderIP);
    _pendingFilesBySender.remove(senderIP);
  }

  /// Show batch receive dialog for all pending files from a sender
  Future<void> _showBatchDialog(
    BuildContext context,
    String senderIP,
    bool autoAccept,
    Future<void> Function()? onComplete,
  ) async {
    if (!context.mounted) return;

    final pendingFiles = _pendingFilesBySender[senderIP];
    if (pendingFiles == null || pendingFiles.isEmpty) return;

    // Get localization
    final l10n = AppLocalizations.of(context);

    // Initialize status for all files if not set
    for (final file in pendingFiles) {
      if (file.status.isEmpty) {
        file.status = l10n.waitingForConfirmation;
      }
    }

    // Create a global key for the dialog state
    final dialogKey = GlobalKey<_BatchReceiveDialogState>();
    _activeDialogKeys[senderIP] = dialogKey;

    try {
      // Show dialog (it will handle its own lifecycle)
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _BatchReceiveDialog(
          key: dialogKey,
          senderIP: senderIP,
          senderDeviceName: pendingFiles.first.senderDeviceName,
          pendingFiles: pendingFiles,
          autoAccept: autoAccept,  // Pass autoAccept flag
          onAccept: () {
            // User accepted, update status and complete futures
            for (final fileInfo in pendingFiles) {
              if (!fileInfo.completer.isCompleted) {
                fileInfo.isAccepted = true;
                fileInfo.status = l10n.preparingToReceive;
                fileInfo.completer.complete(true);
              }
            }
          },
          onReject: () {
            // User rejected, update status and complete futures
            for (final fileInfo in pendingFiles) {
              if (!fileInfo.completer.isCompleted) {
                fileInfo.isAccepted = false;
                fileInfo.status = l10n.rejected;
                fileInfo.isCompleted = true;
                fileInfo.completer.complete(false);
              }
            }
            // Close dialog immediately on reject
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    } catch (e) {
      // If dialog fails to show or is interrupted, complete all pending files as rejected
      for (final fileInfo in pendingFiles) {
        if (!fileInfo.completer.isCompleted) {
          fileInfo.completer.complete(false);
        }
      }
    } finally {
      // Always clean up resources
      _receiveProgressThrottle.reset();
      _activeDialogKeys.remove(senderIP);
      _pendingFilesBySender.remove(senderIP);

      // Cancel and remove timer if it exists
      _batchTimers[senderIP]?.cancel();
      _batchTimers.remove(senderIP);
    }

    // Call completion callback if provided
    if (onComplete != null) {
      await onComplete();
    }
  }

  /// Update progress for a specific transfer
  void updateProgress(
    String transferId,
    double progress,
    int bytesReceived,
    int totalBytes,
  ) {
    _receiveProgressThrottle.maybeEmit(
      key: transferId,
      progress: progress,
      bytesTransferred: bytesReceived,
      totalBytes: totalBytes,
      onEmit: (progress, bytesReceived, totalBytes) {
        _applyReceiveProgress(
          transferId: transferId,
          progress: progress,
          bytesReceived: bytesReceived,
        );
      },
    );
  }

  void _applyReceiveProgress({
    required String transferId,
    required double progress,
    required int bytesReceived,
  }) {
    final statusProvider = TransferStatusProvider();

    // Find the file info
    for (final files in _pendingFilesBySender.values) {
      for (final fileInfo in files) {
        if (fileInfo.transferId == transferId) {
          fileInfo.progress = progress;
          fileInfo.bytesReceived = bytesReceived;
          if (progress >= 1.0) {
            fileInfo.status = statusProvider.receiveComplete;
            fileInfo.isCompleted = true;
          } else {
            fileInfo.status = statusProvider.receivingProgress(progress);
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

  /// Mark a transfer as failed
  void markTransferFailed(String transferId, String errorMessage) {
    // Find the file info
    for (final files in _pendingFilesBySender.values) {
      for (final fileInfo in files) {
        if (fileInfo.transferId == transferId) {
          fileInfo.progress = 0.0;
          fileInfo.status = '失败: $errorMessage';
          fileInfo.isCompleted = true;

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

  /// Clear all pending files and cancel all timers
  void clear() {
    // Cancel all batch timers
    for (final timer in _batchTimers.values) {
      timer.cancel();
    }
    _batchTimers.clear();

    // Complete all pending completers before clearing
    for (final files in _pendingFilesBySender.values) {
      for (final fileInfo in files) {
        if (!fileInfo.completer.isCompleted) {
          fileInfo.completer.complete(false);
        }
      }
    }
    _pendingFilesBySender.clear();

    // Clear active dialog keys
    _activeDialogKeys.clear();
  }
}

/// Dialog widget for batch file receive confirmation
class _BatchReceiveDialog extends StatefulWidget {
  final String senderIP;
  final String? senderDeviceName;
  final List<PendingFileInfo> pendingFiles;
  final bool autoAccept;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BatchReceiveDialog({
    super.key,
    required this.senderIP,
    this.senderDeviceName,
    required this.pendingFiles,
    this.autoAccept = false,
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
    
    // If autoAccept is true, automatically accept after a short delay
    if (widget.autoAccept) {
      // Auto-accept immediately but give UI time to render
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_isAccepted) {
          _handleAccept();
        }
      });
    } else {
      // Start countdown only if not auto-accepting
      _startCountdown();
    }
    
    _startProgressUpdates();
  }

  /// Add a new file to the dialog (called when new file request arrives)
  void addNewFile(PendingFileInfo fileInfo) {
    if (mounted) {
      setState(() {
        _displayedFiles.add(fileInfo);

        // If already accepted, auto-accept the new file
        if (_isAccepted) {
          final l10n = AppLocalizations.of(context);
          fileInfo.isAccepted = true;
          fileInfo.status = l10n.preparingToReceive;
          fileInfo.completer.complete(true);
        }
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel(); // Cancel any existing timer
    _countdownTimer = Timer.periodic(AppConstants.countdownInterval, (timer) {
      if (_disposed || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        // Auto-reject on timeout
        _handleReject();
      }
    });
  }

  void _startProgressUpdates() {
    _updateTimer?.cancel(); // Cancel any existing timer
    // Update UI periodically to show progress
    _updateTimer = Timer.periodic(AppConstants.progressUpdateInterval, (timer) {
      if (_disposed || !mounted) {
        timer.cancel();
        return;
      }

      if (_isAccepted) {
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
      }
      // Keep timer running if not accepted yet
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
    // Stop countdown timer
    _countdownTimer?.cancel();
    _countdownTimer = null;

    ScreenWakeLockService.acquire();

    setState(() {
      _isAccepted = true;
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
    final l10n = AppLocalizations.of(context);

    // Cancel all timers
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _updateTimer?.cancel();
    _updateTimer = null;

    // Reject all files
    for (final fileInfo in _displayedFiles) {
      if (!fileInfo.completer.isCompleted) {
        fileInfo.isAccepted = false;
        fileInfo.status = l10n.rejected;
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
    if (_isAccepted) {
      ScreenWakeLockService.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalSize = _getTotalSize();
    final fileCount = _displayedFiles.length;
    final screenWidth = MediaQuery.of(context).size.width;

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
                _isAccepted
                    ? l10n.receivingFiles(fileCount)
                    : l10n.receiveFilesCount(fileCount),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: screenWidth * AppConstants.dialogWidthPercent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender info
              if (widget.senderDeviceName != null) ...[
                Text(
                  '${l10n.sender}: ${widget.senderDeviceName}',
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
                Text('${l10n.sender} IP: ${widget.senderIP}'),
              ],
              const SizedBox(height: 8),

              // Total size
              Text(
                '${l10n.totalSizeBatch}: ${FormatUtil.formatBytes(totalSize)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // File list
              Text(
                '${l10n.fileList}:',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                              ? (file.isCompleted
                                    ? (file.status.startsWith('失败')
                                          ? Colors.red
                                          : Colors.green)
                                    : Colors.blue)
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
                                  file.isCompleted
                                      ? (file.status.startsWith('失败')
                                            ? Colors.red
                                            : Colors.green)
                                      : Colors.blue,
                                ),
                                minHeight: 3,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                file.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: file.isCompleted
                                      ? (file.status.startsWith('失败')
                                            ? Colors.red
                                            : Colors.green)
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
                        l10n.allFilesReceiveComplete,
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
                        l10n.receivingFiles2,
                        style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                // Timeout warning (only show when not accepted)
                Text(
                  l10n.autoRejectCountdown(_remainingSeconds),
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
                TextButton(
                  onPressed: _handleReject,
                  child: Text(l10n.rejectAll),
                ),
                ElevatedButton(
                  onPressed: _handleAccept,
                  child: Text(l10n.acceptAll),
                ),
              ],
      ),
    );
  }
}
