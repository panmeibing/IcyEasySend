import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../l10n/app_localizations.dart';
import '../../../models/transfer_file_item.dart';
import '../../../services/cache_cleanup_service.dart';
import '../../../utils/folder_collect_util.dart';
import '../../../services/file_transfer_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/preferences_service.dart';
import '../../../services/validation_service.dart';
import '../../../utils/dialog_helper.dart';
import '../../../utils/error_messages.dart';
import '../../../utils/log_util.dart';

/// Controller for handling file transfer logic
class FileTransferController {
  final ValidationService _validationService;
  final FileTransferService _fileTransferService;
  final PermissionService _permissionService;
  final PreferencesService _preferencesService;
  final CacheCleanupService _cacheCleanupService;
  final String logTag = LogTags.transfer;

  FileTransferController({
    ValidationService? validationService,
    FileTransferService? fileTransferService,
    PermissionService? permissionService,
    PreferencesService? preferencesService,
    CacheCleanupService? cacheCleanupService,
  }) : _validationService = validationService ?? ValidationService(),
       _fileTransferService = fileTransferService ?? FileTransferService(),
       _permissionService = permissionService ?? PermissionService(),
       _preferencesService = preferencesService ?? PreferencesService(),
       _cacheCleanupService = cacheCleanupService ?? CacheCleanupService();

