import 'dart:io';

import 'package:dio/dio.dart';

import '../../l10n/current_localizations.dart';
import '../../utils/constants.dart';

/// Which transport produced a data-plane HTTP request.
enum TransferTransport { lan, relay }

enum TransferDirection { upload, download }

/// Shared Dio setup for LAN and relay file transfers.
///
/// [transferTimeout] is the short budget relay signaling still waits on.
/// LAN uploads leave the body timeout unset and fail only when a file goes
/// silent for [AppConstants.transferStallTimeout].
class TransferHttp {
  TransferHttp._();

  /// Budgets one second per megabyte on top of the base timeout.
  static Duration transferTimeout(int fileSize) {
    return Duration(seconds: fileSize ~/ AppConstants.bytesPerMB) +
        Duration(seconds: AppConstants.requestTimeout);
  }

  /// Dio for an upload POST, whether to `/transfer` on the LAN or
  /// `/v1/stream/{id}` on a relay.
  ///
  /// [timeout] overrides the send and receive limits. Relay uploads keep
  /// [transferTimeout]. LAN uploads pass [unbounded] so a slow but still
  /// moving transfer is not cut off by a wall-clock budget.
  static Dio createForUpload(
    int fileSize, {
    Duration? timeout,
    bool unbounded = false,
  }) {
    final Duration? effective = unbounded
        ? null
        : (timeout ?? transferTimeout(fileSize));
    return Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: AppConstants.requestTimeout),
        sendTimeout: effective,
        receiveTimeout: effective,
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
    TransferDirection direction = TransferDirection.upload,
  }) {
    final lan = transport == TransferTransport.lan;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return lan ? appText.transferTimeout : appText.relayTransferTimeout;
      case DioExceptionType.connectionError:
        if (lan) {
          final socketError = error.error;
          final detail = socketError is SocketException
              ? socketError.message
              : error.message;
          return '${appText.networkConnectionFailed}\n$detail';
        }
        return '${appText.relayUnreachable}\n${error.message}';
      case DioExceptionType.cancel:
        return appText.transferCancelled;
      default:
        final detail = '${error.message}';
        if (lan) return '${appText.networkRequestFailed}\n$detail';
        return direction == TransferDirection.upload
            ? appText.relayUploadFailed(detail)
            : appText.relayDownloadFailed(detail);
    }
  }
}
