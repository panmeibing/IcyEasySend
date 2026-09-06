import 'dart:io';

import 'operation_result.dart';

/// Recognises "the volume is out of space" among everything else a failed
/// write can mean.
///
/// There is deliberately no free-space pre-flight check on the receive path:
/// the plugin that reports remaining space returns numbers that cannot be
/// trusted, so the write itself is the only reliable signal. That makes this
/// classifier the thing standing between a full disk and a generic
/// "file save failed" the user cannot act on.
class DiskSpaceError {
  const DiskSpaceError._();

  /// Key under which receive paths flag a failure as out-of-space in
  /// [OperationResult.metadata].
  static const String metadataKey = 'diskFull';

  /// `ENOSPC`. Linux, Android, macOS and iOS all use 28 for this.
  static const int _enospc = 28;

  /// `ERROR_HANDLE_DISK_FULL` (39) and `ERROR_DISK_FULL` (112) from the Win32
  /// error table. Dart surfaces the raw Win32 code in [OSError.errorCode].
  static const Set<int> _windowsDiskFull = {39, 112};

  /// Whether [error] is a write that failed because the disk filled up.
  static bool isDiskFull(Object? error) {
    if (error is! FileSystemException) {
      return false;
    }

    final osError = error.osError;
    if (osError != null) {
      if (Platform.isWindows) {
        if (_windowsDiskFull.contains(osError.errorCode)) {
          return true;
        }
      } else if (osError.errorCode == _enospc) {
        return true;
      }
    }

    return _looksLikeDiskFull(osError?.message ?? error.message);
  }

  /// Fallback for the case where no numeric code came through. Windows
  /// localises its error strings, so this can only ever be best-effort — the
  /// error code above is what actually carries the weight.
  static bool _looksLikeDiskFull(String message) {
    final text = message.toLowerCase();
    return text.contains('no space left') ||
        text.contains('not enough space') ||
        text.contains('disk full') ||
        text.contains('disk is full');
  }

  /// Metadata marking a failed [OperationResult] as caused by a full disk.
  static Map<String, dynamic> get metadata => const {metadataKey: true};
}

extension DiskFullResult<T> on OperationResult<T> {
  /// Whether this failure was caused by the disk running out of space, as
  /// opposed to any of the other reasons a save can fail.
  bool get isDiskFull => metadata?[DiskSpaceError.metadataKey] == true;
}
