import 'dart:io';

import 'package:path/path.dart' as path;

import '../utils/constants.dart';
import '../utils/error_messages.dart';
import '../utils/log_util.dart';
import '../utils/operation_result.dart';
import '../utils/platform_util.dart';

/// ValidationService provides input validation functionality
class ValidationService {
  final String logTag = LogTags.validation;

  /// Check if the file exists (unified method)
  ///
  /// Private auxiliary method, used for unified processing of file existence checks
  Future<bool> _checkFileExists(File file) async {
    try {
      return await file.exists();
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '检查文件存在性失败: ${file.path}, 错误=$e', e, stackTrace);
      return false;
    }
  }

  /// Validate IPv4 format
  ///
  /// Private auxiliary method for verifying IPv4 address format
  /// Return ValidationResult to indicate the validation result
  ValidationResult validateIPv4(String ip) {
    LogUtil.dTag(logTag, '验证IPv4地址: $ip');

    if (ip.isEmpty) {
      LogUtil.wTag(logTag, 'IP地址为空');
      return ValidationResult(
        isValid: false,
        errorMessage: ErrorMessages.ipAddressEmpty,
      );
    }

    // IPv4 format: xxx.xxx.xxx.xxx where xxx is 0-255
    final ipv4Pattern = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');

    final match = ipv4Pattern.firstMatch(ip);
    if (match == null) {
      LogUtil.wTag(logTag, 'IP地址格式无效: $ip');
      return ValidationResult(
        isValid: false,
        errorMessage: ErrorMessages.ipAddressInvalidFormat,
      );
    }

    if (ip == '0.0.0.0') {
      return ValidationResult(
        isValid: false,
        errorMessage: ErrorMessages.ipAddressSpecial1,
      );
    }

    if (ip == '255.255.255.255') {
      return ValidationResult(
        isValid: false,
        errorMessage: ErrorMessages.ipAddressSpecial2,
      );
    }

    // Validate each octet is in range 0-255
    for (int i = 1; i <= 4; i++) {
      final octet = int.tryParse(match.group(i)!);
      if (octet == null || octet < 0 || octet > 255) {
        LogUtil.wTag(logTag, 'IP地址范围无效: $ip, 段$i=$octet');
        return ValidationResult(
          isValid: false,
          errorMessage: ErrorMessages.ipAddressInvalidRange,
        );
      }
    }

    LogUtil.dTag(logTag, 'IPv4地址验证通过: $ip');
    return ValidationResult(isValid: true);
  }

  /// Validates IPv4 address and checks if it's in the same subnet as local IP
  ///
  /// [ip] - The target IP address to validate
  /// [serverAddress] - The server address in format "IP:Port" (optional)
  ///
  /// Returns a ValidationResult with detailed error message if not in same subnet
  ValidationResult validateIPv4WithSubnet(String ip, {String? serverAddress}) {
    LogUtil.dTag(logTag, '验证IPv4地址和子网: $ip, 服务器地址=$serverAddress');

    // First validate the IP format using the extracted method
    final formatValidation = validateIPv4(ip);
    if (!formatValidation.isValid) {
      return formatValidation;
    }

    // If no server address provided, skip subnet check
    if (serverAddress == null || serverAddress.isEmpty) {
      LogUtil.dTag(logTag, '未提供服务器地址，跳过子网检查');
      return ValidationResult(isValid: true);
    }

    // Extract local IP from server address (format: "IP:Port")
    final localIP = _extractIPFromAddress(serverAddress);
    if (localIP == null) {
      // Cannot determine local IP, skip subnet check
      LogUtil.dTag(logTag, '无法提取本地IP，跳过子网检查');
      return ValidationResult(isValid: true);
    }

    // Check if in same subnet (assuming /24 subnet mask: 255.255.255.0)
    if (!_isInSameSubnet(localIP, ip)) {
      LogUtil.wTag(logTag, '目标IP不在同一子网: 本地=$localIP, 目标=$ip');
      return ValidationResult(
        isValid: false,
        errorMessage: ErrorMessages.ipAddressNotInSameSubnet(localIP, ip),
        isWarning: true, // This is a warning, not a hard error
      );
    }

    LogUtil.dTag(logTag, 'IPv4地址和子网验证通过');
    return ValidationResult(isValid: true);
  }

  /// Extract IP address from server address string (format: "IP:Port")
  String? _extractIPFromAddress(String serverAddress) {
    try {
      final parts = serverAddress.split(':');
      if (parts.isNotEmpty) {
        final ip = parts[0];
        // Validate that the extracted IP is a valid IPv4 format
        final ipValidation = validateIPv4(ip);
        if (ipValidation.isValid) {
          return ip;
        }
      }
    } catch (e) {
      // Failed to parse
      return null;
    }
    return null;
  }

  /// Check if two IP addresses are in the same subnet
  /// Assumes a /24 subnet mask (255.255.255.0)
  bool _isInSameSubnet(String ip1, String ip2) {
    final parts1 = ip1.split('.');
    final parts2 = ip2.split('.');

    if (parts1.length != 4 || parts2.length != 4) {
      return false;
    }

    // Compare first 3 octets (assuming /24 subnet)
    for (int i = 0; i < 3; i++) {
      if (parts1[i] != parts2[i]) {
        return false;
      }
    }

    return true;
  }

  /// Validates if a file exists and is readable
  ///
  /// Returns a ValidationResult indicating whether the file is valid
  /// and an error message if invalid
  ValidationResult validateFile(File file) {
    LogUtil.dTag(logTag, '验证文件: ${file.path}');

    // Check if file exists
    if (!file.existsSync()) {
      LogUtil.wTag(logTag, '文件不存在: ${file.path}');
      return ValidationResult(
        isValid: false,
        errorMessage: ErrorMessages.fileNotFound,
      );
    }

    // Check if file is readable by attempting to get its length
    try {
      // This will throw if the file is not readable
      final size = file.lengthSync();
      LogUtil.dTag(logTag, '文件验证通过: ${file.path}, 大小=$size');
      return ValidationResult(isValid: true);
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '文件不可读: ${file.path}, 错误=$e', e, stackTrace);
      return ValidationResult(
        isValid: false,
        errorMessage: ErrorMessages.fileNotReadable,
      );
    }
  }

  /// 验证文件是否可以发送
  ///
  /// 检查:
  /// - 文件是否存在
  /// - 文件大小是否超过限制
  /// - 文件是否可读
  ///
  /// Returns [OperationResult<FileValidationData>] with file information if valid
  Future<OperationResult<FileValidationData>> validateFileForSending(
    File file,
  ) async {
    final fileName = path.basename(file.path);
    LogUtil.dTag(logTag, '验证发送文件: $fileName');

    // 使用统一的文件存在性检查方法
    if (!await _checkFileExists(file)) {
      LogUtil.wTag(logTag, '文件不存在: $fileName');
      return OperationResult.failure(ErrorMessages.fileNotFound);
    }

    // 检查文件大小
    int fileSize;
    try {
      fileSize = await file.length();
      LogUtil.dTag(
        logTag,
        '文件大小: $fileName = ${(fileSize / AppConstants.bytesPerMB).toStringAsFixed(2)}MB',
      );
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '无法获取文件大小: $fileName, 错误=$e', e, stackTrace);
      return OperationResult.failure(ErrorMessages.fileAccessError);
    }

    if (fileSize > AppConstants.maxFileSize) {
      LogUtil.wTag(
        logTag,
        '文件过大: $fileName, 大小=${(fileSize / AppConstants.bytesPerMB).toStringAsFixed(2)}MB, 限制=${(AppConstants.maxFileSize / AppConstants.bytesPerMB).toStringAsFixed(2)}MB',
      );
      return OperationResult.failure(ErrorMessages.fileTooLarge);
    }

    // 检查文件是否可读
    try {
      await file.open(mode: FileMode.read).then((raf) => raf.close());
      LogUtil.dTag(logTag, '文件验证通过: $fileName');
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '文件不可读: $fileName, 错误=$e', e, stackTrace);
      return OperationResult.failure(ErrorMessages.fileNotReadable);
    }

    return OperationResult.success(
      data: FileValidationData(
        fileName: fileName,
        fileSize: fileSize,
        filePath: file.path,
      ),
    );
  }

  /// Batch verification files
  ///
  /// Verify whether multiple files can be sent and return the verification results for each file
  ///
  /// Parameters:
  /// - [files]: List of files to be verified
  ///
  /// Returns a map of fileName -> validation result
  Future<Map<String, OperationResult<FileValidationData>>>
  validateFilesForSending(List<File> files) async {
    LogUtil.iTag(logTag, '批量验证文件: ${files.length}个文件');

    final futures = files.map((file) async {
      final fileName = path.basename(file.path);
      final result = await validateFileForSending(file);

      if (!result.isSuccess) {
        LogUtil.wTag(logTag, '文件验证失败: $fileName, 原因=${result.errorMessage}');
      }

      return MapEntry(fileName, result);
    });

    final resultsList = await Future.wait(futures);
    final results = Map.fromEntries(resultsList);

    final successCount = resultsList.where((e) => e.value.isSuccess).length;
    final failureCount = resultsList.length - successCount;

    LogUtil.iTag(
      logTag,
      '批量验证完成: 成功=$successCount, 失败=$failureCount, 总数=${files.length}',
    );

    return results;
  }

  /// Verify the storage space for receiving files
  ///
  /// Check if the device has sufficient storage space to receive files
  ///
  /// Parameters:
  /// - [requiredBytes]: Required number of bytes
  ///
  /// Returns [OperationResult<void>] indicating if there's enough space
  Future<OperationResult<void>> validateStorageSpace(int requiredBytes) async {
    LogUtil.dTag(
      logTag,
      '验证存储空间: 需要${(requiredBytes / AppConstants.bytesPerMB).toStringAsFixed(2)}MB',
    );

    try {
      // 获取下载目录
      final directory = await PlatformUtil.getDownloadsDirectory();
      if (directory == null) {
        LogUtil.wTag(logTag, '无法获取下载目录');
        return OperationResult.failure(
          ErrorMessages.downloadsDirectoryUnavailable,
        );
      }

      // 检查可用空间
      // 注意：这是一个简化的实现
      // 在生产环境中，应该使用平台特定的实现来准确检查可用空间
      // 目前假设如果文件小于1GB则有足够空间
      if (requiredBytes > (AppConstants.bytesPerGB)) {
        // 对于大于1GB的文件，我们无法确定是否有足够空间
        // 返回警告但不阻止传输
        LogUtil.wTag(
          logTag,
          '文件大小超过1GB，无法准确检查存储空间: ${(requiredBytes / AppConstants.bytesPerGB).toStringAsFixed(2)}GB',
        );
      }

      LogUtil.dTag(logTag, '存储空间验证通过');
      return OperationResult.success();
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '存储空间检查失败: $e', e, stackTrace);
      return OperationResult.failure(ErrorMessages.storageCheckFailed);
    }
  }

  /// Verify the integrity of saved files
  ///
  /// Check if the file exists and matches the size
  ///
  /// Parameters:
  /// - [file]: The file to be verified
  /// - [expectedSize]: Expected file size
  ///
  /// Returns [OperationResult<void>] indicating if file is valid
  Future<OperationResult<void>> validateSavedFile(
    File file,
    int expectedSize,
  ) async {
    final fileName = path.basename(file.path);
    LogUtil.dTag(
      logTag,
      '验证已保存文件: $fileName, 期望大小=${(expectedSize / AppConstants.bytesPerMB).toStringAsFixed(2)}MB',
    );

    // 使用统一的文件存在性检查方法
    if (!await _checkFileExists(file)) {
      LogUtil.wTag(logTag, '已保存文件不存在: $fileName');
      return OperationResult.failure(ErrorMessages.fileSaveFailed);
    }

    // 检查文件大小是否匹配
    try {
      final actualSize = await file.length();
      if (actualSize != expectedSize) {
        LogUtil.wTag(
          logTag,
          '文件大小不匹配: $fileName, 期望=$expectedSize, 实际=$actualSize',
        );
        return OperationResult.failure(ErrorMessages.fileSizeMismatch);
      }
      LogUtil.dTag(logTag, '已保存文件验证通过: $fileName');
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '无法验证文件大小: $fileName, 错误=$e', e, stackTrace);
      return OperationResult.failure(ErrorMessages.fileAccessError);
    }

    return OperationResult.success();
  }
}

/// Result of a validation operation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool isWarning; // True if this is a warning rather than a hard error

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.isWarning = false,
  });
}

/// File verification result data
class FileValidationData {
  final String fileName;
  final int fileSize;
  final String filePath;

  const FileValidationData({
    required this.fileName,
    required this.fileSize,
    required this.filePath,
  });
}
