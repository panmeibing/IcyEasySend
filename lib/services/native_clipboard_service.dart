import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/log_util.dart';
import '../utils/ohos_platform.dart';

/// Image payload read from the platform clipboard.
class NativeClipboardImage {
  final Uint8List bytes;
  final String? fileName;
  final String? mimeType;

  const NativeClipboardImage({
    required this.bytes,
    this.fileName,
    this.mimeType,
  });
}

/// Platform clipboard helpers not covered by super_clipboard.
class NativeClipboardService {
  static const MethodChannel _channel = MethodChannel(
    'com.icyhope.icy_easy_send/clipboard',
  );

  static final String logTag = LogTags.clipboard;

  /// Ensure HarmonyOS `READ_PASTEBOARD` is granted (user_grant / ACL).
  ///
  /// Returns false when unsupported, denied, or the native channel is missing
  /// — callers should fall back to paste-to-share.
  static Future<bool> ensureOhosReadPasteboardPermission() async {
    if (!isOhosPlatform) return false;

    try {
      final granted = await _channel.invokeMethod<bool>(
        'ensureReadPasteboardPermission',
      );
      return granted == true;
    } on MissingPluginException {
      LogUtil.wTag(logTag, '鸿蒙剪切板 MethodChannel 未注册');
      return false;
    } on PlatformException catch (e, stackTrace) {
      LogUtil.wTag(
        logTag,
        '鸿蒙 READ_PASTEBOARD 请求失败: ${e.message}',
        e,
        stackTrace,
      );
      return false;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '鸿蒙 READ_PASTEBOARD 请求异常: $e', e, stackTrace);
      return false;
    }
  }

  /// Read clipboard text using the platform API.
  ///
  /// On Android this uses [ClipData.Item.coerceToText], which can extract text
  /// from HTML-only clips such as those created by system note apps.
  /// On HarmonyOS this uses the pasteboard API after [ensureOhosReadPasteboardPermission].
  static Future<String?> getTextFromClipboard() async {
    if (!Platform.isAndroid && !Platform.isIOS && !isOhosPlatform) {
      return null;
    }

    final channelText = await _readViaMethodChannel();
    if (channelText != null) {
      return channelText;
    }

    if (isOhosPlatform) {
      return null;
    }

    return _readViaFlutterClipboard();
  }

  /// Write plain text via Flutter's platform clipboard channel.
  ///
  /// Used on HarmonyOS where [super_clipboard] / super_native_extensions is
  /// unavailable.
  static Future<bool> setTextToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      LogUtil.iTag(logTag, 'Flutter Clipboard 写入成功，长度: ${text.length}');
      return true;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, 'Flutter Clipboard 写入失败: $e', e, stackTrace);
      return false;
    }
  }

  /// Read image bytes from the platform clipboard.
  static Future<NativeClipboardImage?> getImageFromClipboard() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getImageFromClipboard',
      );
      if (result == null) {
        return null;
      }

      final bytes = _toUint8List(result['imageData']);
      if (bytes == null || bytes.isEmpty) {
        return null;
      }

      final fileName = result['fileName'] as String?;
      final mimeType = result['mimeType'] as String?;

      LogUtil.iTag(
        logTag,
        '原生剪切板图片读取成功，大小: ${bytes.length} bytes'
        '${fileName != null ? ', 文件名: $fileName' : ''}',
      );

      return NativeClipboardImage(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
    } on PlatformException catch (e, stackTrace) {
      LogUtil.wTag(logTag, '原生剪切板图片读取失败: ${e.message}', e, stackTrace);
      return null;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '原生剪切板图片读取异常: $e', e, stackTrace);
      return null;
    }
  }

  static Uint8List? _toUint8List(Object? data) {
    if (data is Uint8List) {
      return data;
    }
    if (data is List) {
      return Uint8List.fromList(data.cast<int>());
    }
    return null;
  }

  static Future<String?> _readViaMethodChannel() async {
    try {
      final text = await _channel.invokeMethod<String>('getTextFromClipboard');
      if (text == null || text.trim().isEmpty) {
        return null;
      }

      LogUtil.iTag(logTag, '原生 MethodChannel 剪切板读取成功，长度: ${text.length}');
      return text.trim();
    } on PlatformException catch (e, stackTrace) {
      LogUtil.wTag(
        logTag,
        '原生 MethodChannel 剪切板读取失败: ${e.message}',
        e,
        stackTrace,
      );
      return null;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '原生 MethodChannel 剪切板读取异常: $e', e, stackTrace);
      return null;
    }
  }

  static Future<String?> _readViaFlutterClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.trim().isEmpty) {
        return null;
      }

      LogUtil.iTag(logTag, 'Flutter Clipboard 读取成功，长度: ${text.length}');
      return text.trim();
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, 'Flutter Clipboard 读取失败: $e', e, stackTrace);
      return null;
    }
  }
}
