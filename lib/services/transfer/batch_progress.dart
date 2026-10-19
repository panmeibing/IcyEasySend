/// Overall progress of a batch whose files can drop out part-way.
///
/// A file that ends without arriving takes its unsent remainder out of the
/// total instead of leaving a gap the bar can never close, and what it did
/// send stays counted, so the byte count the rate tracker samples never goes
/// backwards.
class BatchProgress {
  BatchProgress(Map<int, int> sizes)
    : _sizes = Map.of(sizes),
      _total = sizes.values.fold(0, (sum, size) => sum + size);

  final Map<int, int> _sizes;
  final Map<int, int> _sent = {};
  int _total;

  int get totalBytes => _total;

  int get sentBytes => _sent.values.fold(0, (sum, bytes) => sum + bytes);

  double get fraction {
    if (_total <= 0) return 0.0;
    return (sentBytes / _total).clamp(0.0, 1.0);
  }

  /// Ignored once [key] has settled, so a late progress tick cannot move it.
  void update(int key, int bytes) {
    final size = _sizes[key];
    if (size == null) return;
    _sent[key] = bytes.clamp(0, size);
  }

  void settle(int key, {required bool success}) {
    final size = _sizes.remove(key);
    if (size == null) return;
    if (success) {
      _sent[key] = size;
    } else {
      _total -= size - (_sent[key] ?? 0);
    }
  }
}
