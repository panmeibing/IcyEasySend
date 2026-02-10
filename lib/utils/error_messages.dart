/// ErrorMessages provides user-friendly Chinese error messages
/// for all error scenarios in the application.
///
/// All messages follow these principles:
/// - Clarity: Use simple, clear Chinese descriptions
/// - Actionability: Provide next steps the user can take
/// - Friendliness: Avoid technical jargon, use user-understandable language
/// - Consistency: All messages follow the same format and style
library;

import 'constants.dart';

class ErrorMessages {
  // Network errors (Requirement 10.1)
  static const String networkConnectionFailed = '无法连接到目标设备，请检查网络连接和 IP 地址';
  static const String networkTimeout = '连接超时，目标设备可能不在线或网络不稳定';
  static const String networkRequestFailed = '网络请求失败，请检查网络连接';
  static const String targetDeviceUnavailable = '目标设备不可用，请确认设备在线且 IP 地址正确';
  static const String transferTimeout = '传输超时，请检查网络连接';
  static const String transferInterrupted = '传输中断，请重试';

  // File system errors (Requirement 10.2)
  static const String fileNotFound = '文件不存在';
  static const String fileNotReadable = '无法读取文件，请确保文件存在且有访问权限';
  static const String fileAccessError = '文件访问错误，请检查文件权限';
  static const String fileSaveFailed = '文件保存失败';
  static const String fileSizeMismatch = '文件保存失败：文件大小不匹配';
  static const String invalidFileName = '文件名包含非法字符';
  static const String downloadsDirectoryUnavailable = '无法访问下载目录';

  // Storage errors (Requirement 10.3)
  static const String storageInsufficient = '存储空间不足，无法接收文件';
  static const String storageCheckFailed = '无法检查存储空间';

  // Permission errors (Requirement 10.4)
  static const String permissionDenied = '需要文件访问权限才能继续操作';
  static const String networkPermissionDenied = '需要网络访问权限才能传输文件';
  static const String storagePermissionDenied = '需要存储访问权限才能保存文件';

  // Server errors
  static String serverStartFailed(String reason) => '无法启动服务器：$reason';

  static String get serverPortsOccupied =>
      '无法启动服务器：端口 ${AppConstants.defaultPort}-${AppConstants.maxServerPort} 都已被占用';
  static const String serverUnknownError = '无法启动服务器：未知错误';

  // Transfer errors
  static const String transferRejected = '对方拒绝接收文件';
  static const String fileTooLarge = '文件过大，最大支持 2GB';
  static const String fileOrStorageFull = '文件过大或对方存储空间不足';
  static const String receiveTimeout = '接收超时，已自动拒绝';
  static const String userRejected = '用户拒绝接收文件';

  // Validation errors
  static const String ipAddressEmpty = 'IP 地址不能为空';
  static const String ipAddressInvalidFormat =
      'IP 地址格式无效，请使用 xxx.xxx.xxx.xxx 格式';
  static const String ipAddressInvalidRange = 'IP 地址格式无效，每个数字必须在 0-255 之间';
  static const String ipAddressSpecial1 = '不能使用 0.0.0.0 作为目标地址';
  static const String ipAddressSpecial2 = '不能使用广播地址 255.255.255.255';

  /// Warning message when target IP is not in the same subnet as local IP
  static String ipAddressNotInSameSubnet(String localIP, String targetIP) {
    // Extract network portion (first 3 octets)
    final localNetwork = localIP.split('.').take(3).join('.');
    final targetNetwork = targetIP.split('.').take(3).join('.');

    return '⚠️ 网段不匹配\n'
        '本机IP: $localIP (网段: $localNetwork.x)\n'
        '目标IP: $targetIP (网段: $targetNetwork.x)\n'
        '\n'
        '提示：两台设备需要在同一个局域网（相同网段）才能传输文件。\n'
        'C类IPv4地址应该保证两个IP地址的前三个数字相同，例如都是192.169.2，只是最后一个数字不同\n'
        '最简单的方法就是让两个设备都连接同一个WiFi或路由器。\n';
  }

  // Response parsing errors
  static const String responseParseError = '无法解析服务器响应';
  static const String responseInvalidFormat = '目标设备响应格式不正确';

  static String responseStatusCodeError(int statusCode) =>
      '服务器返回错误状态码: $statusCode';

  // File selection errors
  static const String fileSelectionError = '选择文件时出错';
  static const String fileSelectionCancelled = '已取消选择文件';

  // Generic errors
  static String genericError(String operation) => '$operation失败';

  static String unexpectedError(String details) => '发生意外错误: $details';

  /// Format a network error message with additional context
  static String networkError(String context) {
    return '网络错误: $context';
  }

  /// Format a file error message with additional context
  static String fileError(String context) {
    return '文件错误: $context';
  }

  /// Format a permission error message with specific permission type
  static String permissionError(String permissionType) {
    return '需要$permissionType权限才能继续操作';
  }

  /// Get a user-friendly error message from an exception
  static String fromException(Exception e, {String? context}) {
    final message = e.toString();

    // Try to extract meaningful error message
    if (message.contains('SocketException')) {
      return networkConnectionFailed;
    } else if (message.contains('TimeoutException')) {
      return networkTimeout;
    } else if (message.contains('FileSystemException')) {
      return fileAccessError;
    } else if (message.contains('PermissionDeniedException')) {
      return permissionDenied;
    }

    // Return generic error with context if available
    if (context != null) {
      return '$context: $message';
    }

    return unexpectedError(message);
  }
}
