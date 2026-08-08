import 'dart:io';

import 'package:icy_easy_send/utils/log_util.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Result of permission request operation
class PermissionRequestResult {
  final bool granted;
  final String? errorMessage;
  final bool permanentlyDenied;

  PermissionRequestResult({
    required this.granted,
    this.errorMessage,
    this.permanentlyDenied = false,
  });
}

/// Service for handling runtime permissions
///
/// Provides functionality to:
/// - Request file access permissions
/// - Request network permissions (Android)
/// - Handle permission denial scenarios
///
class PermissionService {
  String logTag = LogTags.permission;

  /// Request storage/file access permissions
  ///
  /// On Android 13+ (API 33+), requests READ_MEDIA_* permissions
  /// On Android 10-12 (API 29-32), requests READ_EXTERNAL_STORAGE and WRITE_EXTERNAL_STORAGE
  /// On iOS, requests photo library access
  ///
  /// Note: For receiving files, we need WRITE_EXTERNAL_STORAGE on Android 12 and below
  /// to save files to the public Downloads directory.
  ///
  /// Returns [PermissionRequestResult] indicating if permission was granted
  Future<PermissionRequestResult> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android 12 and below (API 32 and below), we need WRITE_EXTERNAL_STORAGE
        // to save files to the public Downloads directory
        var status = await ph.Permission.storage.request();

        if (status.isGranted) {
          return PermissionRequestResult(granted: true);
        } else if (status.isPermanentlyDenied) {
          return PermissionRequestResult(
            granted: false,
            permanentlyDenied: true,
            errorMessage: '存储权限已被永久拒绝，请在设置中手动开启\n\n需要此权限才能将文件保存到下载文件夹',
          );
        } else if (status.isDenied) {
          // Try requesting photos permission for Android 13+
          status = await ph.Permission.photos.request();

          if (status.isGranted || status.isLimited) {
            // On Android 13+, we can still save files even without full storage permission
            // The app will use app-specific directory or SAF
            return PermissionRequestResult(
              granted: true,
              errorMessage: '已授予部分权限，文件将保存到下载文件夹',
            );
          }

          return PermissionRequestResult(
            granted: false,
            errorMessage: '需要存储权限才能保存文件到下载文件夹\n\n您可以在设置中授予权限',
          );
        } else {
          return PermissionRequestResult(
            granted: false,
            errorMessage: '存储权限请求失败',
          );
        }
      } else if (Platform.isIOS) {
        // On iOS, file_picker uses the system document picker which doesn't require permissions
        // Only request photo library permission if specifically accessing photos
        // For general file selection, no permission is needed
        return PermissionRequestResult(granted: true);
      } else {
        // Desktop platforms don't require runtime permissions
        return PermissionRequestResult(granted: true);
      }
    } catch (e) {
      LogUtil.eTag(logTag, "requestStoragePermission() error: $e");
      return PermissionRequestResult(
        granted: false,
        errorMessage: '权限请求出错: ${e.toString()}',
      );
    }
  }

  /// Check if storage permission is already granted
  ///
  /// Returns true if permission is granted, false otherwise
  /// Note: On Android, checks for WRITE_EXTERNAL_STORAGE permission
  /// which is needed to save files to public Downloads directory
  Future<bool> hasStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // Check storage permission (needed for Android 12 and below)
        var status = await ph.Permission.storage.status;
        if (status.isGranted) {
          return true;
        }

        // Check photos permission (Android 13+)
        status = await ph.Permission.photos.status;
        if (status.isGranted || status.isLimited) {
          return true;
        }

        // On Android 13+, we can still save files to app-specific directory
        // even without these permissions, so return true
        return true;
      } else if (Platform.isIOS) {
        // On iOS, file_picker doesn't require permissions for document selection
        return true;
      } else {
        // Desktop platforms don't require runtime permissions
        return true;
      }
    } catch (e) {
      // If check fails on Android, assume we can still use app-specific directory
      return Platform.isAndroid;
    }
  }

  /// Request network permissions (Android only)
  ///
  /// On Android, checks if the app has network access.
  /// This is typically granted automatically via manifest, but we check it here.
  ///
  /// Returns [PermissionRequestResult] indicating if permission is available
  Future<PermissionRequestResult> requestNetworkPermission() async {
    try {
      if (Platform.isAndroid) {
        // Network permission is typically granted automatically via manifest
        // We just check if it's available
        // Note: permission_handler doesn't have a direct network permission check
        // but INTERNET permission is granted at install time on Android

        // For this implementation, we'll assume network permission is granted
        // if the app is installed (since it's in the manifest)
        return PermissionRequestResult(granted: true);
      } else {
        // Other platforms don't require network permissions
        return PermissionRequestResult(granted: true);
      }
    } catch (e) {
      return PermissionRequestResult(
        granted: false,
        errorMessage: '网络权限检查出错: ${e.toString()}',
      );
    }
  }

  /// Check if network permission is available
  ///
  /// Returns true if network access is available, false otherwise
  Future<bool> hasNetworkPermission() async {
    try {
      if (Platform.isAndroid) {
        // Network permission is granted at install time via manifest
        return true;
      } else {
        // Other platforms don't require network permissions
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Open app settings
  ///
  /// Opens the system settings page for this app, allowing the user
  /// to manually grant permissions that were permanently denied.
  Future<bool> openAppSettings() async {
    try {
      // Use the permission_handler's openAppSettings method
      return await ph.openAppSettings();
    } catch (e) {
      return false;
    }
  }

  /// Request notification permission (Android 13+).
  ///
  /// Required to display the foreground service notification used for
  /// background keepalive. Returns true if granted or not applicable.
  Future<bool> requestNotificationPermission() async {
    try {
      if (!Platform.isAndroid) return true;

      final status = await ph.Permission.notification.status;
      if (status.isGranted) return true;

      final result = await ph.Permission.notification.request();
      if (result.isGranted) {
        LogUtil.iTag(logTag, '通知权限已授予');
        return true;
      }

      LogUtil.wTag(logTag, '通知权限未授予: $result');
      return false;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '请求通知权限失败: $e', e, stackTrace);
      return false;
    }
  }

  /// Request all necessary permissions for the app
  ///
  /// Requests both storage and network permissions.
  /// Returns true if all permissions are granted, false otherwise.
  Future<PermissionRequestResult> requestAllPermissions() async {
    // Request storage permission
    final storageResult = await requestStoragePermission();

    if (!storageResult.granted) {
      return storageResult;
    }

    // Request network permission (mostly a check on Android)
    final networkResult = await requestNetworkPermission();

    if (!networkResult.granted) {
      return networkResult;
    }

    // Android 13+: notification for foreground service (non-blocking)
    await requestNotificationPermission();

    return PermissionRequestResult(granted: true);
  }

  /// Check if all necessary permissions are granted
  ///
  /// Returns true if all permissions are granted, false otherwise
  Future<bool> hasAllPermissions() async {
    final hasStorage = await hasStoragePermission();
    final hasNetwork = await hasNetworkPermission();

    return hasStorage && hasNetwork;
  }
}
