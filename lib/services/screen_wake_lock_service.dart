import 'package:wakelock_plus/wakelock_plus.dart';

import '../utils/log_util.dart';

/// Keeps the screen awake while file transfers are in progress.
///
/// Uses platform window flags only; does not change system auto-lock settings.
class ScreenWakeLockService {
  static final String logTag = LogTags.system;

  static int _holdCount = 0;

  static Future<void> acquire() async {
    _holdCount++;
    if (_holdCount > 1) {
      return;
    }

    try {
      await WakelockPlus.enable();
      LogUtil.iTag(logTag, '已启用传输期间保持亮屏');
    } catch (e, stackTrace) {
      _holdCount = 0;
      LogUtil.wTag(logTag, '启用保持亮屏失败: $e', e, stackTrace);
    }
  }

  static Future<void> release() async {
    if (_holdCount == 0) {
      return;
    }

    _holdCount--;
    if (_holdCount > 0) {
      return;
    }

    try {
      await WakelockPlus.disable();
      LogUtil.iTag(logTag, '已关闭传输期间保持亮屏');
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '关闭保持亮屏失败: $e', e, stackTrace);
    }
  }
}
