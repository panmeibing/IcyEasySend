import 'dart:io';

import 'package:path/path.dart' as path;

/// A local file paired with the name used on the wire (may include subfolders).
class TransferFileItem {
  final File file;
  final String transferName;

  const TransferFileItem({required this.file, required this.transferName});

  factory TransferFileItem.fromFile(File file) {
    return TransferFileItem(file: file, transferName: path.basename(file.path));
  }

  TransferFileItem renamed(String transferName) =>
      TransferFileItem(file: file, transferName: transferName);

  /// [incoming] with every name made distinct from [existing] and from each
  /// other, by numbering the later copies: `a.jpg`, `a (2).jpg`, ...
  /// A file that is already in the list is dropped rather than numbered.
  ///
  /// The name is what a batch identifies a file by, on both ends: transfer
  /// ids, results and cancellation are all keyed by it. Two files picked from
  /// different folders under the same name would otherwise collapse into one.
  /// Compared case-insensitively, since the receiver's disk may be.
  static List<TransferFileItem> withUniqueNames(
    List<TransferFileItem> incoming, {
    Iterable<TransferFileItem> existing = const [],
  }) {
    final taken = {for (final item in existing) _key(item.transferName)};
    final files = {for (final item in existing) _pathKey(item.file)};
    final result = <TransferFileItem>[];
    for (final item in incoming) {
      if (!files.add(_pathKey(item.file))) continue;
      var name = item.transferName;
      if (taken.contains(_key(name))) {
        final dir = path.posix.dirname(name);
        final base = path.posix.basenameWithoutExtension(name);
        final ext = path.posix.extension(name);
        var counter = 2;
        do {
          final candidate = '$base ($counter)$ext';
          name = dir == '.' ? candidate : '$dir/$candidate';
          counter++;
        } while (taken.contains(_key(name)));
      }
      taken.add(_key(name));
      result.add(name == item.transferName ? item : item.renamed(name));
    }
    return result;
  }

  static String _key(String name) => name.toLowerCase();

  static String _pathKey(File file) => path.normalize(file.absolute.path);
}
