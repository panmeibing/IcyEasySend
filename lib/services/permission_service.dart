import 'dart:io';

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
  /// Request storage/file access permissions
  ///
  /// On Android 13+ (API 33+), requests READ_MEDIA_* permissions
  /// On Android 10-12 (API 29-32), requests READ_EXTERNAL_STORAGE
  /// On iOS, requests photo library access
  ///
  /// Note: For Android 13+, file_picker uses the system file picker
  /// which doesn't require storage permissions for most file types.
  /// We request media permissions for accessing photos, videos, and audio.
  ///
  /// Returns [PermissionRequestResult] indicating if permission was granted
  Future<PermissionRequestResult> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), request granular media permissions
        // For file_picker, these permissions are optional as it uses SAF (Storage Access Framework)
        // But we request them for better user experience when accessing media files

        // Try requesting photos permission first (most common use case)
        var status = await ph.Permission.photos.request();

        if (status.isGranted || status.isLimited) {
          return PermissionRequestResult(granted: true);
        }

        // If photos permission is denied, try storage permission (for Android 12 and below)
        status = await ph.Permission.storage.request();

        if (status.isGranted) {
          return PermissionRequestResult(granted: true);
        } else if (status.isPermanentlyDenied) {
          return PermissionRequestResult(
            granted: false,
            permanentlyDenied: true,
            errorMessage: '存储权限已被永久拒绝，请在设置中手动开启',
          );
        } else if (status.isDenied) {
          // For Android 13+, file_picker can still work without these permissions
          // So we return granted=true but with a note
          return PermissionRequestResult(
            granted: true, // Allow to proceed
            errorMessage: '部分权限被拒绝，但仍可以使用文件选择器',
          );
        } else {
          return PermissionRequestResult(
            granted: true, // Allow to proceed with file picker
            errorMessage: '部分权限未授予，但可以继续使用',
          );
        }
      } else if (Platform.isIOS) {
        // On iOS, request photo library permission for file picker
        final status = await ph.Permission.photos.request();

        if (status.isGranted || status.isLimited) {
          return PermissionRequestResult(granted: true);
        } else if (status.isPermanentlyDenied) {
          return PermissionRequestResult(
            granted: false,
            permanentlyDenied: true,
            errorMessage: '照片权限已被永久拒绝，请在设置中手动开启',
          );
        } else if (status.isDenied) {
          return PermissionRequestResult(
            granted: false,
            errorMessage: '需要照片权限才能选择文件',
          );
        } else {
          return PermissionRequestResult(
            granted: false,
            errorMessage: '照片权限请求失败',
          );
        }
      } else {
        // Desktop platforms don't require runtime permissions
        return PermissionRequestResult(granted: true);
      }
    } catch (e) {
      // If permission request fails, still allow file picker to work
      // as it uses SAF on Android 13+
      if (Platform.isAndroid) {
        return PermissionRequestResult(
          granted: true,
          errorMessage: '权限请求出错，但可以继续使用文件选择器',
        );
      }
      return PermissionRequestResult(
        granted: false,
        errorMessage: '权限请求出错: ${e.toString()}',
      );
    }
  }

  /// Check if storage permission is already granted
  ///
  /// Returns true if permission is granted, false otherwise
  /// Note: On Android 13+, returns true even without permissions
  /// as file_picker uses SAF which doesn't require permissions
  Future<bool> hasStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // Check photos permission first (Android 13+)
        var status = await ph.Permission.photos.status;
        if (status.isGranted || status.isLimited) {
          return true;
        }

        // Check storage permission (Android 12 and below)
        status = await ph.Permission.storage.status;
        if (status.isGranted) {
          return true;
        }

        // On Android 13+, file_picker works without these permissions
        // So we return true to allow the app to proceed
        return true;
      } else if (Platform.isIOS) {
        final status = await ph.Permission.photos.status;
        return status.isGranted || status.isLimited;
      } else {
        // Desktop platforms don't require runtime permissions
        return true;
      }
    } catch (e) {
      // If check fails on Android, assume we can still use file picker
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
