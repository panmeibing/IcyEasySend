import 'dart:typed_data';

import '../models/clipboard_data_model.dart';
import '../utils/constants.dart';
import '../utils/log_util.dart';
import 'clipboard_service.dart';
import 'preferences_service.dart';

/// In-memory single-slot clipboard cache for Android background sharing.
///
/// Only text and images are stored. Each update replaces the previous entry
/// so memory never accumulates a history queue.
class ClipboardCacheService {
  ClipboardCacheService._();

  static final ClipboardCacheService instance = ClipboardCacheService._();

  static final String logTag = LogTags.clipboard;

  final ClipboardService _clipboardService = ClipboardService();

  ClipboardDataModel? _entry;
  DateTime? _cachedAt;

  /// Max age before cached content is treated as stale.
  static const Duration maxAge = AppConstants.clipboardCacheMaxAge;

  /// Whether cache exists and has not expired.
  bool get isValid {
    if (_entry == null || _cachedAt == null) return false;
    if (DateTime.now().difference(_cachedAt!) > maxAge) {
      clear();
      return false;
    }
    return true;
  }

  /// Returns the cached entry if still valid, otherwise null.
  ClipboardDataModel? getIfValid() {
    if (!isValid) return null;
    return _entry;
  }

  /// Read system clipboard and update the single cache slot when possible.
  ///
  /// Returns the cached model only when the update succeeds (type/size checks).
  Future<ClipboardDataModel?> refreshFromSystem({
    PreferencesService? preferencesService,
  }) async {
    final live = await _clipboardService.getClipboardContent();
    if (live == null) {
      LogUtil.dTag(logTag, '刷新缓存失败：系统剪切板不可读或为空');
      return null;
    }
    final ok = await update(live, preferencesService: preferencesService);
    return ok ? live : null;
  }

  /// Apply a payload already read natively (overlay focus / transparent Activity).
  ///
  /// Expected map shapes:
  /// - `{ type: 'text', textContent: String }`
  /// - `{ type: 'image', imageData: bytes, fileName?, mimeType? }`
  Future<bool> updateFromNativePayload(
    Map<Object?, Object?>? payload, {
    PreferencesService? preferencesService,
  }) async {
    if (payload == null) {
      LogUtil.dTag(logTag, '原生剪切板载荷为空');
      return false;
    }

    final type = payload['type'] as String?;
    if (type == 'text') {
      final text = (payload['textContent'] as String?)?.trim();
      if (text == null || text.isEmpty) return false;
      return update(
        ClipboardDataModel(
          type: ClipboardDataType.text,
          textContent: text,
        ),
        preferencesService: preferencesService,
      );
    }

    if (type == 'image') {
      final bytes = _toUint8List(payload['imageData']);
      if (bytes == null || bytes.isEmpty) return false;
      final mimeType = payload['mimeType'] as String? ?? 'image/png';
      final fileName = payload['fileName'] as String? ?? 'clipboard_image.png';
      return update(
        ClipboardDataModel(
          type: ClipboardDataType.file,
          fileData: bytes,
          fileName: fileName,
          mimeType: mimeType,
        ),
        preferencesService: preferencesService,
      );
    }

    LogUtil.dTag(logTag, '未知原生剪切板载荷类型: $type');
    return false;
  }

  Uint8List? _toUint8List(Object? data) {
    if (data is Uint8List) return data;
    if (data is List) {
      return Uint8List.fromList(data.cast<int>());
    }
    return null;
  }

  /// Content to share with peers: prefer live read, fall back to cache when
  /// [allowCacheFallback] is true (typically while backgrounded).
  Future<ClipboardShareResult> getContentForSharing({
    required bool allowCacheFallback,
    PreferencesService? preferencesService,
  }) async {
    final live = await _clipboardService.getClipboardContent();
    if (live != null) {
      await update(live, preferencesService: preferencesService);
      return ClipboardShareResult(data: live, fromCache: false);
    }

    if (allowCacheFallback) {
      final cached = getIfValid();
      if (cached != null) {
        LogUtil.iTag(logTag, '使用剪切板缓存分享: ${cached.typeDescription}');
        return ClipboardShareResult(data: cached, fromCache: true);
      }
      return const ClipboardShareResult(
        data: null,
        fromCache: false,
        cacheMissInBackground: true,
      );
    }

    return const ClipboardShareResult(data: null, fromCache: false);
  }

  /// Replace the single cache slot after filtering type and size.
  Future<bool> update(
    ClipboardDataModel data, {
    PreferencesService? preferencesService,
  }) async {
    if (!_isCacheable(data)) {
      LogUtil.dTag(logTag, '跳过缓存：类型不支持 (${data.typeDescription})');
      return false;
    }

    final prefs = preferencesService ?? PreferencesService();
    final maxSizeMB = await prefs.getMaxClipboardSize();
    if (data.sizeInMB > maxSizeMB) {
      LogUtil.wTag(
        logTag,
        '跳过缓存：内容过大 ${data.sizeInMB.toStringAsFixed(2)} MB > $maxSizeMB MB',
      );
      return false;
    }

    _entry = data;
    _cachedAt = DateTime.now();
    LogUtil.iTag(
      logTag,
      '剪切板缓存已更新: ${data.typeDescription}, '
      '${data.sizeInMB.toStringAsFixed(2)} MB',
    );
    return true;
  }

  /// Clear the single cache slot.
  void clear() {
    if (_entry == null && _cachedAt == null) return;
    _entry = null;
    _cachedAt = null;
    LogUtil.iTag(logTag, '剪切板缓存已清空');
  }

  bool _isCacheable(ClipboardDataModel data) {
    if (data.type == ClipboardDataType.text) {
      return data.textContent != null && data.textContent!.isNotEmpty;
    }
    if (data.type == ClipboardDataType.file && data.isImage) {
      return data.fileData != null && data.fileData!.isNotEmpty;
    }
    return false;
  }
}

/// Result of resolving clipboard content for peer sharing.
class ClipboardShareResult {
  final ClipboardDataModel? data;
  final bool fromCache;

  /// Live read failed while backgrounded and no usable cache.
  final bool cacheMissInBackground;

  const ClipboardShareResult({
    required this.data,
    required this.fromCache,
    this.cacheMissInBackground = false,
  });
}
