import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/incoming_batch.dart';
import '../../services/batch_receive_prompter.dart';
import '../../services/screen_wake_lock_service.dart';
import '../../ui/form_factor.dart';
import '../../utils/constants.dart';
import '../../utils/format_util.dart';
import '../../utils/transfer_rate_tracker.dart';
import '../tv/tv_incoming_dialog.dart';

/// Shows an incoming batch as a modal dialog: a countdown to accept or reject,
/// then per-file progress until everything has landed.
class DialogBatchReceivePrompter extends BatchReceivePrompter {
  const DialogBatchReceivePrompter();

  @override
  Future<void> present(BuildContext context, IncomingBatch batch) async {
    if (!context.mounted) return;
    // Shelf handlers need a fresh frame before showDialog, or HarmonyOS
    // can open the route with nothing painted.
    await Future<void>.delayed(Duration.zero);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => BatchReceiveDialog(batch: batch),
    );
  }
}

class BatchReceiveDialog extends StatefulWidget {
  const BatchReceiveDialog({super.key, required this.batch});

  final IncomingBatch batch;

  @override
  State<BatchReceiveDialog> createState() => _BatchReceiveDialogState();
}

class _BatchReceiveDialogState extends State<BatchReceiveDialog> {
  final TransferRateTracker _rateTracker = TransferRateTracker();
  int _remainingSeconds = AppConstants.receiveConfirmationCountdown;
  Timer? _countdownTimer;
  Timer? _rateTimer;
  bool _holdsWakeLock = false;

  /// Set once this dialog has started to close, so progress updates and
  /// timers noticing the same ending cannot pop a second route.
  bool _closing = false;

  IncomingBatch get _batch => widget.batch;

  @override
  void initState() {
    super.initState();
    _batch.addListener(_onBatchChanged);

    if (_batch.autoAccept) {
      // Give the dialog a frame on screen before it turns into progress.
      Future.delayed(const Duration(milliseconds: 100), _batch.accept);
    } else {
      _countdownTimer = Timer.periodic(AppConstants.countdownInterval, (_) {
        if (!mounted) return;
        setState(() => _remainingSeconds--);
        if (_remainingSeconds <= 0) {
          _batch.reject();
        }
      });
    }

    // Speed and remaining time move even when no progress event arrives.
    _rateTimer = Timer.periodic(AppConstants.progressUpdateInterval, (_) {
      if (mounted && _batch.isAccepted && !_batch.isFinished) {
        setState(_sampleRate);
      }
    });

    // The batch may have moved on before the dialog got a frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onBatchChanged());
  }

  @override
  void dispose() {
    _batch.removeListener(_onBatchChanged);
    _countdownTimer?.cancel();
    _rateTimer?.cancel();
    if (_holdsWakeLock) {
      ScreenWakeLockService.release();
    }
    super.dispose();
  }

  void _onBatchChanged() {
    if (!mounted) return;

    if (_batch.isDecided) {
      _countdownTimer?.cancel();
    }
    if (_batch.isAccepted && !_holdsWakeLock) {
      _holdsWakeLock = true;
      _rateTracker.reset();
      ScreenWakeLockService.acquire();
    }

    setState(_sampleRate);

    if (_batch.isDecided && !_batch.isAccepted) {
      _close(after: Duration.zero);
    } else if (_batch.isAccepted && _batch.isFinished) {
      _rateTimer?.cancel();
      _close(after: AppConstants.autoCloseDelay);
    }
  }

  void _sampleRate() {
    if (_batch.isAccepted && !_batch.isFinished) {
      _rateTracker.onProgress(
        bytesTransferred: _batch.bytesReceived,
        totalBytes: _batch.totalBytes,
      );
    }
  }

