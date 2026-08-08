import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../utils/error_messages.dart';
import '../utils/log_util.dart';

/// Top-level callback required by [FlutterForegroundTask.startService].
@pragma('vm:entry-point')
void androidForegroundTaskStartCallback() {
  FlutterForegroundTask.setTaskHandler(_KeepAliveTaskHandler());
}

/// Minimal task handler — keeps the process elevated; HTTP stays on the main isolate.
class _KeepAliveTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Android-only foreground service wrapper to keep the LAN HTTP server alive
/// while the app is backgrounded.
class AndroidForegroundService {
  AndroidForegroundService._();

  static final String logTag = LogTags.system;
  static bool _initialized = false;

  /// Call once from [main] before [runApp] (Android only).
  static void initCommunicationPort() {
    if (!Platform.isAndroid) return;
    FlutterForegroundTask.initCommunicationPort();
  }

  /// Initialize notification channel / task options. Safe to call multiple times.
  static Future<void> ensureInitialized() async {
    if (!Platform.isAndroid || _initialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'icy_easy_send_foreground',
        channelName: ErrorMessages.foregroundServiceChannelName,
        channelDescription: ErrorMessages.foregroundServiceChannelDescription,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // No periodic work needed; FGS only elevates process priority.
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _initialized = true;
    LogUtil.iTag(logTag, 'Android 前台服务已初始化');
  }

  /// Request notification permission required to show the FGS notification.
  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    final permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission == NotificationPermission.granted) {
      return true;
    }

    final result = await FlutterForegroundTask.requestNotificationPermission();
    return result == NotificationPermission.granted;
  }

  /// Start (or restart) the foreground service while the HTTP server is running.
  static Future<bool> start() async {
    if (!Platform.isAndroid) return false;

    try {
      await ensureInitialized();
      await requestNotificationPermission();

      final ServiceRequestResult result;
      if (await FlutterForegroundTask.isRunningService) {
        result = await FlutterForegroundTask.restartService();
      } else {
        result = await FlutterForegroundTask.startService(
          serviceId: 9527,
          notificationTitle: ErrorMessages.foregroundServiceNotificationTitle,
          notificationText: ErrorMessages.foregroundServiceNotificationText,
          serviceTypes: [ForegroundServiceTypes.connectedDevice],
          callback: androidForegroundTaskStartCallback,
        );
      }

      if (result is ServiceRequestSuccess) {
        LogUtil.iTag(logTag, 'Android 前台服务已启动');
        return true;
      }

      LogUtil.wTag(logTag, 'Android 前台服务启动失败: $result');
      return false;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, 'Android 前台服务启动异常: $e', e, stackTrace);
      return false;
    }
  }

  /// Stop the foreground service when the HTTP server stops.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
        LogUtil.iTag(logTag, 'Android 前台服务已停止');
      }
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, 'Android 前台服务停止异常: $e', e, stackTrace);
    }
  }
}
