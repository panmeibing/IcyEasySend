import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../l10n/app_localizations.dart';
import '../../../services/cache_cleanup_service.dart';
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
  Future<List<File>> selectFiles(BuildContext context) async {
    try {
      // Check and request storage permission
      final hasPermission = await _permissionService.hasStoragePermission();

      if (!hasPermission) {
        final permissionResult = await _permissionService
            .requestStoragePermission();

        if (!permissionResult.granted) {
          if (context.mounted) {
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
                    permissionResult.errorMessage ??
                    AppLocalizations.of(context).permissionDenied,
                title: l10n.error,
                confirmText: l10n.confirm,
              );
            }
          }
          return [];
        }
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
        final List<File> validFiles = [];
        final List<String> invalidFileNames = [];

        // Validate each selected file (use async validation for Android compatibility)
        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            LogUtil.dTag(logTag, '选择的文件路径: ${platformFile.path}');
            LogUtil.dTag(logTag, '选择的文件名: ${platformFile.name}');
            
            final file = File(platformFile.path!);
            // Use async validation to handle Android content URIs properly
            final validationResult = await _validationService.validateFileAsync(file);

            if (validationResult.isValid) {
              validFiles.add(file);
              LogUtil.dTag(logTag, '文件验证通过，添加到列表: ${platformFile.name}');
            } else {
              invalidFileNames.add(platformFile.name);
              LogUtil.wTag(logTag, '文件验证失败: ${platformFile.name}, 原因=${validationResult.errorMessage}');
            }
          }
        }

        // Show error for invalid files
        if (invalidFileNames.isNotEmpty && context.mounted) {
          final l10n = AppLocalizations.of(context);
          await DialogHelper.showErrorDialog(
            context,
            message: l10n.invalidFilesMessage(invalidFileNames.join('\n')),
            title: l10n.error,
            confirmText: l10n.confirm,
          );
        }

        return validFiles;
      }

      return [];
    } on FileSystemException {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        await DialogHelper.showErrorDialog(
          context,
          message: l10n.fileAccessError,
          title: l10n.error,
          confirmText: l10n.confirm,
        );
      }
      return [];
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        await DialogHelper.showErrorDialog(
          context,
          message: l10n.fileError(e.toString()),
          title: l10n.error,
          confirmText: l10n.confirm,
        );
      }
      return [];
    }
  }

  /// Validate dropped files and return valid ones
  Future<List<File>> validateDroppedFiles(
    BuildContext context,
    List<File> droppedFiles,
  ) async {
    try {
      final List<File> validFiles = [];
      final List<String> invalidFileNames = [];

      // Validate each dropped file (use async validation)
      for (final file in droppedFiles) {
        final validationResult = await _validationService.validateFileAsync(file);

        if (validationResult.isValid) {
          validFiles.add(file);
        } else {
          invalidFileNames.add(file.path.split('/').last);
        }
      }

      // Show error for invalid files
      if (invalidFileNames.isNotEmpty && context.mounted) {
        final l10n = AppLocalizations.of(context);
        await DialogHelper.showErrorDialog(
          context,
          message: l10n.invalidFilesMessage(invalidFileNames.join('\n')),
          title: l10n.error,
          confirmText: l10n.confirm,
        );
      }

      return validFiles;
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        await DialogHelper.showErrorDialog(
          context,
          message: l10n.fileError(e.toString()),
          title: l10n.error,
          confirmText: l10n.confirm,
        );
      }
      return [];
    }
  }

  /// Send multiple selected files to the target device
  Future<void> sendFiles({
    required BuildContext context,
    required List<File> files,
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
