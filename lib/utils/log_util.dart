// log_util.dart
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class MyLogPrinter extends LogPrinter {
  final String? logTag;

  MyLogPrinter({this.logTag});

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
    final currentTime = DateTime.now().toString();
    final levelStr = event.level.name.toUpperCase();

    String logMessage = '[$currentTime] [$levelStr]';
    if (logTag != null) {
      logMessage += '[$logTag]';
    }
    logMessage += ' Msg: ${event.message}';
    final color = levelColors[event.level];
    return [color != null ? color(logMessage) : logMessage];
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
        final directory = await getApplicationDocumentsDirectory();
        final logFile = File('${directory.path}/app_log.txt');
        if (!await logFile.exists()) {
          await logFile.create(recursive: true);
        }
        outputs.add(FileOutput(file: logFile));
      } catch (e) {
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
    // return ProductionFilter(); // 注意：这可能导致生产环境日志过多
  }

  // 对外提供的静态日志方法
  static void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.t(message, error: error, stackTrace: stackTrace);
  }

  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.f(message, error: error, stackTrace: stackTrace);
  }

  // 可选：在应用启动时显式初始化（例如，如果需要异步设置路径）
  static Future<void> init() async {
    // 如果_initLogger中有复杂的异步操作，可以在这里确保初始化完成
    // 当前简单情况下，构造函数已处理
  }
}