  /// Closes this dialog's own route, even if something else has since been
  /// pushed over it.
  void _close({required Duration after}) {
    if (_closing) return;
    _closing = true;
    Future.delayed(after, () {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final route = ModalRoute.of(context);
      if (route == null || route.isCurrent) {
        navigator.pop();
      } else {
        navigator.removeRoute(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = _BatchView.of(l10n, _batch, _rateTracker, _remainingSeconds);

    return PopScope(
      // While undecided, back means "reject"; while receiving it is blocked so
      // the transfer cannot be orphaned by an accidental press.
      canPop: _closing || (_batch.isAccepted && _batch.isFinished),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_batch.isDecided) _batch.reject();
      },
      child: AppFormFactor.isTv
          ? _TvBatchDialog(view: view, batch: _batch)
          : _PhoneBatchDialog(view: view, batch: _batch),
    );
  }
}

/// Text shared by the phone and TV layouts.
class _BatchView {
  const _BatchView({
    required this.l10n,
    required this.title,
    required this.speedLine,
    required this.etaLine,
    required this.countdown,
    required this.remainingSeconds,
    required this.statusLine,
  });

  factory _BatchView.of(
    AppLocalizations l10n,
    IncomingBatch batch,
    TransferRateTracker rate,
    int remainingSeconds,
  ) {
    final count = batch.files.length;
    final receiving = batch.isAccepted && !batch.isFinished;
    final eta = rate.estimatedTimeRemaining;
    return _BatchView(
      l10n: l10n,
      title: batch.isAccepted
          ? l10n.receivingFiles(count)
          : l10n.receiveFilesCount(count),
      speedLine: receiving && rate.speed > 0
          ? FormatUtil.formatTransferSpeedLabel(l10n.transferSpeed, rate.speed)
          : null,
      etaLine: receiving && eta != null
          ? FormatUtil.formatRemainingTimeLabel(l10n.remainingTime, eta)
          : null,
      countdown: batch.isDecided
          ? null
          : l10n.autoRejectCountdown(remainingSeconds),
      remainingSeconds: remainingSeconds,
      statusLine: !batch.isAccepted
          ? null
          : batch.isFinished
          ? l10n.allFilesReceiveComplete
          : l10n.receivingFiles2,
    );
  }

  final AppLocalizations l10n;
  final String title;
  final String? speedLine;
  final String? etaLine;
  final String? countdown;
  final int remainingSeconds;
  final String? statusLine;

  String totalLine(IncomingBatch batch) =>
      '${l10n.totalSizeBatch}: ${FormatUtil.formatBytes(batch.totalBytes)}';

  String statusOf(PendingFileInfo file) {
    if (file.isFailed) return '${l10n.statusFailed}: ${file.errorMessage}';
    if (file.isRejected) return l10n.rejected;
    if (!file.isAccepted) return l10n.waitingForConfirmation;
    if (file.isCompleted) return l10n.receiveComplete;
    if (file.progress > 0) return l10n.receivingProgress(file.progress * 100);
    return l10n.preparingToReceive;
  }
}

class _TvBatchDialog extends StatelessWidget {
  const _TvBatchDialog({required this.view, required this.batch});

  final _BatchView view;
  final IncomingBatch batch;

  @override
  Widget build(BuildContext context) {
    final l10n = view.l10n;
    final senderName = batch.senderDeviceName;
    return TvIncomingDialog(
      title: view.title,
      senderLine: senderName == null || senderName.isEmpty
          ? '${l10n.sender} IP: ${batch.senderKey}'
          : '${l10n.sender}: $senderName',
      totalLine: view.totalLine(batch),
      speedLine: view.speedLine,
      etaLine: view.etaLine,
      countdown: view.countdown,
      statusLine: view.statusLine,
      files: [
        for (final file in batch.files)
          TvIncomingFile(
            name: file.fileName,
            sizeLabel: FormatUtil.formatBytes(file.fileSize),
            progress: file.progress,
            status: view.statusOf(file),
            showProgress: file.isAccepted,
            completed: file.isCompleted,
            failed: file.isFailed || file.isRejected,
          ),
      ],
      showActions: !batch.isDecided,
      acceptLabel: l10n.acceptAll,
      rejectLabel: l10n.rejectAll,
      onAccept: batch.accept,
      onReject: batch.reject,
    );
  }
}

class _PhoneBatchDialog extends StatelessWidget {
  const _PhoneBatchDialog({required this.view, required this.batch});

  final _BatchView view;
  final IncomingBatch batch;

  @override
  Widget build(BuildContext context) {
    final l10n = view.l10n;
    final senderName = batch.senderDeviceName;
    final secondaryStyle = TextStyle(fontSize: 13, color: Colors.grey[700]);
    final size = MediaQuery.sizeOf(context);
    // Fixed bounds: AlertDialog + Flexible/ListView intrinsic sizing blanks out
    // on HarmonyOS the same way the scan dialog did.
    final dialogWidth = (size.width * 0.85).clamp(280.0, 420.0);
    final contentHeight = (size.height * 0.45).clamp(240.0, 380.0);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            batch.isAccepted ? Icons.downloading : Icons.file_download,
            color: batch.isAccepted ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(view.title, style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        height: contentHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (senderName != null && senderName.isNotEmpty) ...[
              Text(
                '${l10n.sender}: $senderName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'IP: ${batch.senderKey}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ] else
              Text('${l10n.sender} IP: ${batch.senderKey}'),
            const SizedBox(height: 8),
            Text(
              view.totalLine(batch),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (view.speedLine != null) ...[
              const SizedBox(height: 6),
              Text(view.speedLine!, style: secondaryStyle),
            ],
            if (view.etaLine != null) ...[
              const SizedBox(height: 2),
              Text(view.etaLine!, style: secondaryStyle),
            ],
            const SizedBox(height: 12),
            Text(
              '${l10n.fileList}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  itemCount: batch.files.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: Colors.grey[300]),
                  itemBuilder: (_, index) {
                    final file = batch.files[index];
                    return _ReceiveFileTile(
                      file: file,
                      status: view.statusOf(file),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PhoneStatusLine(view: view, batch: batch),
          ],
        ),
      ),
      actions: batch.isDecided
          ? null
          : [
              TextButton(onPressed: batch.reject, child: Text(l10n.rejectAll)),
              ElevatedButton(
                onPressed: batch.accept,
                child: Text(l10n.acceptAll),
              ),
            ],
    );
  }
}

class _PhoneStatusLine extends StatelessWidget {
  const _PhoneStatusLine({required this.view, required this.batch});

  final _BatchView view;
  final IncomingBatch batch;

  @override
  Widget build(BuildContext context) {
    final countdown = view.countdown;
    if (countdown != null) {
      return Text(
        countdown,
        style: TextStyle(
          color: view.remainingSeconds <= 10 ? Colors.red : Colors.grey[600],
          fontSize: 12,
        ),
      );
    }

    final status = view.statusLine;
    if (status == null) return const SizedBox.shrink();

    if (batch.isFinished) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            status,
            style: TextStyle(color: Colors.blue[700], fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _ReceiveFileTile extends StatelessWidget {
  const _ReceiveFileTile({required this.file, required this.status});

  final PendingFileInfo file;
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (!file.isAccepted) {
      color = Colors.grey;
    } else if (file.isFailed) {
      color = Colors.red;
    } else if (file.isCompleted) {
      color = Colors.green;
    } else {
      color = Colors.blue;
    }

    return ListTile(
      dense: true,
      leading: Icon(Icons.insert_drive_file, size: 20, color: color),
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
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          if (file.isAccepted) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: file.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 10,
                color: file.isCompleted ? color : Colors.blue[700],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
