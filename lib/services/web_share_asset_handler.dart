import 'package:flutter/services.dart';
import 'package:shelf/shelf.dart';

import '../utils/log_util.dart';

/// Serves bundled assets used by the guest web-share pages.
class WebShareAssetHandler {
  static const String logoAssetPath = 'lib/images/icon_256x256.png';
  static const String logoRoutePath = '/web-share/logo.png';

  final String logTag = LogTags.server;
  ByteData? _logoData;
  Future<ByteData?>? _loading;

  /// GET `/web-share/logo.png`
  Future<Response> handleLogo(Request request) async {
    final data = await _loadLogoData();
    if (data == null || data.lengthInBytes == 0) {
      return Response.notFound('Logo not found');
    }

    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return Response.ok(
      bytes,
      headers: {
        'Content-Type': 'image/png',
        'Cache-Control': 'public, max-age=86400',
      },
    );
  }

  Future<ByteData?> _loadLogoData() {
    if (_logoData != null) {
      return Future<ByteData?>.value(_logoData);
    }
    return _loading ??= _readLogoData();
  }

  Future<ByteData?> _readLogoData() async {
    try {
      _logoData = await rootBundle.load(logoAssetPath);
      return _logoData;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '加载网页分享 Logo 失败: $e', e, stackTrace);
      _loading = null;
      return null;
    }
  }
}
