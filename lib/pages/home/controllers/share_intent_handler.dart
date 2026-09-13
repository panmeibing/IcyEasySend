import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/transfer_file_item.dart';
import '../../../services/cache_cleanup_service.dart';
import '../../../services/sharing_intent_service.dart';
import '../../../utils/log_util.dart';
import '../../../utils/toast_helper.dart';
import 'file_transfer_controller.dart';

/// Handles share-intent payloads (cold start and while running).
class ShareIntentHandler {
  final FileTransferController _fileTransferController;
  final CacheCleanupService _cacheCleanupService;
  final SharingIntentService _sharingIntentService;
  final String logTag = LogTags.ui;

  ShareIntentHandler({
    required FileTransferController fileTransferController,
    required CacheCleanupService cacheCleanupService,
    required SharingIntentService sharingIntentService,
  }) : _fileTransferController = fileTransferController,
       _cacheCleanupService = cacheCleanupService,
       _sharingIntentService = sharingIntentService;

  /// Handle share payload that opened the app before UI was ready.
  Future<void> processInitialSharedFiles({
    required bool Function() isMounted,
    required Future<void> Function(List<File> files) handleSharedFiles,
  }) async {
    await _sharingIntentService.loadInitialSharingIfNeeded();
    if (!isMounted()) return;

    final pending = _sharingIntentService.takePendingSharedFiles();
    if (pending.isEmpty) {
      return;
    }

    LogUtil.iTag(logTag, '处理冷启动分享: ${pending.length} 个文件');
    await handleSharedFiles(pending);
  }

  /// Handle shared files from other apps.
  Future<void> handleSharedFiles({
    required BuildContext context,
    required List<File> sharedFiles,
    required bool isServerRunning,
    required bool isSending,
    required bool Function() isMounted,
    required void Function(List<TransferFileItem> items) onItemsAdded,
  }) async {
    LogUtil.iTag(logTag, '开始处理分享文件: ${sharedFiles.length} 个');

    Future<void> rejectShare() async {
      await _sharingIntentService.cleanupSharedCacheFiles(sharedFiles);
      _sharingIntentService.clearSharedFiles();
    }

    if (!isServerRunning) {
      await rejectShare();
      if (!context.mounted || !isMounted()) return;
      ToastHelper.showWarning(
        context,
        AppLocalizations.of(context).serverNotRunning,
      );
      return;
    }

    if (isSending) {
      await rejectShare();
      if (!context.mounted || !isMounted()) return;
      ToastHelper.showWarning(
        context,
        AppLocalizations.of(context).sendingInProgress,
      );
      return;
    }

    final paths = sharedFiles.map((file) => file.path).toList();
    final validItems = await _fileTransferController.validateDroppedPaths(
      context,
      paths,
    );

    if (!context.mounted || !isMounted()) {
      LogUtil.wTag(LogTags.ui, 'The current page is not mounted.');
      return;
    }

    if (validItems.isEmpty) {
      await rejectShare();
      return;
    }

    _sharingIntentService.clearSharedFiles();

    onItemsAdded(validItems);

    ToastHelper.showSuccess(
      context,
      AppLocalizations.of(context).filesAdded(validItems.length),
    );
  }

  Future<void> cleanupShareCacheForItems(
    Iterable<TransferFileItem> items,
  ) async {
    if (items.isEmpty) {
      return;
    }

    await _cacheCleanupService.deleteCacheFilesIfPresent(
      items.map((item) => item.file.path),
    );
  }
}
