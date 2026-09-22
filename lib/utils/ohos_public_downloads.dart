import 'dart:io';

import 'package:flutter/services.dart';

import 'log_util.dart';
import 'ohos_platform.dart';

/// Resolves a user-visible Downloads directory on HarmonyOS NEXT.
///
/// [path_provider_ohos] maps "downloads" to the app sandbox
/// (`…/el2/base/files/downloads`), which File Manager does not list under
/// public 下载. This channel asks native code for:
/// 1. [Environment.getUserDownloadDir] on 2-in-1 / PC when supported
/// 2. otherwise [DocumentViewPicker] DOWNLOAD mode → `Download/<bundle>/`
class OhosPublicDownloads {
  OhosPublicDownloads._();

  static const MethodChannel _channel = MethodChannel(
    'com.icyhope.icy_easy_send/ohos_fs',
  );

  static final String _logTag = LogTags.ui;
  static String? _cachedPath;
  static Future<String?>? _inflight;

  /// Returns a writable public downloads path, or null if unavailable.
  static Future<String?> resolvePath({bool forceRefresh = false}) async {
    if (!isOhosPlatform) return null;

    if (!forceRefresh && _cachedPath != null) {
      return _cachedPath;
    }

    if (!forceRefresh && _inflight != null) {
      return _inflight;
    }

    _inflight = _resolveOnce();
    try {
      final path = await _inflight;
      if (path != null && path.isNotEmpty) {
        _cachedPath = path;
      }
      return path;
    } finally {
      _inflight = null;
    }
  }

  static Future<String?> _resolveOnce() async {
    try {
      final result = await _channel.invokeMethod<String>(
        'getPublicDownloadsPath',
      );
      if (result == null || result.isEmpty) {
        LogUtil.wTag(_logTag, '鸿蒙公共下载目录为空');
        return null;
      }

      final dir = Directory(result);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Probe write access; fall back if the path is not usable.
      final probe = File('${dir.path}${Platform.pathSeparator}.icy_write_probe');
      try {
        await probe.writeAsString('ok', flush: true);
        await probe.delete();
      } catch (e, stackTrace) {
        LogUtil.wTag(_logTag, '鸿蒙公共下载目录不可写: $result', e, stackTrace);
        return null;
      }

      LogUtil.iTag(_logTag, '鸿蒙公共下载目录: $result');
      return result;
    } on MissingPluginException {
      LogUtil.wTag(_logTag, '鸿蒙公共下载 MethodChannel 未注册');
      return null;
    } on PlatformException catch (e, stackTrace) {
      LogUtil.wTag(
        _logTag,
        '获取鸿蒙公共下载目录失败: ${e.code} ${e.message}',
        e,
        stackTrace,
      );
      return null;
    } catch (e, stackTrace) {
      LogUtil.wTag(_logTag, '获取鸿蒙公共下载目录异常: $e', e, stackTrace);
      return null;
    }
  }

  /// Clears the in-memory cache (e.g. after storage permission changes).
  static void clearCache() {
    _cachedPath = null;
    _inflight = null;
  }
}
