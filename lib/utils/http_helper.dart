import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'error_messages.dart';
import 'log_util.dart';
import 'operation_result.dart';
import 'peer_error.dart';

/// Status and UTF-8 text of a control-plane response.
class HttpTextResponse {
  const HttpTextResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

/// HTTP request utility class, providing unified HTTP request encapsulation and error handling
///
/// Main functions:
/// - Unified timeout handling
/// - Unified exception capture and error messages
/// - Unified logging
/// - JSON response parsing
class HttpHelper {
  static final String logTag = LogTags.network;

  /// Every status comes back as a response, for callers to judge; only
  /// transport failures are errors.
  static final Dio _dio = Dio(
    BaseOptions(responseType: ResponseType.bytes, validateStatus: (_) => true),
  );

  /// Execute HTTP GET requests with unified error handling
  ///
  /// Parameters:
  /// - [url]: Request URL
  /// - [timeout]: Timeout period, default no timeout set
  /// - [headers]: Request Header
  ///
  /// Returns: [OperationResult<HttpTextResponse>] Contains response or error messages
  static Future<OperationResult<HttpTextResponse>> get(
    String url, {
    Duration? timeout,
    Map<String, String>? headers,
  }) {
    return _executeRequest('GET', url, headers: headers, timeout: timeout);
  }

  /// Execute HTTP POST requests with unified error handling
  ///
  /// Parameters:
  /// - [url]: Request URL
  /// - [headers]: Request Header
  /// - [body]: Request body, already encoded
  /// - [timeout]: Timeout period, default no timeout set
  ///
  /// Returns: [OperationResult<HttpTextResponse>] Contains response or error messages
  static Future<OperationResult<HttpTextResponse>> post(
    String url, {
    Map<String, String>? headers,
    String? body,
    Duration? timeout,
  }) {
    return _executeRequest(
      'POST',
      url,
      headers: headers,
      body: body,
      timeout: timeout,
    );
  }

  /// Universal request executor, a universal logic for handling all HTTP requests
  ///
  /// [timeout] bounds the whole exchange, not each phase of it.
  static Future<OperationResult<HttpTextResponse>> _executeRequest(
    String requestType,
    String url, {
    Map<String, String>? headers,
    String? body,
    Duration? timeout,
  }) async {
    final cancelToken = CancelToken();
    try {
      LogUtil.dTag(logTag, '[$requestType] $url');

      final request = _dio.request<List<int>>(
        url,
        data: body,
        options: Options(method: requestType, headers: headers),
        cancelToken: cancelToken,
      );
      final response = timeout == null
          ? await request
          : await request.timeout(
              timeout,
              onTimeout: () {
                cancelToken.cancel();
                throw TimeoutException(null, timeout);
              },
            );

      final statusCode = response.statusCode ?? 0;
      LogUtil.dTag(logTag, '[$requestType] $url - 状态码: $statusCode');
      return OperationResult.success(
        data: HttpTextResponse(
          statusCode,
          utf8.decode(response.data ?? const [], allowMalformed: true),
        ),
      );
    } on TimeoutException catch (e, stackTrace) {
      LogUtil.wTag(logTag, '[$requestType] $url - 超时', e, stackTrace);
      return OperationResult.failure(ErrorMessages.networkTimeout);
    } on DioException catch (e, stackTrace) {
      LogUtil.wTag(
        logTag,
        '[$requestType] $url - ${e.type.name}: ${e.error ?? e.message}',
        e,
        stackTrace,
      );
      return OperationResult.failure(_describe(e));
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '[$requestType] $url - 未知错误: $e', e, stackTrace);
      return OperationResult.failure(
        ErrorMessages.withDetails(ErrorMessages.networkRequestFailed, '$e'),
      );
    }
  }

  static String _describe(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ErrorMessages.networkTimeout;
      case DioExceptionType.connectionError:
        final cause = e.error;
        return ErrorMessages.withDetails(
          ErrorMessages.networkConnectionFailed,
          cause is SocketException ? cause.message : '${cause ?? e.message}',
        );
      default:
        return ErrorMessages.withDetails(
          ErrorMessages.networkRequestFailed,
          '${e.error ?? e.message}',
        );
    }
  }

  /// Parse JSON response
  ///
  /// Parameters:
  /// - [response]: HTTP response object
  ///
  /// Returns: [OperationResult<Map<String, dynamic>>] Contains parsed JSON data or error messages
  static OperationResult<Map<String, dynamic>> parseJsonResponse(
    HttpTextResponse response,
  ) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      LogUtil.dTag(logTag, 'JSON解析成功: ${data.keys.join(", ")}');
      return OperationResult.success(data: data);
    } catch (e, stackTrace) {
      LogUtil.wTag(
        logTag,
        'JSON解析失败: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...',
        e,
        stackTrace,
      );
      return OperationResult.failure(ErrorMessages.responseParseError);
    }
  }

  /// Check if the response status code is successful (200)
  ///
  /// Parameters:
  /// - [response]: HTTP response object
  ///
  /// Returns: true indicates success, false indicates failure
  static bool isSuccessResponse(HttpTextResponse response) {
    return response.statusCode == 200;
  }

  /// The peer's error, in this device's language, or [defaultMessage] when
  /// the body says nothing usable. See [PeerError.describeBody].
  static String extractErrorMessage(
    HttpTextResponse response,
    String defaultMessage,
  ) {
    try {
      final message = PeerError.describeBody(
        jsonDecode(response.body),
        defaultMessage,
      );
      LogUtil.dTag(logTag, '提取错误消息: $message');
      return message;
    } catch (e) {
      LogUtil.dTag(logTag, '无法提取错误消息，使用默认: $defaultMessage');
      return defaultMessage;
    }
  }
}
