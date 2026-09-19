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

  /// Format duration as zero-padded `HH:MM:SS`.
  ///
  /// Examples:
  /// - 00:00:30
  /// - 00:02:05
  /// - 01:15:00
  /// - 26:03:09 (hours are not capped at 24)
  static String formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  /// Localized transfer rate line, e.g. `传输速度: 1.5 MB/s`.
  static String formatTransferSpeedLabel(String label, double bytesPerSecond) {
    return '$label: ${formatSpeed(bytesPerSecond)}';
  }

  /// Localized remaining-time line, e.g. `剩余时间: 00:25:23`.
  static String formatRemainingTimeLabel(String label, Duration duration) {
    return '$label: ${formatDuration(duration)}';
  }

  /// Format full date time for detail view
  ///
  /// Example: 2024-01-15 14:30:45
  static String formatFullDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
