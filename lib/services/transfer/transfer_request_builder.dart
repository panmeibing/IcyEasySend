import '../../utils/network_util.dart';

/// Builder for creating HTTP transfer requests
class TransferRequestBuilder {
  /// Build the target URI for a file transfer POST request.
  Uri buildTransferUri({
    required String targetIP,
    required String fileName,
    required int fileSize,
    required String senderIP,
    String? deviceName,
    required String transferId,
  }) {
    final baseUrl = NetworkUtil.buildHttpUrl(targetIP, '/transfer');
    return Uri.parse(baseUrl).replace(
      queryParameters: {
        'fileName': fileName,
        'fileSize': fileSize.toString(),
        'senderIP': senderIP,
        'senderDeviceName': deviceName,
        'transferId': transferId,
      },
    );
  }

  /// Build HTTP headers for a file transfer POST request.
  Map<String, String> buildTransferHeaders({
    required int fileSize,
    String? secretKey,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/octet-stream',
      'Content-Length': fileSize.toString(),
    };

    if (secretKey != null && secretKey.isNotEmpty) {
      headers['X-Secret-Key'] = secretKey;
    }

    return headers;
  }

  /// Build batch confirmation URL
  String buildBatchConfirmationUrl(String targetIP) {
    return NetworkUtil.buildHttpUrl(targetIP, '/batch-confirm-receive');
  }
}
