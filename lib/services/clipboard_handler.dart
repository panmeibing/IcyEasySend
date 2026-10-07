import 'package:flutter/widgets.dart';
import 'package:shelf/shelf.dart';

import '../l10n/current_localizations.dart';
import '../models/clipboard_data_model.dart';
import '../utils/log_util.dart';
import '../utils/ohos_clipboard_share.dart';
import '../utils/ohos_platform.dart';
import '../utils/peer_error.dart';
import '../utils/server_http_util.dart';
import 'clipboard_cache_service.dart';
import 'clipboard_request_prompter.dart';
import 'preferences_service.dart';
import 'secret_key_verifier.dart';
import 'user_notifier.dart';

/// 剪切板请求处理器
///
/// 处理来自其他设备的剪切板请求
class ClipboardHandler {
  final BuildContext? Function()? contextGetter;
  final bool Function()? isInBackgroundGetter;
  final PreferencesService _preferencesService;
  final SecretKeyVerifier _secretKeyVerifier;
  final ClipboardRequestPrompter? _prompter;
  final String logTag = LogTags.clipboard;

  ClipboardHandler({
    this.contextGetter,
    this.isInBackgroundGetter,
    PreferencesService? preferencesService,
    SecretKeyVerifier? secretKeyVerifier,
    ClipboardRequestPrompter? prompter,
  }) : _preferencesService = preferencesService ?? PreferencesService(),
       _secretKeyVerifier = secretKeyVerifier ?? SecretKeyVerifier.instance,
       _prompter = prompter;

  bool get _isInBackground => isInBackgroundGetter?.call() ?? false;

  /// Read at call time, so the UI layer can install itself after this
  /// handler was built.
  ClipboardRequestPrompter get _activePrompter =>
      _prompter ?? ClipboardRequestPrompter.instance;

