import 'dart:math';

import 'package:path/path.dart' as path;

import '../models/transfer_file_item.dart';
import '../models/web_share_session.dart';
import '../utils/constants.dart';
import '../utils/log_util.dart';
import '../utils/network_util.dart';

/// Manages temporary LAN web-share sessions for guest browser downloads.
class WebShareService {
  WebShareService._();

  static final WebShareService instance = WebShareService._();

  final String logTag = LogTags.server;
  final Random _random = Random.secure();

  WebShareSession? _session;

  /// Currently active share session, or null if none / expired.
  WebShareSession? get activeSession {
    final session = _session;
    if (session == null) {
      return null;
    }
    if (session.isExpired) {
      LogUtil.iTag(logTag, '网页分享会话已过期，自动清理: ${session.token}');
      _session = null;
      return null;
    }
    return session;
  }

  bool get hasActiveSession => activeSession != null;

  /// Create a new share session from selected transfer items.
  ///
  /// Replaces any existing session. Only selected file paths are exposed.
  Future<WebShareSession> createSession({
    required List<TransferFileItem> items,
    Duration? ttl,
    String? deviceName,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Share session requires at least one file');
    }

    final resolvedDeviceName =
        deviceName ?? await NetworkUtil.getDeviceName();
    final createdAt = DateTime.now();
    final expiresAt =
        createdAt.add(ttl ?? AppConstants.webShareSessionDuration);
    final token = _generateToken();

    final files = <WebShareFile>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final file = item.file;
      if (!await file.exists()) {
        LogUtil.wTag(logTag, '跳过不存在的分享文件: ${file.path}');
        continue;
      }

      final size = await file.length();
      final displayName = item.transferName.isNotEmpty
          ? item.transferName
          : path.basename(file.path);

      files.add(
        WebShareFile(
          id: _generateFileId(i),
          displayName: displayName.replaceAll('\\', '/'),
          absolutePath: file.absolute.path,
          size: size,
        ),
      );
    }

    if (files.isEmpty) {
      throw StateError('No readable files available for web share');
    }

    final session = WebShareSession(
      token: token,
      files: files,
      createdAt: createdAt,
      expiresAt: expiresAt,
      deviceName: resolvedDeviceName,
    );

    _session = session;
    LogUtil.iTag(
      logTag,
      '创建网页分享会话: token=$token, files=${files.length}, expires=$expiresAt',
    );
    return session;
  }

  /// Look up a session by token. Returns null if missing or expired.
  WebShareSession? getSession(String token) {
    if (token.isEmpty) {
      return null;
    }
    final session = activeSession;
    if (session == null || session.token != token) {
      return null;
    }
    return session;
  }

  /// Stop the active session (or a specific token if provided).
  bool stopSession({String? token}) {
    final session = _session;
    if (session == null) {
      return false;
    }
    if (token != null && session.token != token) {
      return false;
    }
    _session = null;
    LogUtil.iTag(logTag, '已停止网页分享会话: ${session.token}');
    return true;
  }

  /// Clear all sessions (e.g. when HTTP server stops).
  void clearAll() {
    if (_session != null) {
      LogUtil.iTag(logTag, '清理网页分享会话: ${_session!.token}');
    }
    _session = null;
  }

  /// Build guest download page URL for the given server address (`IP:port`).
  ///
  /// Built without [NetworkUtil.buildHttpUrl] logging so UI timers can refresh
  /// quietly when the local IP changes.
  String buildShareUrl(String serverAddress, String token) {
    final base = serverAddress.contains(':')
        ? 'http://$serverAddress'
        : 'http://$serverAddress:${AppConstants.defaultPort}';
    return '$base/s/$token';
  }

  String _generateToken() {
    // 128-bit unguessable token encoded as hex.
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _generateFileId(int index) {
    final suffix = List<int>.generate(4, (_) => _random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${index.toRadixString(16).padLeft(2, '0')}$suffix';
  }
}
