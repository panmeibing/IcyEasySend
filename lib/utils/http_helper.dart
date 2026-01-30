import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'error_messages.dart';
import 'log_util.dart';
import 'operation_result.dart';

/// HTTP request utility class, providing unified HTTP request encapsulation and error handling
///
/// Main functions:
/// - Unified timeout handling
/// - Unified exception capture and error messages
/// - Unified logging
/// - JSON response parsing
class HttpHelper {
  static final String logTag = LogTags.network;

  /// Execute HTTP GET requests with unified error handling
  ///
  /// Parameters:
  /// - [url]: Request URL
  /// - [timeout]: Timeout period, default no timeout set
  /// - [headers]: Request Header
  ///
  /// Returns: [OperationResult<http.Response>] Contains response or error messages
  static Future<OperationResult<http.Response>> get(
    String url, {
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _executeRequest(
      () => http.get(Uri.parse(url), headers: headers),
      timeout: timeout,
      requestType: 'GET',
      url: url,
    );
  }

  /// Execute HTTP POST requests with unified error handling
  ///
  /// Parameters:
  /// - [url]: Request URL
  /// - [headers]: Request Header
  /// - [body]: Request body
  /// - [timeout]: Timeout period, default no timeout set
  ///
  /// Returns: [OperationResult<http.Response>] Contains response or error messages
  static Future<OperationResult<http.Response>> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    return _executeRequest(
      () => http.post(Uri.parse(url), headers: headers, body: body),
      timeout: timeout,
      requestType: 'POST',
      url: url,
    );
  }

  /// Universal request executor, a universal logic for handling all HTTP requests
  ///
  /// Unified processing:
  /// - Timeout Exception
  /// - Socket exception (network connection failure)
  /// - HTTP Exception
  /// - Other unknown anomalies
  /// - Log recording
  static Future<OperationResult<http.Response>> _executeRequest(
    Future<http.Response> Function() request, {
    Duration? timeout,
    required String requestType,
    required String url,
  }) async {
    try {
      LogUtil.dTag(logTag, '[$requestType] $url');

      final response = timeout != null
          ? await request().timeout(timeout)
          : await request();

      LogUtil.dTag(logTag, '[$requestType] $url - 状态码: ${response.statusCode}');
      return OperationResult.success(data: response);
    } on TimeoutException catch (e, stackTrace) {
      final error = ErrorMessages.networkTimeout;
      LogUtil.wTag(logTag, '[$requestType] $url - 超时', e, stackTrace);
      return OperationResult.failure(error);
    } on SocketException catch (e, stackTrace) {
      final error =
          '${ErrorMessages.networkConnectionFailed}\n详情: ${e.message}';
      LogUtil.wTag(
        logTag,
        '[$requestType] $url - Socket异常: ${e.message}',
        e,
        stackTrace,
      );
      return OperationResult.failure(error);
    } on http.ClientException catch (e, stackTrace) {
      final error = '${ErrorMessages.networkRequestFailed}\n详情: $e';
      LogUtil.wTag(logTag, '[$requestType] $url - Client异常: $e', e, stackTrace);
      return OperationResult.failure(error);
    } on HttpException catch (e, stackTrace) {
      final error = '${ErrorMessages.networkRequestFailed}\n详情: ${e.message}';
      LogUtil.wTag(
        logTag,
        '[$requestType] $url - HTTP异常: ${e.message}',
        e,
        stackTrace,
      );
      return OperationResult.failure(error);
    } catch (e, stackTrace) {
      final error = '${ErrorMessages.networkRequestFailed}\n详情: $e';
      LogUtil.eTag(logTag, '[$requestType] $url - 未知错误: $e', e, stackTrace);
      return OperationResult.failure(error);
    }
  }

  /// Parse JSON response
  ///
  /// Parameters:
  /// - [response]: HTTP response object
  ///
  /// Returns: [OperationResult<Map<String, dynamic>>] Contains parsed JSON data or error messages
  static OperationResult<Map<String, dynamic>> parseJsonResponse(
    http.Response response,
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
  static bool isSuccessResponse(http.Response response) {
    return response.statusCode == 200;
  }

  /// Extract error messages from responses
  ///
  /// Attempt to extract the 'message' field from the JSON response, and return a default error message if unsuccessful
  ///
  /// Parameters:
  /// - [response]: HTTP response object
  /// - [defaultMessage]: Default error message
  ///
  /// Returns: Error message string
  static String extractErrorMessage(
    http.Response response,
    String defaultMessage,
  ) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final message = data['message'] as String? ?? defaultMessage;
      LogUtil.dTag(logTag, '提取错误消息: $message');
      return message;
    } catch (e) {
      LogUtil.dTag(logTag, '无法提取错误消息，使用默认: $defaultMessage');
      return defaultMessage;
    }
  }
}
