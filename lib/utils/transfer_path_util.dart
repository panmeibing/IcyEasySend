import 'package:path/path.dart' as path;

/// Helpers for folder-aware transfer paths.
class TransferPathUtil {
  TransferPathUtil._();

  /// Normalize to forward slashes for transfer protocol.
  static String normalizeTransferPath(String transferPath) {
    return transferPath.replaceAll('\\', '/');
  }

  /// Reject path traversal and empty segments; returns OS-specific relative path.
  static String? sanitizeRelativePath(String transferPath) {
    final normalized = normalizeTransferPath(transferPath.trim());
    if (normalized.isEmpty) {
      return null;
    }

    final segments = normalized
        .split('/')
        .where((segment) => segment.isNotEmpty && segment != '.')
        .toList();

    if (segments.isEmpty || segments.any((segment) => segment == '..')) {
      return null;
    }

    return path.joinAll(segments);
  }
}
