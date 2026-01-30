import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// Log label constant
class LogTags {
  static const String server = 'Server';
  static const String transfer = 'Transfer';
  static const String network = 'Network';
  static const String validation = 'Validation';
  static const String permission = 'Permission';
  static const String history = 'History';
  static const String ui = 'UI';
}

class MyLogPrinter extends LogPrinter {
  static const levelColors = {
    Level.trace: AnsiColor.fg(250),
    Level.debug: AnsiColor.none(),
    Level.info: AnsiColor.fg(6),
    Level.warning: AnsiColor.fg(208),
    Level.error: AnsiColor.fg(196),
    Level.fatal: AnsiColor.fg(199),
  };

  @override
  List<String> log(LogEvent event) {
    final currentTime = DateTime.now().toString().substring(0, 23); // 精确到毫秒
    final levelStr = _formatLevel(event.level);

    // 统一格式: [时间] [级别] [标签] 消息
    String logMessage = '[$currentTime] [$levelStr]';

    // 从消息中提取标签（如果存在）
    final message = event.message.toString();
    final tagMatch = RegExp(r'^\[([^\]]+)\]\s*(.*)').firstMatch(message);

    if (tagMatch != null) {
      final tag = tagMatch.group(1)!;
      final actualMessage = tagMatch.group(2)!;
      logMessage += ' [$tag] $actualMessage';
    } else {
      logMessage += ' $message';
    }

    // 如果有错误信息，追加到下一行
    if (event.error != null) {
      logMessage += '\n    ↳ Error: ${event.error}';
    }

    // 如果有堆栈跟踪，追加到后续行
    if (event.stackTrace != null) {
      logMessage += '\n    ↳ StackTrace:\n${event.stackTrace}';
    }

    final color = levelColors[event.level];
    return [color != null ? color(logMessage) : logMessage];
  }

  /// 格式化日志级别，统一宽度
  String _formatLevel(Level level) {
    switch (level) {
      case Level.trace:
        return 'TRACE';
      case Level.debug:
        return 'DEBUG';
      case Level.info:
        return 'INFO ';
      case Level.warning:
        return 'WARN ';
      case Level.error:
        return 'ERROR';
      case Level.fatal:
        return 'FATAL';
      default:
        return level.name.toUpperCase().padRight(5);
    }
  }
}

class LogUtil {
  static final LogUtil _instance = LogUtil._internal();
  late Logger _logger;

  factory LogUtil() {
    return _instance;
  }

  LogUtil._internal() {
    _initLogger();
  }

  Future<void> _initLogger() async {
    List<LogOutput> outputs = [ConsoleOutput()];

    // 如果不是调试模式，则额外添加文件输出（可选，用于持久化重要日志）
    if (!kDebugMode) {
      try {
        final directory = await path_provider.getApplicationDocumentsDirectory();
        final logFile = File('${directory.path}/app_log.txt');
        if (!await logFile.exists()) {
          await logFile.create(recursive: true);
        }
        outputs.add(FileOutput(file: logFile));
      } catch (e) {
        // ignore: avoid_print
        print("Failed to initialize file logging: $e");
      }
    }

    _logger = Logger(
      filter: _getLogFilter(),
      // printer: PrettyPrinter(
      //   methodCount: 1,
      //   // 显示调用方法栈的数量，有助于定位日志来源
      //   errorMethodCount: 8,
      //   // colors: kDebugMode,
      //   colors: false,
      //   printEmojis: false,
      //   dateTimeFormat: DateTimeFormat.dateAndTime,
      //   noBoxingByDefault: false,
      // ),
      // printer: SimplePrinter(printTime: true),
      printer: MyLogPrinter(),
      output: MultiOutput(outputs),
    );

    Logger.level = kDebugMode ? Level.debug : Level.warning;
  }

  LogFilter _getLogFilter() {
    return DevelopmentFilter();
    // Attention: This may result in excessive production environment logs
    // return ProductionFilter();
  }

  // ==================== 基础日志方法 ====================

  /// Trace级别日志（最详细）
  static void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Debug级别日志
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info级别日志
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning级别日志
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error级别日志
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal级别日志（最严重）
  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.f(message, error: error, stackTrace: stackTrace);
  }

  // ==================== 带标签的日志方法 ====================

  /// 带标签的Trace日志
  static void vTag(
    String tag,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _instance._logger.t(
      '[$tag] $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 带标签的Debug日志
  static void dTag(
    String tag,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _instance._logger.d(
      '[$tag] $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 带标签的Info日志
  static void iTag(
    String tag,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _instance._logger.i(
      '[$tag] $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 带标签的Warning日志
  static void wTag(
    String tag,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _instance._logger.w(
      '[$tag] $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 带标签的Error日志
  static void eTag(
    String tag,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _instance._logger.e(
      '[$tag] $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 带标签的Fatal日志
  static void fTag(
    String tag,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _instance._logger.f(
      '[$tag] $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  //Optional: Explicitly initialize at application startup (e.g. if asynchronous path setting is required)
  static Future<void> init() async {
    // If there are complex asynchronous operations in ''initLogger',
    // you can ensure that initialization is complete here
    // In the current simple case, the constructor has been processed
  }
}
