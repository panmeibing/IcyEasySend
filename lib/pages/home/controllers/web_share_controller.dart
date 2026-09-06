import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/transfer_file_item.dart';
import '../../../models/transfer_history.dart';
import '../../../services/http_server_manager.dart';
import '../../../services/transfer/transfer_history_manager.dart';
import '../../../services/web_share_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/log_util.dart';
import '../../../utils/toast_helper.dart';
import '../widgets/web_share_qr_dialog.dart';

/// Controller for QR web-share flow.
class WebShareController {
  final TransferHistoryManager _historyManager;
  final String logTag = LogTags.ui;

  WebShareController({TransferHistoryManager? historyManager})
    : _historyManager = historyManager ?? TransferHistoryManager();

  /// QR share only needs a running server and selected files.
  bool canShareViaQr({
    required bool isServerRunning,
    required bool isSending,
    required bool isCreatingWebShare,
    required bool hasSelectedItems,
  }) {
    return isServerRunning &&
        !isSending &&
        !isCreatingWebShare &&
        hasSelectedItems;
  }

  /// Create a temporary web-share session and show QR for guest downloads.
  Future<void> shareViaQr({
    required BuildContext context,
    required List<TransferFileItem> selectedItems,
    required HTTPServerManager serverManager,
    required VoidCallback onCreatingStart,
    required VoidCallback onCreatingEnd,
    required VoidCallback disableFocusNodes,
    required VoidCallback enableFocusNodes,
    required bool Function() isMounted,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (!serverManager.isRunning()) {
      ToastHelper.showError(context, l10n.webShareServerRequired);
      return;
    }

    final serverAddress = serverManager.getServerAddress();
    if (serverAddress == null || serverAddress.isEmpty) {
      ToastHelper.showError(context, l10n.webShareServerRequired);
      return;
    }

    onCreatingStart();
    disableFocusNodes();

    try {
      final session = await WebShareService.instance.createSession(
        items: selectedItems,
      );
      final shareUrl = WebShareService.instance.buildShareUrl(
        serverAddress,
        session.token,
      );

      await saveWebShareHistory(
        session.files.map((f) {
          return TransferHistory(
            fileName: f.displayName,
            fileSize: f.size,
            peerIP: AppConstants.webShareHistoryPeerIp,
            peerDeviceName: l10n.webSharePeerName,
            timestamp: session.createdAt,
            isReceived: false,
            success: true,
          );
        }).toList(),
        onHistoryUpdated: serverManager.refreshHistory,
      );

      if (!context.mounted || !isMounted()) return;

      ToastHelper.showSuccess(context, l10n.webShareCreated);

      await WebShareQrDialog.show(
        context,
        session: session,
        shareUrl: shareUrl,
        shareUrlBuilder: () {
          final address = serverManager.getServerAddress();
          if (address == null || address.isEmpty) {
            return shareUrl;
          }
          return WebShareService.instance.buildShareUrl(address, session.token);
        },
        onStopSharing: () async {
          WebShareService.instance.stopSession(token: session.token);
          if (context.mounted && isMounted()) {
            ToastHelper.showInfo(context, l10n.webShareStopped);
          }
        },
      );
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '创建网页分享失败: $e', e, stackTrace);
      if (context.mounted && isMounted()) {
        ToastHelper.showError(context, l10n.webShareFailed);
      }
    } finally {
      enableFocusNodes();
      onCreatingEnd();
    }
  }

  Future<void> saveWebShareHistory(
    List<TransferHistory> histories, {
    VoidCallback? onHistoryUpdated,
  }) async {
    if (histories.isEmpty) return;
    await _historyManager.saveTransferHistoryBatch(histories);
    onHistoryUpdated?.call();
  }
}