  /// 处理 POST /clipboard-request 请求
  ///
  /// 当其他设备请求本设备的剪切板内容时，会弹出确认对话框
  /// 用户同意后返回剪切板内容
  ///
  /// 请求体格式:
  /// {
  ///   "requesterDeviceName": "设备名称",
  ///   "timestamp": "2024-01-01T00:00:00.000Z"
  /// }
  ///
  /// 响应格式:
  /// {
  ///   "accepted": true/false,
  ///   "message": "消息"
  ///   "clipboardData": 响应成功携带的剪切板数据,
  ///   "actualSizeMB": 文件过大的时候返回文件的实际大小,
  ///   "maxSizeMB": 文件过大的时候返回设备限制文件的大小,
  /// }
  Future<Response> handleClipboardRequest(Request request) async {
    LogUtil.iTag(logTag, '收到剪切板请求: /clipboard-request');

    try {
      final Object? body;
      try {
        body = await ServerHttpUtil.readJson(request);
      } on RequestBodyTooLargeException {
        return _reject(PeerError.badRequest, status: 413);
      } on FormatException {
        LogUtil.wTag(logTag, '无效的JSON格式');
        return _reject(PeerError.badRequest, status: 400);
      }
      if (body is! Map) {
        return _reject(PeerError.badRequest, status: 400);
      }

      final rawName = body['requesterDeviceName'];
      final requesterDeviceName = rawName is String && rawName.isNotEmpty
          ? rawName
          : ServerHttpUtil.remoteAddress(request) ?? '?';
      final secretKey = request.headers['x-secret-key'];

      LogUtil.dTag(
        logTag,
        '请求设备: $requesterDeviceName, 秘钥=${secretKey != null ? "已提供" : "未提供"}, 后台=$_isInBackground',
      );

      final skipConfirmation = await _secretKeyVerifier.verify(
        secretKey,
        remoteAddress: ServerHttpUtil.remoteAddress(request),
      );

      bool userAccepted;
      if (skipConfirmation) {
        LogUtil.iTag(logTag, '秘钥验证通过，跳过确认对话框');
        // On HarmonyOS the toast waits until content is actually resolved.
        // Paste-to-share can still run after a secret-key auto-accept.
        final ctx = contextGetter?.call();
        if (!isOhosPlatform && !_isInBackground && ctx != null && ctx.mounted) {
          UserNotifier.instance.showSuccess(
            ctx,
            appText.clipboardSharedWithSecretKey(requesterDeviceName),
          );
        }
        userAccepted = true;
      } else if (_isInBackground) {
        // HarmonyOS can report "background" while a mounted UI is still visible.
        final ctx = contextGetter?.call();
        if (ctx != null && ctx.mounted) {
          LogUtil.wTag(logTag, '生命周期标记为后台，但 UI 上下文可用，仍弹出剪切板确认');
          userAccepted = await _activePrompter.confirm(
            ctx,
            requesterDeviceName: requesterDeviceName,
          );
        } else {
          LogUtil.iTag(logTag, '应用在后台且无有效秘钥，拒绝剪切板请求');
          return _reject(PeerError.backgroundNeedsSecretKey);
        }
      } else {
        final ctx = contextGetter?.call();
        if (ctx == null || !ctx.mounted) {
          LogUtil.eTag(logTag, '无法显示确认对话框：缺少上下文');
          return _reject(PeerError.noUi, status: 500);
        }
        userAccepted = await _activePrompter.confirm(
          ctx,
          requesterDeviceName: requesterDeviceName,
        );
      }

      if (!userAccepted) {
        LogUtil.iTag(logTag, '用户拒绝了剪切板请求');
        return _reject(PeerError.clipboardDeclined);
      }

      // 用户同意，获取剪切板内容（后台可回退到单槽缓存）。
      // HarmonyOS uses one resolver for LAN and relay: silent read, then paste dialog.
      final ClipboardDataModel? clipboardData;
      var cacheMissInBackground = false;
      var fromCache = false;
      if (isOhosPlatform) {
        clipboardData = await OhosClipboardShare.resolveForPeerShare(
          context: contextGetter?.call(),
          allowCacheFallback: true,
          preferencesService: _preferencesService,
          readLive: () => ClipboardCacheService.instance.refreshFromSystem(
            preferencesService: _preferencesService,
          ),
        );
        cacheMissInBackground = _isInBackground && clipboardData == null;
      } else {
        final shareResult = await ClipboardCacheService.instance
            .getContentForSharing(
              allowCacheFallback: _isInBackground,
              preferencesService: _preferencesService,
            );
        clipboardData = shareResult.data;
        cacheMissInBackground = shareResult.cacheMissInBackground;
        fromCache = shareResult.fromCache;
      }

      if (clipboardData == null) {
        if (cacheMissInBackground) {
          LogUtil.wTag(logTag, '后台无可用剪切板缓存');
          return _reject(PeerError.clipboardUnavailableInBackground);
        }
        LogUtil.wTag(logTag, '剪切板为空，无法分享');
        return _reject(PeerError.clipboardEmpty);
      }

      if (isOhosPlatform && skipConfirmation) {
        final currentCtx = contextGetter?.call();
        if (currentCtx != null && currentCtx.mounted) {
          UserNotifier.instance.showSuccess(
            currentCtx,
            appText.clipboardSharedWithSecretKey(requesterDeviceName),
          );
        }
      } else if (fromCache) {
        LogUtil.iTag(logTag, '使用缓存剪切板内容分享');
      }

      final contentSizeMB = clipboardData.sizeInMB;
      final maxSizeMB = await _preferencesService.getMaxClipboardSize();

      LogUtil.dTag(
        logTag,
        '剪切板内容: ${clipboardData.typeDescription}, 大小: ${contentSizeMB.toStringAsFixed(2)} MB, 限制: $maxSizeMB MB',
      );

      if (contentSizeMB > maxSizeMB) {
        LogUtil.wTag(
          logTag,
          '剪切板内容过大: ${contentSizeMB.toStringAsFixed(2)} MB > $maxSizeMB MB',
        );
        return ServerHttpUtil.json({
          'accepted': false,
          ...PeerError.clipboardTooLarge.toJson(),
          'actualSizeMB': contentSizeMB,
          'maxSizeMB': maxSizeMB,
        }, status: 413);
      }

      LogUtil.iTag(
        logTag,
        '用户同意分享剪切板，类型: ${clipboardData.typeDescription}, 大小: ${contentSizeMB.toStringAsFixed(2)} MB',
      );

      return _success(clipboardData);
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '处理剪切板请求异常: $e', e, stackTrace);
      return _reject(PeerError.internalError, status: 500);
    }
  }

  Response _success(ClipboardDataModel data) =>
      ServerHttpUtil.json({'accepted': true, 'clipboardData': data.toJson()});

  Response _reject(PeerError error, {int status = 200}) => ServerHttpUtil.json({
    'accepted': false,
    ...error.toJson(),
  }, status: status);
}
