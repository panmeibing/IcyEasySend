/// Tracks near-realtime transfer speed using ~1s byte deltas.
///
/// Call [onProgress] on every progress tick (even if UI is throttled more
/// frequently). [speed] and [estimatedTimeRemaining] only refresh when at least
/// [sampleInterval] has elapsed since the previous sample.
class TransferRateTracker {
  static const Duration sampleInterval = Duration(seconds: 1);

  double speed = 0.0;
  Duration? estimatedTimeRemaining;

  int? _sampleBytes;
  DateTime? _sampleAt;

  void reset() {
    speed = 0.0;
    estimatedTimeRemaining = null;
    _sampleBytes = null;
    _sampleAt = null;
  }

  /// Updates displayed rate when a full sample window has elapsed.
  ///
  /// Returns `true` when [speed] / [estimatedTimeRemaining] changed.
  bool onProgress({
    required int bytesTransferred,
    required int totalBytes,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();

    if (_sampleAt == null || _sampleBytes == null) {
      _sampleAt = at;
      _sampleBytes = bytesTransferred;
      return false;
    }

    final elapsed = at.difference(_sampleAt!);
    if (elapsed < sampleInterval) {
      return false;
    }

    final seconds = elapsed.inMilliseconds / 1000.0;
    if (seconds <= 0) {
      return false;
    }

    final deltaBytes = bytesTransferred - _sampleBytes!;
    final nextSpeed = deltaBytes / seconds;
    speed = nextSpeed < 0 ? 0.0 : nextSpeed;

    if (speed > 0 && totalBytes > bytesTransferred) {
      final remainingBytes = totalBytes - bytesTransferred;
      estimatedTimeRemaining = Duration(
        seconds: (remainingBytes / speed).ceil(),
      );
    } else if (totalBytes <= bytesTransferred) {
      estimatedTimeRemaining = Duration.zero;
    } else {
      estimatedTimeRemaining = null;
    }

    _sampleAt = at;
    _sampleBytes = bytesTransferred;
    return true;
  }
}
