import 'dart:convert';
import 'dart:io';

import '../../../l10n/app_localizations.dart';
import '../../../utils/constants.dart';
import '../../../utils/platform_util.dart';

enum LogCopyFailure { notFound, empty, readFailed }

/// The tail of the log file, or why it could not be read.
class LogCopyResult {
  const LogCopyResult.success(String this.content, this.lineCount)
    : failure = null,
      error = null;

  const LogCopyResult.failure(LogCopyFailure this.failure, {this.error})
    : content = null,
      lineCount = 0;

  final String? content;
  final int lineCount;
  final LogCopyFailure? failure;

  /// The exception text, for [LogCopyFailure.readFailed].
  final String? error;
}

/// Controller for developer mode features
class DeveloperController {
  /// Get developer information
  Future<String> getDeveloperInfo(AppLocalizations l10n) async {
    // Get paths
    final downloadDir = await PlatformUtil.getReceiveSaveDirectory();
    final logPath = await PlatformUtil.getLoggerFilePath();
    final historyPath = await PlatformUtil.getHistoryFilePath();

    // Build developer info report
    String separator = AppConstants.diagInfoSeparator;
    final buffer = StringBuffer();
    buffer.writeln(separator * 3);
    buffer.writeln(l10n.devInfo);
    buffer.writeln(separator * 3);
    buffer.writeln();

    buffer.writeln(l10n.devInfoSavePath);
    if (downloadDir != null) {
      buffer.writeln(downloadDir.path);
    } else {
      buffer.writeln(l10n.savePathUnavailable);
    }
    buffer.writeln();

    buffer.writeln(l10n.devInfoLogPath);
    buffer.writeln(logPath);
    buffer.writeln();

    buffer.writeln(l10n.devInfoHistoryPath);
    buffer.writeln(historyPath);
    buffer.writeln();

    buffer.writeln(separator * 3);

    return buffer.toString();
  }

  /// Copy log content (last 50 lines)
  /// Efficiently reads from the end of the file without loading the entire file
  Future<LogCopyResult> copyLogContent(String logPath) async {
    try {
      final logFile = File(logPath);

      if (!await logFile.exists()) {
        return const LogCopyResult.failure(LogCopyFailure.notFound);
      }

      // Get file size
      final fileSize = await logFile.length();

      if (fileSize == 0) {
        return const LogCopyResult.failure(LogCopyFailure.empty);
      }

      // Read from the end of file
      // Estimate: average line length ~100 bytes, so read last 8KB to ensure we get 50+ lines
      final bytesToRead = fileSize < 8192 ? fileSize : 8192;
      final startPosition = fileSize - bytesToRead;

      final randomAccessFile = await logFile.open(mode: FileMode.read);
      await randomAccessFile.setPosition(startPosition);
      final bytes = await randomAccessFile.read(bytesToRead);
      await randomAccessFile.close();

      // Decode bytes to string
      final content = utf8.decode(bytes, allowMalformed: true);
      final lines = content.split('\n');

      // Remove first incomplete line if we didn't start from beginning
      if (startPosition > 0 && lines.isNotEmpty) {
        lines.removeAt(0);
      }

      // Remove last empty line if exists
      if (lines.isNotEmpty && lines.last.trim().isEmpty) {
        lines.removeLast();
      }

      if (lines.isEmpty) {
        return const LogCopyResult.failure(LogCopyFailure.empty);
      }

      // Get last 50 lines (or all lines if less than 50)
      final linesToCopy = lines.length > AppConstants.maxReadLogLines
          ? lines.sublist(lines.length - AppConstants.maxReadLogLines)
          : lines;

      final logContent = linesToCopy.join('\n');

      return LogCopyResult.success(logContent, linesToCopy.length);
    } catch (e) {
      return LogCopyResult.failure(LogCopyFailure.readFailed, error: '$e');
    }
  }
}
