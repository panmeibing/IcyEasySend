import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

import 'constants.dart';
import 'log_util.dart';

/// Platform related tools and methods
class PlatformUtil {
  static final String logTag = LogTags.ui;

  /// Get download directory
  ///
  /// Android: /storage/emulated/0/Download
  /// iOS: Documents directory
  /// Other platforms: Downloads directory
  static Future<Directory?> getDownloadsDirectory() async {
    LogUtil.dTag(logTag, '获取下载目录...');

    try {
      Directory? directory;

      if (Platform.isAndroid) {
        LogUtil.dTag(logTag, '平台: Android');
        final externalDir = await path_provider.getExternalStorageDirectory();

        if (externalDir != null) {
          final pathParts = externalDir.path.split('/');
          final androidIndex = pathParts.indexOf('Android');

          if (androidIndex > 0) {
            final basePath = pathParts.sublist(0, androidIndex).join('/');
            final downloadsPath = '$basePath/Download';
            LogUtil.dTag(logTag, 'Android下载路径: $downloadsPath');

            final downloadsDir = Directory(downloadsPath);

            if (!await downloadsDir.exists()) {
              LogUtil.dTag(logTag, '下载目录不存在，创建中...');
              try {
                await downloadsDir.create(recursive: true);
                LogUtil.iTag(logTag, '下载目录创建成功: $downloadsPath');
              } catch (e, stackTrace) {
                LogUtil.wTag(logTag, '创建下载目录失败，使用外部存储目录: $e', e, stackTrace);
                return externalDir;
              }
            }

            directory = downloadsDir;
          } else {
            LogUtil.wTag(logTag, '无法解析Android路径，使用外部存储目录');
            directory = externalDir;
          }
        } else {
          LogUtil.wTag(logTag, '无法获取外部存储目录');
          directory = null;
        }
      } else if (Platform.isIOS) {
        LogUtil.dTag(logTag, '平台: iOS');
        directory = await path_provider.getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        LogUtil.dTag(logTag, '平台: ${Platform.operatingSystem}');
        directory = await path_provider.getDownloadsDirectory();
      } else {
        LogUtil.wTag(logTag, '未知平台: ${Platform.operatingSystem}');
        directory = null;
      }

      if (directory != null) {
        LogUtil.iTag(logTag, '下载目录: ${directory.path}');
      } else {
        LogUtil.wTag(logTag, '无法获取下载目录');
      }

      return directory;
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '获取下载目录失败: $e', e, stackTrace);
      return null;
    }
  }

  /// Get logger file directory
  ///
  /// Mobile: Must use the system allocated writable directory
  /// Desktop: Retrieve the directory where the executable file is located
  static Future<String> getLoggerFilePath([String? fileName]) async {
    final String effectiveFileName =
        fileName ?? AppConstants.defaultLoggerFileName;
    final String finalFileName = path.extension(effectiveFileName).isEmpty
        ? '$effectiveFileName.log'
        : effectiveFileName;

    Directory directory;

    if (Platform.isAndroid || Platform.isIOS) {
      directory = await path_provider.getApplicationSupportDirectory();
    } else {
      final String exePath = Platform.resolvedExecutable;
      directory = Directory(path.dirname(exePath));
    }

    return path.join(directory.path, finalFileName);
  }
}
