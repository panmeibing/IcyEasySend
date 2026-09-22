import 'package:flutter/material.dart';

import '../models/clipboard_data_model.dart';
import '../services/clipboard_cache_service.dart';
import '../services/native_clipboard_service.dart';
import '../services/preferences_service.dart';
import 'log_util.dart';
import 'ohos_platform.dart';

/// HarmonyOS clipboard share helpers shared by LAN and relay paths.
///
/// With ACL + runtime grant for `READ_PASTEBOARD`, silent pasteboard reads
/// may work (especially PC/2in1). On phones or when the grant fails, fall
/// back to the paste-to-share dialog (system paste into a focused TextField).
class OhosClipboardShare {
  OhosClipboardShare._();

  static final String _logTag = LogTags.clipboard;

  /// Resolve clipboard content for peer sharing (LAN HTTP or relay).
  ///
  /// On HarmonyOS: try silent read after ensuring pasteboard permission;
  /// otherwise show paste dialog (cache may prefill the field).
  /// Secret-key auto-accept only skips allow/deny — content capture still runs.
  /// Elsewhere: live system clipboard, optionally falling back to cache.
  static Future<ClipboardDataModel?> resolveForPeerShare({
    required BuildContext? context,
    required Future<ClipboardDataModel?> Function() readLive,
    bool allowCacheFallback = true,
    PreferencesService? preferencesService,
  }) async {
    if (isOhosPlatform) {
      final silent = await _trySilentRead(
        preferencesService: preferencesService,
      );
      if (silent != null) {
        return silent;
      }

      final cached = allowCacheFallback
          ? ClipboardCacheService.instance.getIfValid()
          : null;
      return resolveContent(
        context: context,
        live: null,
        preferencesService: preferencesService,
        initialText: cached?.type == ClipboardDataType.text
            ? cached!.textContent
            : null,
      );
    }

    final live = await readLive();
    if (live != null) {
      await ClipboardCacheService.instance.update(
        live,
        preferencesService: preferencesService,
      );
      return live;
    }

    if (allowCacheFallback) {
      return ClipboardCacheService.instance.getIfValid();
    }
    return null;
  }

  /// Request/check `READ_PASTEBOARD`, then read text from the system pasteboard.
  static Future<ClipboardDataModel?> _trySilentRead({
    PreferencesService? preferencesService,
  }) async {
    final granted =
        await NativeClipboardService.ensureOhosReadPasteboardPermission();
    if (!granted) {
      LogUtil.iTag(_logTag, '鸿蒙未授予 READ_PASTEBOARD，改用粘贴分享');
      return null;
    }

    try {
      final text = await NativeClipboardService.getTextFromClipboard();
      if (text == null || text.isEmpty) {
        LogUtil.iTag(_logTag, '鸿蒙静默读剪切板为空，改用粘贴分享');
        return null;
      }

      final model = ClipboardDataModel(
        type: ClipboardDataType.text,
        textContent: text,
      );
      await ClipboardCacheService.instance.update(
        model,
        preferencesService: preferencesService,
      );
      LogUtil.iTag(_logTag, '鸿蒙静默读剪切板成功，长度: ${text.length}');
      return model;
    } catch (e, stackTrace) {
      LogUtil.wTag(_logTag, '鸿蒙静默读剪切板失败，改用粘贴分享: $e', e, stackTrace);
      return null;
    }
  }

  /// Shows the paste-to-share dialog and returns trimmed text, or null.
  static Future<String?> showPasteDialog(
    BuildContext context, {
    String? initialText,
  }) async {
    if (!context.mounted) return null;

    // Shelf / WebSocket handlers need a fresh frame before showDialog.
    await Future<void>.delayed(Duration.zero);
    if (!context.mounted) return null;

    final isZh = Localizations.localeOf(context).languageCode.startsWith('zh');
    try {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => _OhosPasteToShareDialog(
          isZh: isZh,
          initialText: initialText,
        ),
      );
      final text = result?.trim();
      if (text == null || text.isEmpty) return null;
      return text;
    } catch (e, stackTrace) {
      LogUtil.eTag(_logTag, '显示鸿蒙粘贴分享对话框失败: $e', e, stackTrace);
      return null;
    }
  }

  /// Prompt the user to paste (and optionally prefill from cache).
  static Future<ClipboardDataModel?> resolveContent({
    required BuildContext? context,
    required ClipboardDataModel? live,
    PreferencesService? preferencesService,
    String? initialText,
  }) async {
    if (live != null || !isOhosPlatform) return live;
    if (context == null || !context.mounted) return null;

    LogUtil.iTag(_logTag, '鸿蒙粘贴分享剪切板');
    final pasted = await showPasteDialog(context, initialText: initialText);
    if (pasted == null || pasted.isEmpty) return null;

    final model = ClipboardDataModel(
      type: ClipboardDataType.text,
      textContent: pasted,
    );
    await ClipboardCacheService.instance.update(
      model,
      preferencesService: preferencesService,
    );
    return model;
  }
}

/// Owns its [TextEditingController] so dispose happens after the TextField
/// unmounts — disposing from the caller caused `_dependents.isEmpty` asserts.
class _OhosPasteToShareDialog extends StatefulWidget {
  final bool isZh;
  final String? initialText;

  const _OhosPasteToShareDialog({
    required this.isZh,
    this.initialText,
  });

  @override
  State<_OhosPasteToShareDialog> createState() =>
      _OhosPasteToShareDialogState();
}

class _OhosPasteToShareDialogState extends State<_OhosPasteToShareDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = widget.isZh;
    final title = isZh ? '粘贴以分享剪切板' : 'Paste to share clipboard';
    final hint = isZh
        ? '未能静默读取剪切板时，请长按输入框粘贴要分享的内容，然后点确定。'
        : 'If silent clipboard read is unavailable, long-press the field to paste, then confirm.';
    final confirm = isZh ? '确定' : 'Share';
    final cancel = isZh ? '取消' : 'Cancel';

    return AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 18)),
      content: SizedBox(
        width: (MediaQuery.sizeOf(context).width * 0.85).clamp(280.0, 420.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hint, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 6,
              minLines: 3,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: isZh ? '在此粘贴文本…' : 'Paste text here…',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(confirm),
        ),
      ],
    );
  }
}
