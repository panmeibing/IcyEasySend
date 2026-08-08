import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/log_util.dart';
import 'clipboard_cache_service.dart';
import 'preferences_service.dart';

/// Android clipboard overlay + focus-aware clipboard change listening.
class ClipboardOverlayService {
  ClipboardOverlayService._();

  static final ClipboardOverlayService instance = ClipboardOverlayService._();

  static const MethodChannel _channel = MethodChannel(
    'com.icyhope.icy_easy_send/clipboard',
  );

  static final String logTag = LogTags.clipboard;

  bool _handlerAttached = false;
  bool _listeningForChanges = false;
  bool _refreshInFlight = false;

  /// Wire MethodChannel callbacks once (overlay tap / clip changed).
  void ensureInitialized() {
    if (!Platform.isAndroid || _handlerAttached) return;
    _handlerAttached = true;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onNativeClipboardCaptured':
          // Native already read clipboard (overlay focus or transparent Activity).
          final raw = call.arguments;
          final Map<Object?, Object?>? payload =
              raw is Map ? Map<Object?, Object?>.from(raw) : null;
          final ok = await _applyNativePayload(payload);
          return {'success': ok};
        case 'onClipboardChanged':
          // Only meaningful while app has focus.
          await refreshCache();
          return null;
        default:
          throw MissingPluginException(call.method);
      }
    });
  }

  Future<bool> isOverlayPermissionGranted() async {
    if (!Platform.isAndroid) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('isOverlayPermissionGranted');
      return result ?? false;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '检查悬浮窗权限失败: $e', e, stackTrace);
      return false;
    }
  }

  /// Opens system overlay settings; returns whether permission is granted after.
  Future<bool> requestOverlayPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '请求悬浮窗权限失败: $e', e, stackTrace);
      return false;
    }
  }

  Future<bool> showOverlay() async {
    if (!Platform.isAndroid) return false;
    ensureInitialized();
    try {
      final result = await _channel.invokeMethod<bool>('showClipboardOverlay');
      return result ?? false;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '显示剪切板悬浮窗失败: $e', e, stackTrace);
      return false;
    }
  }

  Future<void> hideOverlay() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('hideClipboardOverlay');
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '隐藏剪切板悬浮窗失败: $e', e, stackTrace);
    }
  }

  Future<void> startClipboardChangeListening() async {
    if (!Platform.isAndroid || _listeningForChanges) return;
    ensureInitialized();
    try {
      await _channel.invokeMethod('startClipboardChangeListening');
      _listeningForChanges = true;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '启动剪切板变更监听失败: $e', e, stackTrace);
    }
  }

  Future<void> stopClipboardChangeListening() async {
    if (!Platform.isAndroid || !_listeningForChanges) return;
    try {
      await _channel.invokeMethod('stopClipboardChangeListening');
      _listeningForChanges = false;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '停止剪切板变更监听失败: $e', e, stackTrace);
    }
  }

  /// Apply clipboard content already read on the native side.
  Future<bool> _applyNativePayload(Map<Object?, Object?>? payload) async {
    if (_refreshInFlight) return ClipboardCacheService.instance.isValid;
    _refreshInFlight = true;
    try {
      final ok =
          await ClipboardCacheService.instance.updateFromNativePayload(payload);
      LogUtil.dTag(
        logTag,
        ok ? '原生剪切板载荷已写入缓存' : '原生剪切板载荷写入缓存失败',
      );
      unawaited(_notifyOverlayRefreshResult(ok));
      return ok;
    } finally {
      _refreshInFlight = false;
    }
  }

  /// Refresh in-memory cache from system clipboard.
  Future<bool> refreshCache() async {
    if (_refreshInFlight) return ClipboardCacheService.instance.isValid;
    _refreshInFlight = true;
    try {
      final data = await ClipboardCacheService.instance.refreshFromSystem();
      final ok = data != null && ClipboardCacheService.instance.isValid;
      if (ok) {
        LogUtil.iTag(logTag, '剪切板缓存刷新成功');
      }
      unawaited(_notifyOverlayRefreshResult(ok));
      return ok;
    } finally {
      _refreshInFlight = false;
    }
  }

  Future<void> _notifyOverlayRefreshResult(bool success) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('overlayRefreshResult', {'success': success});
    } catch (_) {
      // Overlay may not be visible.
    }
  }

  /// Apply preference: show/hide overlay. Clears cache when turning off.
  ///
  /// When enabling without overlay permission, opens system settings and
  /// persists the preference so [restoreOverlayIfEnabled] can show it after
  /// the user returns with permission granted.
  Future<bool> applyOverlayPreference(bool enabled) async {
    if (!Platform.isAndroid) return false;

    if (!enabled) {
      await hideOverlay();
      ClipboardCacheService.instance.clear();
      await PreferencesService().saveClipboardOverlayEnabled(false);
      return true;
    }

    await PreferencesService().saveClipboardOverlayEnabled(true);

    final granted = await isOverlayPermissionGranted();
    if (!granted) {
      await requestOverlayPermission();
      // User must grant in Settings; restore happens on next resume.
      return false;
    }

    final shown = await showOverlay();
    if (shown) {
      await refreshCache();
    }
    return shown;
  }

  /// Restore overlay on app start if preference is on.
  Future<void> restoreOverlayIfEnabled() async {
    if (!Platform.isAndroid) return;
    ensureInitialized();
    final enabled = await PreferencesService().getClipboardOverlayEnabled();
    if (!enabled) return;

    final granted = await isOverlayPermissionGranted();
    if (!granted) {
      LogUtil.wTag(logTag, '悬浮窗偏好已开启但权限未授予，跳过显示');
      return;
    }
    await showOverlay();
  }

  Future<void> dispose() async {
    await stopClipboardChangeListening();
    await hideOverlay();
    ClipboardCacheService.instance.clear();
  }
}
