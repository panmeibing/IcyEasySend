import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../utils/log_util.dart';

/// Service for cleaning up temporary files and caches
///
/// This service helps prevent storage issues by cleaning up:
/// - file_picker cache files
/// - Temporary files created by the app
/// - Old clipboard files
class CacheCleanupService {
  final String logTag = LogTags.system;

  /// Clean up file_picker cache directory
  ///
  /// file_picker on Android may cache large files in the app's cache directory,
  /// which can cause storage issues. This method cleans up those cached files.
  Future<void> cleanupFilePickerCache() async {
    try {
      // Get the cache directory
      final cacheDir = await getTemporaryDirectory();

      LogUtil.iTag(logTag, '开始清理file_picker缓存: ${cacheDir.path}');

      // Clean up the entire cache directory
      if (await cacheDir.exists()) {
        final files = await cacheDir.list(recursive: true).toList();
        int deletedCount = 0;
        int deletedSize = 0;

        for (final entity in files) {
          if (entity is File) {
            try {
              final size = await entity.length();
              await entity.delete();
              deletedCount++;
              deletedSize += size;
              LogUtil.dTag(logTag, '删除缓存文件: ${entity.path}');
            } catch (e) {
              LogUtil.wTag(logTag, '删除缓存文件失败: ${entity.path}, 错误=$e');
            }
          }
        }

        LogUtil.iTag(
          logTag,
          '缓存清理完成: 删除$deletedCount个文件, 释放${(deletedSize / (1024 * 1024)).toStringAsFixed(2)}MB空间',
        );
      }
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '清理file_picker缓存失败: $e', e, stackTrace);
    }
  }

  /// Clean up old files in a specific directory
  ///
  /// Parameters:
  /// - [directory]: The directory to clean
  /// - [maxAgeInDays]: Maximum age of files to keep (default: 7 days)
  Future<void> cleanupOldFiles(
    Directory directory, {
    int maxAgeInDays = 7,
  }) async {
    try {
      if (!await directory.exists()) {
        return;
      }

      final now = DateTime.now();
      final maxAge = Duration(days: maxAgeInDays);

      final files = await directory
          .list(recursive: false)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      int deletedCount = 0;

      for (final file in files) {
        try {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

          if (age > maxAge) {
            await file.delete();
            deletedCount++;
            LogUtil.dTag(logTag, '删除过期文件: ${file.path}, 年龄=${age.inDays}天');
          }
        } catch (e) {
          LogUtil.wTag(logTag, '删除过期文件失败: ${file.path}, 错误=$e');
        }
      }

      if (deletedCount > 0) {
        LogUtil.iTag(logTag, '清理完成: 删除$deletedCount个过期文件');
      }
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '清理过期文件失败: $e', e, stackTrace);
    }
  }

  /// Get cache directory size
  ///
  /// Returns the total size of the cache directory in bytes
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();

      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      final files = await cacheDir
          .list(recursive: true)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      for (final file in files) {
        try {
          totalSize += await file.length();
        } catch (e) {
          // Ignore errors for individual files
        }
      }

      return totalSize;
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '获取缓存大小失败: $e', e, stackTrace);
      return 0;
    }
  }

}
