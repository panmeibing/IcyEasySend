import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../services/file_transfer_service.dart';
import '../../services/permission_service.dart';
import '../../services/preferences_service.dart';
import '../../services/validation_service.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/error_messages.dart';
import '../../utils/log_util.dart';

/// Controller for handling file transfer logic
class FileTransferController {
  final ValidationService _validationService;
  final FileTransferService _fileTransferService;
  final PermissionService _permissionService;
  final PreferencesService _preferencesService;
  final String logTag = LogTags.transfer;

  FileTransferController({
    ValidationService? validationService,
    FileTransferService? fileTransferService,
    PermissionService? permissionService,
    PreferencesService? preferencesService,
  }) : _validationService = validationService ?? ValidationService(),
       _fileTransferService = fileTransferService ?? FileTransferService(),
       _permissionService = permissionService ?? PermissionService(),
       _preferencesService = preferencesService ?? PreferencesService();

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
              await DialogHelper.showErrorDialog(
                context,
                message:
                    permissionResult.errorMessage ??
                    ErrorMessages.permissionDenied,
              );
            }
          }
          return [];
        }
      }

      // Open file picker with multiple selection enabled
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<File> validFiles = [];
        final List<String> invalidFileNames = [];

        // Validate each selected file
        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            final validationResult = _validationService.validateFile(file);

            if (validationResult.isValid) {
              validFiles.add(file);
            } else {
              invalidFileNames.add(platformFile.name);
            }
          }
        }

        // Show error for invalid files
        if (invalidFileNames.isNotEmpty && context.mounted) {
          await DialogHelper.showErrorDialog(
            context,
            message: '以下文件无效或无法访问:\n${invalidFileNames.join('\n')}',
          );
        }

        return validFiles;
      }

      return [];
    } on FileSystemException {
      if (context.mounted) {
        await DialogHelper.showErrorDialog(
          context,
          message: ErrorMessages.fileAccessError,
        );
      }
      return [];
    } catch (e) {
      if (context.mounted) {
        await DialogHelper.showErrorDialog(
          context,
          message: ErrorMessages.fileError(e.toString()),
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

      // Validate each dropped file
      for (final file in droppedFiles) {
        final validationResult = _validationService.validateFile(file);

        if (validationResult.isValid) {
          validFiles.add(file);
        } else {
          invalidFileNames.add(file.path.split('/').last);
        }
      }

      // Show error for invalid files
      if (invalidFileNames.isNotEmpty && context.mounted) {
        await DialogHelper.showErrorDialog(
          context,
          message: '以下文件无效或无法访问:\n${invalidFileNames.join('\n')}',
        );
      }

      return validFiles;
    } catch (e) {
      if (context.mounted) {
        await DialogHelper.showErrorDialog(
          context,
          message: ErrorMessages.fileError(e.toString()),
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
      onStatusChange('等待接收方确认...');

      final results = await _fileTransferService.sendFilesWithBatchConfirm(
        targetIP: targetAddress,
        files: files,
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
        if (failureCount == 0) {
          await DialogHelper.showSuccessDialog(
            context,
            message: successCount == 1
                ? '文件发送成功！'
                : '发送 $successCount 个文件发送成功！',
          );

          // Save the IP address and port for next time
          await _preferencesService.saveLastUsedIP(targetIP);
          await _preferencesService.saveLastUsedPort(targetPort);
        } else if (successCount == 0) {
          await DialogHelper.showErrorDialog(
            context,
            message: '所有文件发送失败\n失败的文件:\n${failedFiles.join('\n')}',
          );
        } else {
          await DialogHelper.showInfoDialog(
            context,
            title: '传输完成',
            message:
                '成功: $successCount 个文件\n失败: $failureCount 个文件\n\n失败的文件:\n${failedFiles.join('\n')}',
          );

          await _preferencesService.saveLastUsedIP(targetIP);
          await _preferencesService.saveLastUsedPort(targetPort);
        }
      }
    } on SocketException {
      if (context.mounted) {
        await DialogHelper.showErrorDialog(
          context,
          message: ErrorMessages.networkConnectionFailed,
        );
      }
    } on FileSystemException {
      if (context.mounted) {
        await DialogHelper.showErrorDialog(
          context,
          message: ErrorMessages.fileAccessError,
        );
      }
    } catch (e) {
      if (context.mounted) {
        await DialogHelper.showErrorDialog(
          context,
          message: ErrorMessages.unexpectedError(e.toString()),
        );
      }
    } finally {
      onTransferEnd();
    }
  }

  /// Show dialog when permission is permanently denied
  Future<void> _showPermissionDeniedDialog(
    BuildContext context,
    String? message,
  ) async {
    if (!context.mounted) return;

    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: '需要权限',
      message: message ?? '需要存储权限才能选择文件。请在设置中手动开启权限。',
      confirmText: '打开设置',
      cancelText: '取消',
      icon: Icons.settings,
      iconColor: Colors.orange,
    );

    if (confirmed) {
      await ph.openAppSettings();
    }
  }
}
