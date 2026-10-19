import 'dart:async';

import 'package:flutter/widgets.dart';

import '../l10n/current_localizations.dart';
import '../models/incoming_batch.dart';
import '../utils/log_util.dart';
import '../utils/transfer_progress_throttle.dart';
import 'batch_receive_prompter.dart';

export '../models/incoming_batch.dart' show IncomingBatch, PendingFileInfo;

/// Routes receive decisions and progress for incoming batches.
///
/// Shared by the LAN server and the relay, which both identify files by a
/// transfer ID; this class maps those IDs back to the batch on screen.
class BatchReceiveManager {
  static final BatchReceiveManager _instance = BatchReceiveManager._();

  factory BatchReceiveManager() => _instance;

  BatchReceiveManager._({BatchReceivePrompter? prompter})
    : _prompter = prompter;

  /// Fresh instance with its own bookkeeping, for tests.
  @visibleForTesting
  factory BatchReceiveManager.forTesting({BatchReceivePrompter? prompter}) =>
      BatchReceiveManager._(prompter: prompter);

  final BatchReceivePrompter? _prompter;
  final String logTag = LogTags.transfer;

  final Map<String, ({IncomingBatch batch, PendingFileInfo file})>
  _byTransferId = {};
  final TransferProgressThrottle _progressThrottle = TransferProgressThrottle();

  /// Read at call time, so the UI layer can install itself after this
  /// manager was first used.
  BatchReceivePrompter get _activePrompter =>
      _prompter ?? BatchReceivePrompter.instance;

  /// Asks the user about [files] and resolves with the answer.
  ///
  /// The prompt stays up after an accept to show progress; [onComplete] runs
  /// once it has closed, whichever way the batch ended. With [autoAccept]
  /// (secret key) the user is shown progress without being asked.
  Future<bool> requestBatchReceiveConfirmation({
    required BuildContext context,
    required List<PendingFileInfo> files,
    required String senderIP,
    String? senderDeviceName,
    bool autoAccept = false,
    Future<void> Function()? onComplete,
  }) {
    if (files.isEmpty) return Future.value(false);

    final batch = IncomingBatch(
      senderKey: senderIP,
      senderDeviceName: senderDeviceName,
      files: files,
      autoAccept: autoAccept,
    );
    _track(batch);
    unawaited(_present(context, batch, onComplete));
    return batch.decision;
  }

  Future<void> _present(
    BuildContext context,
    IncomingBatch batch,
    Future<void> Function()? onComplete,
  ) async {
    try {
      if (context.mounted) {
        await _activePrompter.present(context, batch);
      }
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '接收确认框异常: $e', e, stackTrace);
    } finally {
      // A prompt that closed without an answer is a refusal.
      batch.reject();
      _untrack(batch);
    }
    await onComplete?.call();
  }

  /// Accepts [files] with no UI at all (background + secret key).
  ///
  /// The batch stays tracked until [clearPendingForSender].
  Future<bool> acceptBatchHeadless({
    required List<PendingFileInfo> files,
    required String senderIP,
  }) async {
    if (files.isEmpty) return false;

    final batch = IncomingBatch(senderKey: senderIP, files: files);
    _track(batch);
    batch.accept();
    return true;
  }

  /// Stops tracking every batch from [senderIP].
  void clearPendingForSender(String senderIP) {
    final batches = _byTransferId.values
        .where((entry) => entry.batch.senderKey == senderIP)
        .map((entry) => entry.batch)
        .toSet();
    batches.forEach(_untrack);
  }

  void updateProgress(
    String transferId,
    double progress,
    int bytesReceived,
    int totalBytes,
  ) {
    final entry = _byTransferId[transferId];
    if (entry == null) return;
    _progressThrottle.maybeEmit(
      key: transferId,
      progress: progress,
      bytesTransferred: bytesReceived,
      totalBytes: totalBytes,
      onEmit: (progress, bytesReceived, _) {
        entry.batch.updateProgress(entry.file, progress, bytesReceived);
      },
    );
  }

  final Map<String, Completer<void>> _stops = {};

  bool isCancelled(String transferId) =>
      _byTransferId[transferId]?.file.isCancelled ?? false;

  /// Completes [stop] when the user cancels [transferId], or immediately if
  /// they already have.
  void bindStop(String transferId, Completer<void> stop) {
    if (isCancelled(transferId)) {
      if (!stop.isCompleted) stop.complete();
      return;
    }
    _stops[transferId] = stop;
  }

  void unbindStop(String transferId) => _stops.remove(transferId);

  /// Stops one file. A transfer that has not started yet is flagged on its
  /// [PendingFileInfo], so the later `/transfer` is refused even after the
  /// prompt has closed. A file that has already ended is left alone: it may
  /// be on disk already, and calling it cancelled would be a lie.
  void cancelTransfer(String transferId) {
    final entry = _byTransferId[transferId];
    if (entry != null &&
        !entry.batch.cancel(entry.file, appText.transferCancelled)) {
      return;
    }
    final stop = _stops.remove(transferId);
    if (stop != null && !stop.isCompleted) stop.complete();
  }

  void cancelBatch(IncomingBatch batch) {
    for (final file in batch.files) {
      if (!file.isCompleted) cancelTransfer(file.transferId);
    }
  }

  void markTransferReceived(String transferId) {
    final entry = _byTransferId[transferId];
    if (entry == null) return;
    _progressThrottle.resetKey(transferId);
    entry.batch.markReceived(entry.file);
  }

  void markTransferFailed(String transferId, String errorMessage) {
    final entry = _byTransferId[transferId];
    if (entry == null) return;
    entry.batch.markFailed(entry.file, errorMessage);
  }

  void _track(IncomingBatch batch) {
    for (final file in batch.files) {
      _byTransferId[file.transferId] = (batch: batch, file: file);
    }
  }

  void _untrack(IncomingBatch batch) {
    for (final file in batch.files) {
      if (identical(_byTransferId[file.transferId]?.batch, batch)) {
        _byTransferId.remove(file.transferId);
      }
      _stops.remove(file.transferId);
      _progressThrottle.resetKey(file.transferId);
    }
  }
}
