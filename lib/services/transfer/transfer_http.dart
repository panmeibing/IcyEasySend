import 'dart:io';

import 'package:dio/dio.dart';

import '../../utils/constants.dart';

/// Which transport produced a data-plane HTTP request.
enum TransferTransport {
  lan,
  relay,
}

/// Shared Dio setup for LAN and relay file transfers.
///
/// Both paths budget one second per megabyte on top of the base request
/// timeout. Centralising that here keeps send and receive aligned regardless
/// of whether bytes go over the LAN or through a relay.
class TransferHttp {
  TransferHttp._();

  /// Budgets one second per megabyte on top of the base timeout.
  static Duration transferTimeout(int fileSize) {
    return Duration(seconds: fileSize ~/ AppConstants.bytesPerMB) +
        Duration(seconds: AppConstants.requestTimeout);
  }

  /// Dio for an upload POST, whether to `/transfer` on the LAN or
  /// `/v1/stream/{id}` on a relay.
  static Dio createForUpload(int fileSize) {
    final timeout = transferTimeout(fileSize);
    return Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: AppConstants.requestTimeout),
        sendTimeout: timeout,
        receiveTimeout: timeout,
      ),
    );
  }

  /// Dio for a relay download GET on `/v1/stream/{id}`.
  static Dio createForDownload(int fileSize) {
    final timeout = transferTimeout(fileSize);
    return Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: AppConstants.requestTimeout),
        receiveTimeout: timeout,
      ),
    );
  }

  /// Turns a [DioException] into user-facing text.
  static String describeFailure(
    DioException error, {
    required TransferTransport transport,
    String verb = '上传',
  }) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return transport == TransferTransport.lan
            ? '文件传输超时'
            : '中转传输超时';
      case DioExceptionType.connectionError:
        if (transport == TransferTransport.lan) {
          final socketError = error.error;
          if (socketError is SocketException) {
            return '网络连接失败\n错误: ${socketError.message}';
          }
          return '网络连接失败\n错误: ${error.message}';
        }
        return '无法连接中转服务器\n错误: ${error.message}';
      case DioExceptionType.cancel:
        return '文件传输已取消';
      default:
        return transport == TransferTransport.lan
            ? '网络请求失败: ${error.message}'
            : '中转$verb失败: ${error.message}';
    }
  }
}
