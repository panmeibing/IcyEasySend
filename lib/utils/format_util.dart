import 'package:icy_easy_send/utils/constants.dart';

/// Utility class for formatting data into human-readable strings
class FormatUtil {
  /// Format bytes to human-readable format
  ///
  /// Examples:
  /// - 512 B
  /// - 1.5 KB
  /// - 2.3 MB
  /// - 1.25 GB
  static String formatBytes(int bytes) {
    if (bytes < AppConstants.bytesPerKB) {
      return '$bytes B';
    } else if (bytes < AppConstants.bytesPerMB) {
      return '${(bytes / AppConstants.bytesPerKB).toStringAsFixed(1)} KB';
    } else if (bytes < AppConstants.bytesPerGB) {
      return '${(bytes / (AppConstants.bytesPerMB)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (AppConstants.bytesPerGB)).toStringAsFixed(2)} GB';
    }
  }

  /// Format transfer speed to human-readable format
  ///
  /// Examples:
  /// - 512 B/s
  /// - 1.5 KB/s
  /// - 2.3 MB/s
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < AppConstants.bytesPerKB) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < AppConstants.bytesPerMB) {
      return '${(bytesPerSecond / AppConstants.bytesPerKB).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / AppConstants.bytesPerMB).toStringAsFixed(1)} MB/s';
    }
  }

  /// Format duration to human-readable format
  ///
  /// Examples:
  /// - 30 秒
  /// - 2 分 30 秒
  /// - 1 小时 15 分
  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} 秒';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} 分 ${duration.inSeconds % 60} 秒';
    } else {
      return '${duration.inHours} 小时 ${duration.inMinutes % 60} 分';
    }
  }

  /// Format full date time for detail view
  ///
  /// Example: 2024-01-15 14:30:45
  static String formatFullDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
