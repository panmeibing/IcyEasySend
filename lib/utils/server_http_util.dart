import 'dart:convert';
import 'dart:io' show HttpConnectionInfo;
import 'dart:typed_data';

import 'package:shelf/shelf.dart';

import 'constants.dart';

/// Raised by [ServerHttpUtil.readJson] when a body exceeds its byte budget.
class RequestBodyTooLargeException implements Exception {
  const RequestBodyTooLargeException(this.limit);

  final int limit;

  @override
  String toString() => 'Request body exceeds $limit bytes';
}

/// Shared plumbing for the LAN server's shelf handlers.
class ServerHttpUtil {
  ServerHttpUtil._();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  static Response json(Map<String, Object?> body, {int status = 200}) {
    return Response(status, body: jsonEncode(body), headers: _jsonHeaders);
  }

  /// Address the request actually arrived from, as opposed to any address
  /// the caller wrote into its own body or query.
  static String? remoteAddress(Request request) {
    final info = request.context['shelf.io.connection_info'];
    return info is HttpConnectionInfo ? info.remoteAddress.address : null;
  }

  /// Decodes the body as JSON, reading at most [maxBytes].
  ///
  /// Anyone on the network can reach these endpoints, so the body is never
  /// buffered whole before its size is known to be reasonable.
  ///
  /// Throws [RequestBodyTooLargeException] or [FormatException].
  static Future<Object?> readJson(
    Request request, {
    int maxBytes = AppConstants.maxJsonBodyBytes,
  }) async {
    return jsonDecode(
      utf8.decode(await readBytes(request, maxBytes: maxBytes)),
    );
  }

  /// Reads the body, refusing anything over [maxBytes].
  ///
  /// Throws [RequestBodyTooLargeException].
  static Future<Uint8List> readBytes(
    Request request, {
    int maxBytes = AppConstants.maxJsonBodyBytes,
  }) async {
    final declared = request.contentLength;
    if (declared != null && declared > maxBytes) {
      throw RequestBodyTooLargeException(maxBytes);
    }

    final builder = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      if (builder.length + chunk.length > maxBytes) {
        throw RequestBodyTooLargeException(maxBytes);
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}
