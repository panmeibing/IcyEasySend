import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';

import '../utils/log_util.dart';
import '../utils/web_share_http_util.dart';
import 'web_share_page_builder.dart';
import 'web_share_service.dart';

/// HTTP handlers for guest web-share download pages.
class WebShareHandler {
  final WebShareService _shareService;
  final String logTag = LogTags.server;

  WebShareHandler({WebShareService? shareService})
    : _shareService = shareService ?? WebShareService.instance;

  /// GET `/s/{token}` — mobile-friendly download page.
  Future<Response> handleSharePage(Request request, String token) async {
    if (!WebShareHttpUtil.isValidToken(token)) {
      return _gonePage();
    }

    final session = _shareService.getSession(token);
    if (session == null) {
      return _gonePage();
    }

    return Response.ok(
      WebSharePageBuilder.buildDownloadPage(
        session,
        preferChinese: _preferChinese(request),
      ),
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-store',
      },
    );
  }

  /// GET `/s/{token}/meta` — JSON file list.
  Future<Response> handleShareMeta(Request request, String token) async {
    if (!WebShareHttpUtil.isValidToken(token)) {
      return Response(
        410,
        body: jsonEncode({'error': 'Share link expired or not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final session = _shareService.getSession(token);
    if (session == null) {
      return Response(
        410,
        body: jsonEncode({'error': 'Share link expired or not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode(session.toMetaJson()),
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-store',
      },
    );
  }

  /// GET `/s/{token}/file/{fileId}` — stream a single file download.
  Future<Response> handleFileDownload(
    Request request,
    String token,
    String fileId,
  ) async {
    if (!WebShareHttpUtil.isValidToken(token)) {
      return Response(
        410,
        body: 'Share link expired or not found',
        headers: {'Content-Type': 'text/plain; charset=utf-8'},
      );
    }

    if (!WebShareHttpUtil.isValidFileId(fileId)) {
      LogUtil.wTag(logTag, '拒绝非法网页分享文件ID: $fileId');
      return Response.forbidden('Invalid file id');
    }

    final session = _shareService.getSession(token);
    if (session == null) {
      return Response(
        410,
        body: 'Share link expired or not found',
        headers: {'Content-Type': 'text/plain; charset=utf-8'},
      );
    }

    final shareFile = session.findFile(fileId);
    if (shareFile == null) {
      return Response.notFound('File not found');
    }

    final file = shareFile.file;
    final fileName = path.basename(shareFile.displayName);

    try {
      if (!await file.exists()) {
        LogUtil.wTag(logTag, '网页分享文件不存在: ${shareFile.absolutePath}');
        return Response.notFound('File no longer available');
      }

      // Live size keeps Content-Length aligned with the stream body.
      final fileSize = await file.length();
      final contentDisposition =
          WebShareHttpUtil.buildContentDisposition(fileName);

      LogUtil.iTag(
        logTag,
        '网页分享下载: token=$token, file=$fileName, size=$fileSize',
      );

      // Always use octet-stream so mobile browsers download instead of
      // inline-previewing images/PDFs.
      return Response.ok(
        file.openRead(),
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': fileSize.toString(),
          'Content-Disposition': contentDisposition,
          'Cache-Control': 'no-store',
          'X-Content-Type-Options': 'nosniff',
        },
      );
    } on FileSystemException catch (e, stackTrace) {
      LogUtil.eTag(
        logTag,
        '网页分享读取文件失败: ${shareFile.absolutePath}: $e',
        e,
        stackTrace,
      );
      return Response.internalServerError(
        body: 'Failed to read file',
        headers: {'Content-Type': 'text/plain; charset=utf-8'},
      );
    }
  }

  /// Exposed for unit tests.
  static String buildContentDisposition(String fileName) =>
      WebShareHttpUtil.buildContentDisposition(fileName);

  bool _preferChinese(Request request) {
    final accept = request.headers['accept-language']?.toLowerCase() ?? '';
    return accept.contains('zh');
  }

  Response _gonePage() {
    return Response(
      410,
      body: WebSharePageBuilder.buildGonePage(),
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-store',
      },
    );
  }
}
