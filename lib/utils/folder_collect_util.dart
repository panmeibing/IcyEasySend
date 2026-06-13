import 'dart:io';

import 'package:path/path.dart' as path;

import '../models/transfer_file_item.dart';
import 'log_util.dart';
import 'transfer_path_util.dart';

/// Collects files from directories for folder transfer.
class FolderCollectUtil {
  static final String _logTag = LogTags.transfer;

  /// Recursively list files under [root], preserving structure as `folderName/...`.
  static Future<List<TransferFileItem>> collectFromDirectory(
    Directory root,
  ) async {
    final items = <TransferFileItem>[];
    final rootPath = path.normalize(root.absolute.path);
    final folderName = path.basename(rootPath);

    if (!await root.exists()) {
      LogUtil.wTag(_logTag, '文件夹不存在: $rootPath');
      return items;
    }

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }

      final filePath = path.normalize(entity.absolute.path);
      if (!filePath.startsWith(rootPath)) {
        continue;
      }

      var relative = path.relative(filePath, from: rootPath);
      relative = TransferPathUtil.normalizeTransferPath(relative);
      final transferName = path.posix.join(folderName, relative);

      items.add(
        TransferFileItem(file: entity, transferName: transferName),
      );
    }

    LogUtil.iTag(
      _logTag,
      '从文件夹收集文件: $folderName, 共 ${items.length} 个文件',
    );
    return items;
  }

  /// Expand filesystem paths (files or directories) into transfer items.
  static Future<List<TransferFileItem>> collectFromPaths(
    Iterable<String> paths,
  ) async {
    final items = <TransferFileItem>[];

    for (final rawPath in paths) {
      final trimmed = rawPath.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final entityType = await FileSystemEntity.type(
        trimmed,
        followLinks: false,
      );

      if (entityType == FileSystemEntityType.directory) {
        items.addAll(await collectFromDirectory(Directory(trimmed)));
      } else if (entityType == FileSystemEntityType.file) {
        items.add(TransferFileItem.fromFile(File(trimmed)));
      }
    }

    return items;
  }
}
