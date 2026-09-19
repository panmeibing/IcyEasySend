import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/transfer_file_item.dart';
import '../../../services/screen_wake_lock_service.dart';
import '../../../utils/transfer_progress_throttle.dart';
import '../../../utils/transfer_rate_tracker.dart';

/// Mutable progress snapshot for the home-page transfer card.
///
/// Lives outside the page so the send callbacks do not have to keep rewriting
/// a dozen fields inline. The page still owns `setState` — this class only
/// mutates its own fields and tells the caller when the UI needs a rebuild.
class SendProgressController {
  double progress = 0.0;
  int bytesTransferred = 0;
  int totalBytes = 0;
  double speed = 0.0;
  Duration? estimatedTimeRemaining;
  String status = '';

  int totalFilesCount = 0;
  int completedFilesCount = 0;
  final Map<int, double> fileProgress = {};
  final Map<int, String> fileStatus = {};
  final Set<int> completedFileIndices = {};

  final TransferProgressThrottle _overallThrottle = TransferProgressThrottle();
  final TransferProgressThrottle _fileThrottle = TransferProgressThrottle();
  final TransferRateTracker _rateTracker = TransferRateTracker();

  void onOverallProgress({
    required double progress,
    required int bytesTransferred,
    required int totalBytes,
    required VoidCallback onUiUpdate,
  }) {
    _overallThrottle.maybeEmit(
      key: 'overall',
      progress: progress,
      bytesTransferred: bytesTransferred,
      totalBytes: totalBytes,
      onEmit: (progress, bytesTransferred, totalBytes) {
        this.progress = progress;
        this.bytesTransferred = bytesTransferred;
        this.totalBytes = totalBytes;

        _rateTracker.onProgress(
          bytesTransferred: bytesTransferred,
          totalBytes: totalBytes,
        );
        speed = _rateTracker.speed;
        estimatedTimeRemaining = _rateTracker.estimatedTimeRemaining;

        onUiUpdate();
      },
    );
  }

  void onFileProgress({
    required int fileIndex,
    required double progress,
    required List<TransferFileItem> items,
    required AppLocalizations l10n,
    required VoidCallback onUiUpdate,
  }) {
    _fileThrottle.maybeEmit(
      key: fileIndex,
      progress: progress,
      bytesTransferred: 0,
      totalBytes: 0,
      onEmit: (progress, bytesTransferred, totalBytes) {
        // The shared throttle callback always passes byte counts; per-file
        // status only cares about the 0..1 progress value.
        fileProgress[fileIndex] = progress;
        final fileName = items[fileIndex].transferName;

        if (progress < 1.0) {
          fileStatus[fileIndex] = l10n.transferringProgress(progress * 100);
          status =
              '[${fileIndex + 1}/${items.length}] $fileName: ${l10n.transferring}...';
        } else {
          if (!completedFileIndices.contains(fileIndex)) {
            completedFileIndices.add(fileIndex);
            completedFilesCount++;
          }
          fileStatus[fileIndex] = l10n.sendSuccess;
        }
        onUiUpdate();
      },
    );
  }

  void onStatusChange(String next, VoidCallback onUiUpdate) {
    status = next;
    onUiUpdate();
  }

  /// Wake lock and throttles belong to the transfer, so they run even if the
  /// page has already been disposed. [onUiUpdate] is only invoked when the
  /// caller still has a mounted widget.
  void onTransferStart({
    required int fileCount,
    required String preparingLabel,
    required VoidCallback onUiUpdate,
  }) {
    ScreenWakeLockService.acquire();
    _overallThrottle.reset();
    _fileThrottle.reset();
    _rateTracker.reset();

    totalFilesCount = fileCount;
    completedFilesCount = 0;
    progress = 0.0;
    bytesTransferred = 0;
    totalBytes = 0;
    speed = 0.0;
    estimatedTimeRemaining = null;
    status = preparingLabel;
    fileProgress.clear();
    fileStatus.clear();
    completedFileIndices.clear();

    onUiUpdate();
  }

  void onTransferEnd({
    required VoidCallback onUiUpdate,
    required VoidCallback clearSelectedItems,
  }) {
    ScreenWakeLockService.release();
    _rateTracker.reset();

    completedFilesCount = 0;
    totalFilesCount = 0;
    progress = 0.0;
    bytesTransferred = 0;
    totalBytes = 0;
    speed = 0.0;
    estimatedTimeRemaining = null;
    status = '';
    fileProgress.clear();
    fileStatus.clear();
    completedFileIndices.clear();
    clearSelectedItems();
    onUiUpdate();
  }
}
