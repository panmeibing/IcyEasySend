import 'dart:convert';
import 'dart:io';

import '../../../utils/constants.dart';
import '../../../utils/platform_util.dart';

/// Controller for developer mode features
class DeveloperController {
  /// Get developer information
  Future<String> getDeveloperInfo() async {
    // Get paths
    final downloadDir = await PlatformUtil.getDownloadsDirectory();
    final logPath = await PlatformUtil.getLoggerFilePath();
    final historyPath = await PlatformUtil.getHistoryFilePath();

    // Build developer info report
    String separator = AppConstants.diagInfoSeparator;
    final buffer = StringBuffer();
    buffer.writeln(separator * 3);
    buffer.writeln('开发信息');
    buffer.writeln(separator * 3);
    buffer.writeln();

    buffer.writeln('【下载文件路径】');
    if (downloadDir != null) {
      buffer.writeln(downloadDir.path);
    } else {
      buffer.writeln('无法获取下载路径');
    }
    buffer.writeln();

    buffer.writeln('【日志文件路径】');
    buffer.writeln(logPath);
    buffer.writeln();

    buffer.writeln('【历史文件路径】');
    buffer.writeln(historyPath);
    buffer.writeln();

    buffer.writeln(separator * 3);

    return buffer.toString();
  }

  /// Copy log content (last 50 lines)
  /// Efficiently reads from the end of the file without loading the entire file
  Future<Map<String, dynamic>> copyLogContent(String logPath) async {
    try {
      final logFile = File(logPath);

      if (!await logFile.exists()) {
        return {'success': false, 'message': '日志文件不存在'};
      }

      // Get file size
      final fileSize = await logFile.length();

      if (fileSize == 0) {
        return {'success': false, 'message': '日志文件为空'};
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
        return {'success': false, 'message': '日志文件为空'};
      }

      // Get last 50 lines (or all lines if less than 50)
      final linesToCopy = lines.length > AppConstants.maxReadLogLines
          ? lines.sublist(lines.length - AppConstants.maxReadLogLines)
          : lines;

      final logContent = linesToCopy.join('\n');

      return {
        'success': true,
        'content': logContent,
        'lineCount': linesToCopy.length,
      };
    } catch (e) {
      return {'success': false, 'message': '读取日志文件失败: $e'};
    }
  }
}
