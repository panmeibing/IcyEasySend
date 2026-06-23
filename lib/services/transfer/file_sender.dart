import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import '../../models/transfer_data.dart';
import '../../utils/constants.dart';
import '../../utils/error_messages.dart';
import '../../utils/log_util.dart';
import '../../utils/operation_result.dart';
import 'transfer_request_builder.dart';

/// Service for sending files to target devices
class FileSender {
  final TransferRequestBuilder _requestBuilder;
  final Dio Function(int fileSize)? _dioFactory;
  final String logTag = LogTags.transfer;

  FileSender({
    TransferRequestBuilder? requestBuilder,
    Dio Function(int fileSize)? dioFactory,
  }) : _requestBuilder = requestBuilder ?? TransferRequestBuilder(),
       _dioFactory = dioFactory;

  /// Send a file with a pre-obtained transfer ID
  ///
  /// Note: This method does NOT save transfer history.
  /// The caller is responsible for collecting results and saving history in batch.
  ///
  /// Progress reporting semantics:
  ///   0%–99% → bytes actually sent by Dio ([onSendProgress])
  ///   99%    → all data has been sent; waiting for the receiver to finish
  ///            writing and acknowledge via HTTP 200
  ///   100%   → receiver confirmed successful receipt (HTTP 200 OK received)
  Future<OperationResult<TransferData>> sendFileWithTransferId({
    required String targetIP,
    required File file,
    required String transferId,
    required String senderIP,
    String? deviceName,
    String? secretKey,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    String? transferName,
  }) async {
    final fileName = transferName != null && transferName.isNotEmpty
        ? transferName
        : path.basename(file.path);
    int fileSize = 0;

    try {
      fileSize = await file.length();
    } catch (e) {
      LogUtil.eTag(
        logTag,
        'Failed to get file size for $fileName: ${e.toString()}',
      );
      return OperationResult.failure('无法读取文件大小: ${e.toString()}');
    }

    LogUtil.iTag(
      logTag,
      "sendFileWithTransferId() transferId: [$transferId], targetIP: [$targetIP], fileSize: [$fileSize], fileName: [$fileName]",
    );

    final dio = _dioFactory?.call(fileSize) ?? _createDio(fileSize);

    try {
      final uri = _requestBuilder.buildTransferUri(
        targetIP: targetIP,
        fileName: fileName,
        fileSize: fileSize,
        senderIP: senderIP,
        deviceName: deviceName,
        transferId: transferId,
      );
      final headers = _requestBuilder.buildTransferHeaders(
        fileSize: fileSize,
        secretKey: secretKey,
      );

      if (fileSize == 0) {
        onProgress?.call(0.0, 0, 0);
      }

      final response = await dio.post<String>(
        uri.toString(),
        data: fileSize == 0 ? const <int>[] : file.openRead(),
        options: Options(
          headers: headers,
          contentType: 'application/octet-stream',
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null,
        ),
        onSendProgress: fileSize == 0
            ? null
            : (sent, total) {
                final effectiveTotal = total > 0 ? total : fileSize;
                final rawProgress = sent / effectiveTotal;
                final cappedProgress = rawProgress * _kStreamingProgressCap;
                onProgress?.call(cappedProgress, sent, effectiveTotal);
              },
      );

      LogUtil.dTag(
        logTag,
        'All bytes sent for $fileName; waiting for receiver ACK...',
      );

      final result = await _handleTransferResponse(
        statusCode: response.statusCode ?? 0,
        responseBody: response.data ?? '',
        fileName: fileName,
        fileSize: fileSize,
        targetIP: targetIP,
        deviceName: deviceName,
      );

      if (result.isSuccess) {
        onProgress?.call(1.0, fileSize, fileSize);
      }

      return result;
    } on DioException catch (e, stackTrace) {
      return _handleDioException(e, stackTrace, fileName);
    } on FileSystemException catch (e) {
      LogUtil.eTag(logTag, 'File system error for $fileName: ${e.toString()}');
      return OperationResult.failure('文件访问错误: ${e.message}');
    } catch (e, stackTrace) {
      LogUtil.eTag(
        logTag,
        'Unexpected error sending file $fileName: ${e.toString()}',
        e,
        stackTrace,
      );
      return OperationResult.failure(
        ErrorMessages.unexpectedError(e.toString()),
      );
    }
  }

  static const double _kStreamingProgressCap = 0.99;

  Dio _createDio(int fileSize) {
    final transferTimeout = _transferTimeout(fileSize);
    return Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: AppConstants.requestTimeout),
        sendTimeout: transferTimeout,
        receiveTimeout: transferTimeout,
      ),
    );
  }

  Duration _transferTimeout(int fileSize) {
    return Duration(seconds: fileSize ~/ (AppConstants.bytesPerMB)) +
        Duration(seconds: AppConstants.requestTimeout);
  }

  OperationResult<TransferData> _handleDioException(
    DioException e,
    StackTrace stackTrace,
    String fileName,
  ) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        LogUtil.eTag(logTag, 'Timeout sending file $fileName: ${e.message}');
        return OperationResult.failure('文件传输超时');
      case DioExceptionType.connectionError:
        final error = e.error;
        if (error is SocketException) {
          LogUtil.eTag(
            logTag,
            'Socket error sending file $fileName: ${error.toString()}',
          );
          return OperationResult.failure('网络连接失败\n错误: ${error.message}');
        }
        LogUtil.eTag(
          logTag,
          'Connection error sending file $fileName: ${e.message}',
          e,
          stackTrace,
        );
        return OperationResult.failure('网络连接失败\n错误: ${e.message}');
      case DioExceptionType.cancel:
        LogUtil.wTag(logTag, 'Upload cancelled for $fileName');
        return OperationResult.failure('文件传输已取消');
      default:
        LogUtil.eTag(
          logTag,
          'Dio error sending file $fileName: ${e.message}',
          e,
          stackTrace,
        );
        return OperationResult.failure('网络请求失败: ${e.message}');
    }
  }

  /// Handle server response
  Future<OperationResult<TransferData>> _handleTransferResponse({
    required int statusCode,
    required String responseBody,
    required String fileName,
    required int fileSize,
    required String targetIP,
    String? deviceName,
  }) async {
    if (statusCode != 200) {
      try {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return OperationResult.failure(data['message'] as String? ?? '文件传输失败');
      } catch (e) {
        LogUtil.eTag(logTag, e.toString());
        return OperationResult.failure('文件传输失败\n状态码: $statusCode');
      }
    }

    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final savedPath = data['savedPath'] as String?;

      return OperationResult.success(
        data: TransferData(savedPath: savedPath, bytesTransferred: fileSize),
      );
    } catch (e) {
      LogUtil.eTag(logTag, e.toString());
      return OperationResult.failure('无法解析响应\n错误: $e');
    }
  }
}