  /// Select multiple files using the file picker
  Future<List<TransferFileItem>> selectFiles(BuildContext context) async {
    try {
      if (!await _ensureStoragePermission(context)) {
        return [];
      }

      // Open file picker with multiple selection enabled
      // withReadStream: true 避免在Android上缓存整个文件
      // withData: false 不读取文件字节数据到内存
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withReadStream: true, // 使用流式读取，避免缓存
        withData: false, // 不加载文件数据到内存
      );

      if (result != null && result.files.isNotEmpty) {
        final paths = result.files
            .where((platformFile) => platformFile.path != null)
            .map((platformFile) => platformFile.path!)
            .toList();
        if (!context.mounted) {
          return [];
        }
        return _collectAndValidatePaths(context, paths);
      }

      return [];
    } on FileSystemException {
      if (context.mounted) {
        await _showFileAccessError(context);
      }
      return [];
    } catch (e) {
      if (context.mounted) {
        await _showFileError(context, e);
      }
      return [];
    }
  }

  /// Select a folder and expand it into transfer items (recursive).
  Future<List<TransferFileItem>> selectFolder(BuildContext context) async {
    try {
      if (!await _ensureStoragePermission(context)) {
        return [];
      }

      if (!context.mounted) {
        return [];
      }

      final l10n = AppLocalizations.of(context);
      final directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.selectFolder,
      );

      if (directoryPath == null || directoryPath.trim().isEmpty) {
        return [];
      }

      final items = await FolderCollectUtil.collectFromDirectory(
        Directory(directoryPath),
      );

      if (items.isEmpty) {
        if (context.mounted) {
          await DialogHelper.showInfoDialog(
            context,
            title: l10n.error,
            message: l10n.folderContainsNoFiles,
            confirmText: l10n.confirm,
          );
        }
        return [];
      }

      if (!context.mounted) {
        return [];
      }
      return _validateTransferItems(context, items);
    } on FileSystemException {
      if (context.mounted) {
        await _showFileAccessError(context);
      }
      return [];
    } catch (e) {
      if (context.mounted) {
        await _showFileError(context, e);
      }
      return [];
    }
  }

  /// Expand dropped/shared paths (files or folders) and return valid items.
  Future<List<TransferFileItem>> validateDroppedPaths(
    BuildContext context,
    Iterable<String> paths,
  ) async {
    try {
      final items = await FolderCollectUtil.collectFromPaths(paths);
      if (items.isEmpty) {
        return [];
      }
      if (!context.mounted) {
        return [];
      }
      return _validateTransferItems(context, items);
    } catch (e) {
      if (context.mounted) {
        await _showFileError(context, e);
      }
      return [];
    }
  }

  Future<List<TransferFileItem>> _collectAndValidatePaths(
    BuildContext context,
    List<String> paths,
  ) async {
    final items = await FolderCollectUtil.collectFromPaths(paths);
    if (!context.mounted) {
      return [];
    }
    return _validateTransferItems(context, items);
  }

  Future<List<TransferFileItem>> _validateTransferItems(
    BuildContext context,
    List<TransferFileItem> items,
  ) async {
    final validItems = <TransferFileItem>[];
    final invalidNames = <String>[];

    for (final item in items) {
      final validationResult = await _validationService.validateFileAsync(
        item.file,
      );

      if (validationResult.isValid) {
        validItems.add(item);
        LogUtil.dTag(
          logTag,
          '文件验证通过: ${item.transferName} -> ${item.file.path}',
        );
      } else {
        invalidNames.add(item.transferName);
        LogUtil.wTag(
          logTag,
          '文件验证失败: ${item.transferName}, 原因=${validationResult.errorMessage}',
        );
      }
    }

    if (invalidNames.isNotEmpty && context.mounted) {
      final l10n = AppLocalizations.of(context);
      await DialogHelper.showErrorDialog(
        context,
        message: l10n.invalidFilesMessage(invalidNames.join('\n')),
        title: l10n.error,
        confirmText: l10n.confirm,
      );
    }

    return validItems;
  }

  Future<bool> _ensureStoragePermission(BuildContext context) async {
    final hasPermission = await _permissionService.hasStoragePermission();
    if (hasPermission) {
      return true;
    }

    final permissionResult = await _permissionService.requestStoragePermission();
    if (permissionResult.granted) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    if (permissionResult.permanentlyDenied) {
      await _showPermissionDeniedDialog(
        context,
        permissionResult.errorMessage,
      );
    } else {
      final l10n = AppLocalizations.of(context);
      await DialogHelper.showErrorDialog(
        context,
        message:
            permissionResult.errorMessage ?? l10n.permissionDenied,
        title: l10n.error,
        confirmText: l10n.confirm,
      );
    }
    return false;
  }

  Future<void> _showFileAccessError(BuildContext context) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    await DialogHelper.showErrorDialog(
      context,
      message: l10n.fileAccessError,
      title: l10n.error,
      confirmText: l10n.confirm,
    );
  }

  Future<void> _showFileError(BuildContext context, Object error) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    await DialogHelper.showErrorDialog(
      context,
      message: l10n.fileError(error.toString()),
      title: l10n.error,
      confirmText: l10n.confirm,
    );
  }

  /// Send multiple selected files to the target device
  Future<void> sendFiles({
    required BuildContext context,
    required List<TransferFileItem> files,
    required String targetIP,
    required int targetPort,
    String? secretKey,
    required Function(double, int, int) onProgress,
    required Function(int, double, int, int) onFileProgress,
    required Function(String) onStatusChange,
    required Function() onTransferStart,
    required Function() onTransferEnd,
    VoidCallback? onHistoryUpdated,
  }) async {
    if (files.isEmpty || targetIP.isEmpty) {
      return;
    }

    final targetAddress = '$targetIP:$targetPort';
    LogUtil.iTag(
      logTag,
      "sendFiles() ready to send files, targetAddress: $targetAddress",
    );

    onTransferStart();

    try {
      final l10n = AppLocalizations.of(context);
      onStatusChange(l10n.waitingForReceiverConfirmation);

      final results = await _fileTransferService.sendFilesWithBatchConfirm(
        targetIP: targetAddress,
        files: files,
        secretKey: secretKey,
        onProgress: onProgress,
        onFileProgress: onFileProgress,
        onStatusChange: onStatusChange,
        onHistoryUpdated: onHistoryUpdated,
      );

      // Count successes and failures
      int successCount = 0;
      int failureCount = 0;
      final List<String> failedFiles = [];

      for (final entry in results.entries) {
        if (entry.value.isSuccess) {
          successCount++;
        } else {
          failureCount++;
          failedFiles.add(entry.key);
        }
      }

      // Show summary message
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        if (failureCount == 0) {
          await DialogHelper.showSuccessDialog(
            context,
            message: successCount == 1
                ? l10n.fileSendSuccess
                : l10n.filesSendSuccess(successCount),
            title: l10n.success,
            confirmText: l10n.confirm,
          );

          // Save the IP address and port for next time
          await _preferencesService.saveLastUsedIP(targetIP);
          await _preferencesService.saveLastUsedPort(targetPort);
        } else if (successCount == 0) {
          await DialogHelper.showErrorDialog(
            context,
            message:
                '${l10n.allFilesSendFailed}\n${l10n.failedFiles}:\n${failedFiles.join('\n')}',
            title: l10n.error,
            confirmText: l10n.confirm,
          );
        } else {
          await DialogHelper.showInfoDialog(
            context,
            title: l10n.transferComplete,
            message: l10n.transferSummary(
              successCount,
              failureCount,
              failedFiles.join('\n'),
            ),
            confirmText: l10n.confirm,
          );

          await _preferencesService.saveLastUsedIP(targetIP);
          await _preferencesService.saveLastUsedPort(targetPort);
        }
      }
    } on SocketException {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        await DialogHelper.showErrorDialog(
          context,
          message: l10n.networkConnectionFailed,
          title: l10n.error,
          confirmText: l10n.confirm,
        );
      }
    } on FileSystemException {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        await DialogHelper.showErrorDialog(
          context,
          message: ErrorMessages.fileAccessError,
          title: l10n.error,
          confirmText: l10n.confirm,
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        await DialogHelper.showErrorDialog(
          context,
          message: l10n.unexpectedError(e.toString()),
          title: l10n.error,
          confirmText: l10n.confirm,
        );
      }
    } finally {
      onTransferEnd();
      
      // Clean up file_picker cache after transfer completes (Android only)
      // This is safe because files have already been read and sent
      if (Platform.isAndroid) {
        LogUtil.iTag(logTag, '文件传输完成，清理file_picker缓存');
        _cacheCleanupService.cleanupFilePickerCache().catchError((e) {
          LogUtil.wTag(logTag, '清理缓存失败: $e');
        });
      }
    }
  }

  /// Show dialog when permission is permanently denied
  Future<void> _showPermissionDeniedDialog(
    BuildContext context,
    String? message,
  ) async {
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context);
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: l10n.permissionRequired,
      message: message ?? l10n.storagePermissionMessage,
      confirmText: l10n.openSettings,
      cancelText: l10n.cancel,
      icon: Icons.settings,
      iconColor: Colors.orange,
    );

    if (confirmed) {
      await ph.openAppSettings();
    }
  }
}
