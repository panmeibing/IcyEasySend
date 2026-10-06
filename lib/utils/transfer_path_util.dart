import 'dart:io' show Platform;

import 'package:path/path.dart' as path;

/// Helpers for folder-aware transfer paths.
class TransferPathUtil {
  TransferPathUtil._();

  static final RegExp _controlChars = RegExp(r'[\x00-\x1f]');
  static final RegExp _windowsIllegalChars = RegExp(r'[<>:"|?*]');
  static final RegExp _windowsTrailing = RegExp(r'[. ]+$');
  static const Set<String> _windowsReservedNames = {
    'CON',
    'PRN',
    'AUX',
    'NUL',
    'COM1',
    'COM2',
    'COM3',
    'COM4',
    'COM5',
    'COM6',
    'COM7',
    'COM8',
    'COM9',
    'LPT1',
    'LPT2',
    'LPT3',
    'LPT4',
    'LPT5',
    'LPT6',
    'LPT7',
    'LPT8',
    'LPT9',
  };

  /// Normalize to forward slashes for transfer protocol.
  static String normalizeTransferPath(String transferPath) {
    return transferPath.replaceAll('\\', '/');
  }

  /// Turns a peer-supplied transfer path into a relative path that cannot
  /// leave the directory it is joined onto, or null if that is impossible.
  ///
  /// On Windows a segment such as `C:` would make [path.join] discard the
  /// save directory entirely, so characters Windows gives meaning to are
  /// replaced rather than passed through. [windows] exists for tests.
  static String? sanitizeRelativePath(String transferPath, {bool? windows}) {
    final isWindows = windows ?? Platform.isWindows;
    final normalized = normalizeTransferPath(transferPath.trim());
    if (normalized.isEmpty || _controlChars.hasMatch(normalized)) {
      return null;
    }

    final segments = <String>[];
    for (final raw in normalized.split('/')) {
      if (raw.isEmpty || raw == '.') continue;
      if (raw == '..') return null;

      final segment = isWindows ? _sanitizeWindowsSegment(raw) : raw;
      if (segment == null) return null;
      segments.add(segment);
    }

    if (segments.isEmpty) {
      return null;
    }

    final context = isWindows ? path.windows : path.posix;
    return context.joinAll(segments);
  }

  static String? _sanitizeWindowsSegment(String segment) {
    var result = segment
        .replaceAll(_windowsIllegalChars, '_')
        .replaceAll(_windowsTrailing, '');
    if (result.isEmpty) {
      return null;
    }

    final stem = result.split('.').first.toUpperCase();
    if (_windowsReservedNames.contains(stem)) {
      result = '_$result';
    }
    return result;
  }
}
