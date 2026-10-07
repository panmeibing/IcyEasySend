import 'dart:async';

import 'package:flutter/foundation.dart';

/// One file of an [IncomingBatch].
///
/// Holds facts only; the words describing them are chosen by whichever UI
/// shows the file, in whatever language it is showing.
class PendingFileInfo {
  final String fileName;
  final int fileSize;
  final String transferId;

  double progress = 0.0;
  int bytesReceived = 0;
  bool isAccepted = false;

  /// Finished one way or another: received, failed or rejected.
  bool isCompleted = false;

  /// Why the file failed, or null if it has not.
  String? errorMessage;

  PendingFileInfo({
    required this.fileName,
    required this.fileSize,
    required this.transferId,
  });

  bool get isFailed => errorMessage != null;

  bool get isRejected => isCompleted && !isAccepted;

  bool get isReceived => isCompleted && isAccepted && !isFailed;
}

/// A set of files a peer asked to send, from the user's decision through to
/// the last byte.
///
/// The service layer drives it; a receive prompt listens to it.
class IncomingBatch extends ChangeNotifier {
  IncomingBatch({
    required this.senderKey,
    required List<PendingFileInfo> files,
    this.senderDeviceName,
    this.autoAccept = false,
  }) : files = List.unmodifiable(files);

  /// Address or relay label the batch came from.
  final String senderKey;
  final String? senderDeviceName;
  final List<PendingFileInfo> files;

  /// Already authorised (secret key), so the prompt only shows progress.
  final bool autoAccept;

  final Completer<bool> _decision = Completer<bool>();
  bool _accepted = false;

  /// Completes with the user's answer, exactly once.
  Future<bool> get decision => _decision.future;

  bool get isDecided => _decision.isCompleted;

  bool get isAccepted => _accepted;

  /// Every file has reached a final state.
  bool get isFinished => files.every((f) => f.isCompleted);

  int get totalBytes => files.fold(0, (sum, f) => sum + f.fileSize);

  int get bytesReceived => files.fold(0, (sum, f) => sum + f.bytesReceived);

  void accept() {
    if (isDecided) return;
    _accepted = true;
    for (final file in files) {
      file.isAccepted = true;
    }
    _decision.complete(true);
    notifyListeners();
  }

  /// Declines every file still outstanding. A no-op once decided.
  void reject() {
    if (isDecided) return;
    for (final file in files) {
      if (!file.isCompleted) {
        file.isAccepted = false;
        file.isCompleted = true;
      }
    }
    _decision.complete(false);
    notifyListeners();
  }

  void updateProgress(PendingFileInfo file, double progress, int bytes) {
    file.progress = progress;
    file.bytesReceived = bytes;
    if (progress >= 1.0) {
      file.isCompleted = true;
    }
    notifyListeners();
  }

  void markFailed(PendingFileInfo file, String errorMessage) {
    file.progress = 0.0;
    file.errorMessage = errorMessage;
    file.isCompleted = true;
    // Nothing left to decide about: the sender gave up before the user
    // answered, so the prompt should not keep asking.
    if (!isDecided && isFinished) {
      _decision.complete(false);
    }
    notifyListeners();
  }
}
