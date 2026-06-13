import 'dart:io';

import 'package:path/path.dart' as path;

/// A local file paired with the name used on the wire (may include subfolders).
class TransferFileItem {
  final File file;
  final String transferName;

  const TransferFileItem({
    required this.file,
    required this.transferName,
  });

  factory TransferFileItem.fromFile(File file) {
    return TransferFileItem(
      file: file,
      transferName: path.basename(file.path),
    );
  }
}
