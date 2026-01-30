import '../../utils/constants.dart';
import '../../utils/error_messages.dart';
import '../../utils/http_helper.dart';
import '../../utils/log_util.dart';
import '../../utils/network_util.dart';
import '../../utils/operation_result.dart';

/// Service for checking target device health
class HealthChecker {
  String logTag = LogTags.network;

  /// Check if target device is healthy and ready to receive files
  Future<OperationResult<HealthCheckData>> checkHealth(String targetIP) async {
    LogUtil.dTag(logTag, 'checkHealth() targetIP: $targetIP');

    final url = NetworkUtil.buildHttpUrl(targetIP, '/health');

    String separator = AppConstants.diagInfoSeparator;
    LogUtil.iTag(logTag, separator * 3);
    LogUtil.iTag(logTag, '开始健康检查');
    LogUtil.iTag(logTag, '目标URL: $url');
    LogUtil.iTag(logTag, '当前时间: ${DateTime.now()}');
    LogUtil.iTag(logTag, separator * 3);

    final result = await HttpHelper.get(
      url,
      timeout: Duration(seconds: AppConstants.checkHealthTimeout),
    );

    if (!result.isSuccess) {
      LogUtil.wTag(logTag, '请求失败: ${result.errorMessage}');
      return OperationResult.failure(result.errorMessage!);
    }

    final response = result.data!;
    LogUtil.iTag(logTag, '收到响应，状态码: ${response.statusCode}');
    LogUtil.dTag(logTag, '响应内容: ${response.body}');

    if (HttpHelper.isSuccessResponse(response)) {
      final parseResult = HttpHelper.parseJsonResponse(response);
      if (!parseResult.isSuccess) {
        LogUtil.eTag(logTag, '解析响应失败: ${parseResult.errorMessage}');
        return OperationResult.failure(parseResult.errorMessage!);
      }

      final data = parseResult.data!;

      if (data.containsKey('status') && data['status'] == 'ok') {
        LogUtil.iTag(logTag, '健康检查成功');
        final healthData = HealthCheckData(
          deviceName: data['deviceName'] as String? ?? 'Unknown',
          version: data['version'] as String? ?? 'Unknown',
          isReady: true,
        );
        return OperationResult.success(data: healthData, metadata: data);
      } else {
        LogUtil.wTag(logTag, '响应格式不正确: $data');
        return OperationResult.failure(ErrorMessages.responseInvalidFormat);
      }
    } else {
      LogUtil.wTag(logTag, '服务器返回错误状态码: ${response.statusCode}');
      return OperationResult.failure(
        ErrorMessages.responseStatusCodeError(response.statusCode),
      );
    }
  }
}

/// Health check data
class HealthCheckData {
  final String deviceName;
  final String version;
  final bool isReady;

  HealthCheckData({
    required this.deviceName,
    required this.version,
    required this.isReady,
  });
}
