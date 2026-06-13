import 'dart:io';

import 'package:path/path.dart' as p;
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

  /// Whether [filePath] is located inside the app temporary/cache directory.
  Future<bool> isAppCacheFile(String filePath) async {
    final cacheDir = await getTemporaryDirectory();
    final cacheRoot = p.normalize(cacheDir.path);
    final normalizedPath = p.normalize(filePath);
    return p.isWithin(cacheRoot, normalizedPath) || normalizedPath == cacheRoot;
  }

  /// Delete specific files when they live in the app cache directory.
  ///
  /// Used to release space copied by share intent or file_picker once the
  /// files are no longer needed.
  Future<void> deleteCacheFilesIfPresent(Iterable<String> filePaths) async {
    if (filePaths.isEmpty) {
      return;
    }

    var deletedCount = 0;
    var deletedSize = 0;

    for (final filePath in filePaths) {
      if (!await isAppCacheFile(filePath)) {
        continue;
      }

      try {
        final file = File(filePath);
        if (!await file.exists()) {
          continue;
        }

        final size = await file.length();
        await file.delete();
        deletedCount++;
        deletedSize += size;
        LogUtil.dTag(logTag, '删除临时缓存文件: $filePath');
      } catch (e, stackTrace) {
        LogUtil.wTag(logTag, '删除临时缓存文件失败: $filePath, 错误=$e', e, stackTrace);
      }
    }

    if (deletedCount > 0) {
      LogUtil.iTag(
        logTag,
        '临时缓存清理完成: 删除$deletedCount个文件, '
        '释放${_formatSize(deletedSize)}',
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
  }

  /// Clean up file_picker cache directory
  ///
  /// file_picker on Android may cache large files in the app's cache directory,
  /// which can cause storage issues. This method cleans up those cached files.
  ///
  /// [excludePaths] can be used to preserve files received from a share intent
  /// during cold start.
  Future<void> cleanupFilePickerCache({
    Set<String> excludePaths = const {},
  }) async {
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
            if (excludePaths.contains(entity.path)) {
              LogUtil.dTag(logTag, '跳过分享缓存文件: ${entity.path}');
              continue;
            }

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
          '缓存清理完成: 删除$deletedCount个文件, 释放${_formatSize(deletedSize)}',
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
