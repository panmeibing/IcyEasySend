/// Throttles transfer progress UI updates to reduce rebuild frequency.
///
/// Emits when any of these conditions is met:
/// - First update for a given [key]
/// - Progress reaches 100% ([progress] >= 1.0)
/// - Progress changed by at least [minProgressDelta] (1%)
/// - At least [minInterval] (200ms) elapsed since the last emit
typedef TransferProgressCallback =
    void Function(double progress, int bytesTransferred, int totalBytes);

class TransferProgressThrottle {
  static const Duration minInterval = Duration(milliseconds: 200);
  static const double minProgressDelta = 0.01;

  final Map<Object, _ThrottleEntry> _entries = {};

  void reset() => _entries.clear();

  void resetKey(Object key) => _entries.remove(key);

  bool shouldEmit(Object key, double progress) {
    if (progress >= 1.0) {
      return true;
    }

    final entry = _entries[key];
    if (entry == null) {
      return true;
    }

    if ((progress - entry.progress).abs() >= minProgressDelta) {
      return true;
    }

    return DateTime.now().difference(entry.emittedAt) >= minInterval;
  }

  void markEmitted(Object key, double progress) {
    _entries[key] = _ThrottleEntry(
      progress: progress,
      emittedAt: DateTime.now(),
    );
  }

  /// Invokes [onEmit] only when the throttle allows it.
  bool maybeEmit({
    required Object key,
    required double progress,
    required int bytesTransferred,
    required int totalBytes,
    required TransferProgressCallback onEmit,
  }) {
    if (!shouldEmit(key, progress)) {
      return false;
    }

    onEmit(progress, bytesTransferred, totalBytes);
    markEmitted(key, progress);
    return true;
  }
}

class _ThrottleEntry {
  final double progress;
  final DateTime emittedAt;

  const _ThrottleEntry({
    required this.progress,
    required this.emittedAt,
  });
}
