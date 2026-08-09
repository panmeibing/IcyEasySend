import 'dart:io';

/// A file exposed by a temporary web share session.
class WebShareFile {
  final String id;
  final String displayName;
  final String absolutePath;
  final int size;

  const WebShareFile({
    required this.id,
    required this.displayName,
    required this.absolutePath,
    required this.size,
  });

  File get file => File(absolutePath);

  Map<String, dynamic> toMetaJson() {
    return {
      'id': id,
      'name': displayName,
      'size': size,
    };
  }
}

/// Temporary LAN web share session for guest browser downloads.
class WebShareSession {
  final String token;
  final List<WebShareFile> files;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? deviceName;

  const WebShareSession({
    required this.token,
    required this.files,
    required this.createdAt,
    required this.expiresAt,
    this.deviceName,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get totalSize => files.fold(0, (sum, f) => sum + f.size);

  WebShareFile? findFile(String fileId) {
    for (final file in files) {
      if (file.id == fileId) return file;
    }
    return null;
  }

  Map<String, dynamic> toMetaJson() {
    return {
      'token': token,
      'deviceName': deviceName,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'fileCount': files.length,
      'totalSize': totalSize,
      'files': files.map((f) => f.toMetaJson()).toList(),
    };
  }
}
