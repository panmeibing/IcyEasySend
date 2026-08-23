import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/transfer/transfer_http.dart';
import 'package:icy_easy_send/utils/constants.dart';

void main() {
  group('TransferHttp', () {
    test('transferTimeout budgets one second per megabyte plus base', () {
      expect(
        TransferHttp.transferTimeout(0),
        Duration(seconds: AppConstants.requestTimeout),
      );
      expect(
        TransferHttp.transferTimeout(AppConstants.bytesPerMB),
        Duration(seconds: AppConstants.requestTimeout + 1),
      );
      expect(
        TransferHttp.transferTimeout(3 * AppConstants.bytesPerMB + 1),
        Duration(seconds: AppConstants.requestTimeout + 3),
      );
    });

    test('createForUpload sets send and receive timeouts', () {
      final dio = TransferHttp.createForUpload(AppConstants.bytesPerMB);
      final timeout = TransferHttp.transferTimeout(AppConstants.bytesPerMB);

      expect(dio.options.connectTimeout?.inSeconds, AppConstants.requestTimeout);
      expect(dio.options.sendTimeout, timeout);
      expect(dio.options.receiveTimeout, timeout);
      dio.close();
    });

    test('createForDownload sets receive timeout only', () {
      final dio = TransferHttp.createForDownload(AppConstants.bytesPerMB);
      final timeout = TransferHttp.transferTimeout(AppConstants.bytesPerMB);

      expect(dio.options.connectTimeout?.inSeconds, AppConstants.requestTimeout);
      expect(dio.options.sendTimeout, isNull);
      expect(dio.options.receiveTimeout, timeout);
      dio.close();
    });

    test('describeFailure maps relay timeout errors', () {
      expect(
        TransferHttp.describeFailure(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.receiveTimeout,
          ),
          transport: TransferTransport.relay,
        ),
        '中转传输超时',
      );
      expect(
        TransferHttp.describeFailure(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.badResponse,
            message: 'boom',
          ),
          transport: TransferTransport.relay,
          verb: '下载',
        ),
        '中转下载失败: boom',
      );
    });

    test('describeFailure maps LAN connection errors', () {
      expect(
        TransferHttp.describeFailure(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionError,
            error: const SocketException('refused'),
          ),
          transport: TransferTransport.lan,
        ),
        '网络连接失败\n错误: refused',
      );
      expect(
        TransferHttp.describeFailure(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.sendTimeout,
          ),
          transport: TransferTransport.lan,
        ),
        '文件传输超时',
      );
    });
  });
}
