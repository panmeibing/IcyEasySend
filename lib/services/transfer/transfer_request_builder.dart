import 'package:http/http.dart' as http;

import '../../utils/network_util.dart';

/// Builder for creating HTTP transfer requests
class TransferRequestBuilder {
  /// Build HTTP streaming request for file transfer
  http.StreamedRequest buildTransferRequest({
    required String targetIP,
    required String fileName,
    required int fileSize,
    required String senderIP,
    String? deviceName,
    required String transferId,
  }) {
    final baseUrl = NetworkUtil.buildHttpUrl(targetIP, '/transfer');
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'fileName': fileName,
        'fileSize': fileSize.toString(),
        'senderIP': senderIP,
        if (deviceName != null) 'senderDeviceName': deviceName,
        'transferId': transferId,
      },
    );

    final request = http.StreamedRequest('POST', uri);
    request.headers['Content-Type'] = 'application/octet-stream';
    request.contentLength = fileSize;

    return request;
  }

  /// Build batch confirmation URL
  String buildBatchConfirmationUrl(String targetIP) {
    return NetworkUtil.buildHttpUrl(targetIP, '/batch-confirm-receive');
  }
}
