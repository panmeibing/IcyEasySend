/// General operation result class
class OperationResult<T> {
  final bool success;
  final String? errorMessage;
  final T? data;
  final Map<String, dynamic>? metadata;

  const OperationResult({
    required this.success,
    this.errorMessage,
    this.data,
    this.metadata,
  });

  factory OperationResult.success({T? data, Map<String, dynamic>? metadata}) {
    return OperationResult(success: true, data: data, metadata: metadata);
  }

  factory OperationResult.failure(String errorMessage) {
    return OperationResult(success: false, errorMessage: errorMessage);
  }

  bool get isSuccess => success;

  bool get isFailure => !success;
}

/// File transfer result data
class TransferData {
  final String? savedPath;
  final int? bytesTransferred;
  final Duration? duration;

  const TransferData({this.savedPath, this.bytesTransferred, this.duration});
}

/// Health check result data
class HealthCheckData {
  final String deviceName;
  final String version;
  final bool isReady;

  const HealthCheckData({
    required this.deviceName,
    required this.version,
    required this.isReady,
  });
}
