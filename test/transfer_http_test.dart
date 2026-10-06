import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/l10n/app_localizations.dart';
import 'package:icy_easy_send/l10n/current_localizations.dart';
import 'package:icy_easy_send/services/language_service.dart';
import 'package:icy_easy_send/services/transfer/transfer_http.dart';
import 'package:icy_easy_send/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

      expect(
        dio.options.connectTimeout?.inSeconds,
        AppConstants.requestTimeout,
      );
      expect(dio.options.sendTimeout, timeout);
      expect(dio.options.receiveTimeout, timeout);
      dio.close();
    });

    test('createForDownload sets receive timeout only', () {
      final dio = TransferHttp.createForDownload(AppConstants.bytesPerMB);
      final timeout = TransferHttp.transferTimeout(AppConstants.bytesPerMB);

      expect(
        dio.options.connectTimeout?.inSeconds,
        AppConstants.requestTimeout,
      );
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
        appText.relayTransferTimeout,
      );
      expect(
        TransferHttp.describeFailure(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.badResponse,
            message: 'boom',
          ),
          transport: TransferTransport.relay,
          direction: TransferDirection.download,
        ),
        appText.relayDownloadFailed('boom'),
      );
    });

    test('describeFailure follows the chosen app language', () async {
      SharedPreferences.setMockInitialValues({});
      addTearDown(() => LanguageService.instance.setLanguage('system'));
      await LanguageService.instance.setLanguage('ja');

      expect(
        TransferHttp.describeFailure(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionTimeout,
          ),
          transport: TransferTransport.relay,
        ),
        lookupAppLocalizations(const Locale('ja')).relayTransferTimeout,
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
        '${appText.networkConnectionFailed}\nrefused',
      );
      expect(
        TransferHttp.describeFailure(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.sendTimeout,
          ),
          transport: TransferTransport.lan,
        ),
        appText.transferTimeout,
      );
    });
  });
}
