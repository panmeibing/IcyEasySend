import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../utils/log_util.dart';
import '../utils/constants.dart';
import 'notification_service.dart';
import 'transfer_history_service.dart';
import 'preferences_service.dart';
import '../utils/error_messages.dart';
import '../models/transfer_history.dart';

/// Result of health check operation
class HealthCheckResult {
  final bool isHealthy;
  final String? errorMessage;
  final Map<String, dynamic>? responseData;

  HealthCheckResult({
    required this.isHealthy,
    this.errorMessage,
    this.responseData,
  });
}

/// Result of file transfer operation
class TransferResult {
  final bool success;
  final String? errorMessage;
  final String? savedPath;

  TransferResult({required this.success, this.errorMessage, this.savedPath});
}

/// Result of file receive operation
class ReceiveResult {
  final bool accepted;
  final String? savedPath;
  final String? errorMessage;

  ReceiveResult({required this.accepted, this.savedPath, this.errorMessage});
}

/// Result of direct file receive operation (without confirmation)
class DirectReceiveResult {
  final bool success;
  final String? savedPath;
  final String? errorMessage;

  DirectReceiveResult({
    required this.success,
    this.savedPath,
    this.errorMessage,
  });
}

/// Result of confirmation request
class ConfirmationResult {
  final bool accepted;
  final String? errorMessage;
  final bool autoAcceptRemaining;

  ConfirmationResult({
    required this.accepted,
    this.errorMessage,
    this.autoAcceptRemaining = false,
  });
}

/// Service for handling file transfers (sender side)
///
/// Provides functionality to:
/// - Check health of target devices
/// - Send files to target devices
class FileTransferService {
  // Timeout for network requests
  static const Duration _requestTimeout = Duration(seconds: 10);

  // Timeout for confirmation requests (longer to allow user to respond)
  // User has 30 seconds to confirm, so we add 5 seconds buffer
  static const Duration _confirmTimeout = Duration(seconds: 35);

  // Maximum file size (2GB)
  static const int _maxFileSize = 2 * 1024 * 1024 * 1024;

  // Transfer history service
  final TransferHistoryService _historyService = TransferHistoryService();

  // Preferences service
  final PreferencesService _preferencesService = PreferencesService();

  /// Check if target device is healthy and ready to receive files
  ///
  /// Sends a GET request to the target device's /health endpoint.
  /// Returns [HealthCheckResult] indicating if the device is healthy.
  ///
  /// Parameters:
  /// - [targetIP]: IP address of the target device (format: "192.168.1.100:8080")
  ///
  Future<HealthCheckResult> checkHealth(String targetIP) async {
    try {
      // Ensure targetIP includes port, default to AppConstants.defaultPort if not specified
      String url;
      if (targetIP.contains(':')) {
        url = 'http://$targetIP/health';
      } else {
        url = 'http://$targetIP:${AppConstants.defaultPort}/health';
      }

      LogUtil.i('[Health Check] ========================================');
      LogUtil.i('[Health Check] 开始健康检查');
      LogUtil.i('[Health Check] 目标URL: $url');
      LogUtil.i('[Health Check] 当前时间: ${DateTime.now()}');
      LogUtil.i('[Health Check] ========================================');

      // Send GET request to health endpoint
      final response = await http.get(Uri.parse(url)).timeout(_requestTimeout);

      LogUtil.i('[Health Check] 收到响应，状态码: ${response.statusCode}');
      LogUtil.i('[Health Check] 响应内容: ${response.body}');

      // Check if response is successful
      if (response.statusCode == 200) {
        try {
          // Parse JSON response
          final data = jsonDecode(response.body) as Map<String, dynamic>;

          // Verify response contains expected fields
          if (data.containsKey('status') && data['status'] == 'ok') {
            LogUtil.i('[Health Check] 健康检查成功');
            return HealthCheckResult(isHealthy: true, responseData: data);
          } else {
            LogUtil.i('[Health Check] 响应格式不正确: $data');
            return HealthCheckResult(
              isHealthy: false,
              errorMessage: ErrorMessages.responseInvalidFormat,
            );
          }
        } catch (e) {
          LogUtil.i('[Health Check] 解析响应失败: $e');
          return HealthCheckResult(
            isHealthy: false,
            errorMessage: ErrorMessages.responseParseError,
          );
        }
      } else {
        LogUtil.i('[Health Check] 服务器返回错误状态码: ${response.statusCode}');
        return HealthCheckResult(
          isHealthy: false,
          errorMessage: ErrorMessages.responseStatusCodeError(
            response.statusCode,
          ),
        );
      }
    } on SocketException catch (e) {
      LogUtil.i('[Health Check] Socket异常: ${e.message}');
      LogUtil.i('[Health Check] 目标地址: $targetIP');
      return HealthCheckResult(
        isHealthy: false,
        errorMessage: '无法连接到目标设备\n错误: ${e.message}\nIP: $targetIP',
      );
    } on http.ClientException catch (e) {
      LogUtil.i('[Health Check] HTTP客户端异常: $e');
      return HealthCheckResult(isHealthy: false, errorMessage: '网络请求失败: $e');
    } on TimeoutException {
      LogUtil.i('[Health Check] 连接超时（10秒）');
      LogUtil.i('[Health Check] 目标地址: $targetIP');
      return HealthCheckResult(
        isHealthy: false,
        errorMessage: '连接超时（10秒）\n目标设备可能未运行或网络不通\nIP: $targetIP',
      );
    } catch (e, stackTrace) {
      LogUtil.i('[Health Check] 未预期的错误: $e');
      LogUtil.i('[Health Check] 堆栈跟踪: $stackTrace');
      return HealthCheckResult(
        isHealthy: false,
        errorMessage: '检查设备健康状态时出错: $e',
      );
    }
  }

  /// Send multiple files to the target device with batch confirmation
  ///
  /// This method first sends all file information to the receiver for confirmation,
  /// then sends files one by one after user accepts.
  ///
  /// Parameters:
  /// - [targetIP]: IP address of the target device (format: "192.168.1.100:8080")
  /// - [files]: List of files to send
  /// - [onProgress]: Optional callback for overall progress updates
  /// - [onFileProgress]: Optional callback for individual file progress (fileIndex, progress, bytes, total)
  /// - [onStatusChange]: Optional callback for status updates
  ///
  Future<Map<String, TransferResult>> sendFilesWithBatchConfirm({
    required String targetIP,
    required List<File> files,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    void Function(
      int fileIndex,
      double progress,
      int bytesTransferred,
      int totalBytes,
    )?
    onFileProgress,
    void Function(String status)? onStatusChange,
  }) async {
    final results = <String, TransferResult>{};

    if (files.isEmpty) {
      return results;
    }

    try {
      // Step 1: Perform health check
      onStatusChange?.call('正在检查目标设备...');
      final healthResult = await checkHealth(targetIP);
      if (!healthResult.isHealthy) {
        // Health check failed, return error for all files
        for (final file in files) {
          final fileName = file.path.split('/').last;
          results[fileName] = TransferResult(
            success: false,
            errorMessage: '目标设备不可用\n错误: ${healthResult.errorMessage}',
          );
        }
        return results;
      }

      // Step 2: Get local IP and device info
      onStatusChange?.call('准备传输信息...');
      final senderIP = await _getLocalIPAddress();
      String? deviceName = await _preferencesService.getDeviceName();
      if (deviceName == null || deviceName.isEmpty) {
        deviceName = await _getDeviceModel();
      }

      // Step 3: Prepare file list for batch confirmation
      final fileList = <Map<String, dynamic>>[];
      int totalBytes = 0;

      for (final file in files) {
        if (!await file.exists()) {
          final fileName = file.path.split('/').last;
          results[fileName] = TransferResult(
            success: false,
            errorMessage: ErrorMessages.fileNotFound,
          );
          continue;
        }

        final fileSize = await file.length();
        if (fileSize > _maxFileSize) {
          final fileName = file.path.split('/').last;
          results[fileName] = TransferResult(
            success: false,
            errorMessage: ErrorMessages.fileTooLarge,
          );
          continue;
        }

        totalBytes += fileSize;
        fileList.add({
          'fileName': file.path.split('/').last,
          'fileSize': fileSize,
        });
      }

      if (fileList.isEmpty) {
        return results; // All files failed validation
      }

      // Step 4: Send batch confirmation request
      onStatusChange?.call('等待接收方确认 ${fileList.length} 个文件...');

      String confirmUrl;
      if (targetIP.contains(':')) {
        confirmUrl = 'http://$targetIP/batch-confirm-receive';
      } else {
        confirmUrl =
            'http://$targetIP:${AppConstants.defaultPort}/batch-confirm-receive';
      }

      final confirmBody = jsonEncode({
        'files': fileList,
        'senderIP': senderIP,
        if (deviceName != null) 'senderDeviceName': deviceName,
      });

      http.Response confirmResponse;
      try {
        confirmResponse = await http
            .post(
              Uri.parse(confirmUrl),
              headers: {'Content-Type': 'application/json'},
              body: confirmBody,
            )
            .timeout(_confirmTimeout);
      } on TimeoutException {
        final errorMsg = '等待接收方确认超时（35秒）\n接收方可能未响应或网络连接问题';
        for (final fileData in fileList) {
          results[fileData['fileName'] as String] = TransferResult(
            success: false,
            errorMessage: errorMsg,
          );
        }
        return results;
      } on SocketException catch (e) {
        final errorMsg = '无法连接到接收方\n错误: ${e.message}';
        for (final fileData in fileList) {
          results[fileData['fileName'] as String] = TransferResult(
            success: false,
            errorMessage: errorMsg,
          );
        }
        return results;
      }

      // Check confirmation response
      if (confirmResponse.statusCode != 200) {
        String errorMsg;
        try {
          final data = jsonDecode(confirmResponse.body) as Map<String, dynamic>;
          errorMsg = data['message'] as String? ?? '接收方拒绝接收';
        } catch (e) {
          errorMsg = '接收方拒绝接收\n状态码: ${confirmResponse.statusCode}';
        }

        for (final fileData in fileList) {
          results[fileData['fileName'] as String] = TransferResult(
            success: false,
            errorMessage: errorMsg,
          );
        }
        return results;
      }

      // Parse confirmation response
      Map<String, String> transferIds;
      try {
        final confirmData =
            jsonDecode(confirmResponse.body) as Map<String, dynamic>;

        if (confirmData['accepted'] != true) {
          final errorMsg = confirmData['message'] as String? ?? '接收方拒绝接收';
          for (final fileData in fileList) {
            results[fileData['fileName'] as String] = TransferResult(
              success: false,
              errorMessage: errorMsg,
            );
          }
          return results;
        }

        transferIds = Map<String, String>.from(
          confirmData['transferIds'] as Map,
        );
      } catch (e) {
        final errorMsg = '无法解析接收方响应\n错误: $e';
        for (final fileData in fileList) {
          results[fileData['fileName'] as String] = TransferResult(
            success: false,
            errorMessage: errorMsg,
          );
        }
        return results;
      }

      // Step 5: Send files with concurrent control
      // Get concurrent transfer count from preferences
      final concurrentCount = await _preferencesService
          .getConcurrentTransfers();

      final Map<int, double> fileProgress = {}; // fileIndex -> progress
      final Map<int, int> fileBytes = {}; // fileIndex -> bytes transferred

      // Initialize fileBytes for all valid files
      for (int i = 0; i < files.length; i++) {
        final fileName = files[i].path.split('/').last;
        if (transferIds.containsKey(fileName)) {
          fileBytes[i] = 0; // Initialize to 0
        }
      }

      // Create a list of valid file indices (files that passed validation and have transferIds)
      final validFileIndices = <int>[];
      for (int i = 0; i < files.length; i++) {
        final fileName = files[i].path.split('/').last;
        // Only include files that have transferIds (passed validation)
        if (transferIds.containsKey(fileName)) {
          validFileIndices.add(i);
        }
      }

      // Function to send a single file
      Future<TransferResult> sendFile(int fileIndex) async {
        final file = files[fileIndex];
        final fileName = file.path.split('/').last;

        // Skip files that failed validation
        if (results.containsKey(fileName)) {
          return results[fileName]!;
        }

        // Get transfer ID for this file
        final transferId = transferIds[fileName];
        if (transferId == null) {
          return TransferResult(success: false, errorMessage: '未找到传输ID');
        }

        onStatusChange?.call(
          '正在传输文件 ${fileIndex + 1}/${files.length}: $fileName',
        );

        // Send the file
        final result = await _sendFileWithTransferId(
          targetIP: targetIP,
          file: file,
          transferId: transferId,
          senderIP: senderIP,
          deviceName: deviceName,
          onProgress: (progress, bytes, total) {
            // Update individual file progress
            fileProgress[fileIndex] = progress;
            fileBytes[fileIndex] = bytes;
            onFileProgress?.call(fileIndex, progress, bytes, total);

            // Calculate overall progress
            int overallBytes = 0;
            for (final entry in fileBytes.entries) {
              overallBytes += entry.value;
            }
            final overallProgress = totalBytes > 0
                ? overallBytes / totalBytes
                : 0.0;
            onProgress?.call(overallProgress, overallBytes, totalBytes);
          },
        );

        return result;
      }

      // Process files with concurrent control
      // Use validFileIndices instead of all files to ensure correct concurrency
      for (int i = 0; i < validFileIndices.length; i += concurrentCount) {
        final batchEnd = (i + concurrentCount < validFileIndices.length)
            ? i + concurrentCount
            : validFileIndices.length;

        // Create batch of futures
        final batch = <Future<void>>[];
        for (int j = i; j < batchEnd; j++) {
          final fileIndex = validFileIndices[j];
          batch.add(
            sendFile(fileIndex).then((result) {
              final fileName = files[fileIndex].path.split('/').last;
              results[fileName] = result;
            }),
          );
        }

        // Wait for all files in this batch to complete before starting next batch
        // Use eagerError: false to ensure all files complete even if some fail
        await Future.wait(batch, eagerError: false);
      }

      return results;
    } catch (e) {
      // Handle unexpected errors
      for (final file in files) {
        final fileName = file.path.split('/').last;
        if (!results.containsKey(fileName)) {
          results[fileName] = TransferResult(
            success: false,
            errorMessage: ErrorMessages.unexpectedError(e.toString()),
          );
        }
      }
      return results;
    }
  }

  /// Send a file with a pre-obtained transfer ID
  Future<TransferResult> _sendFileWithTransferId({
    required String targetIP,
    required File file,
    required String transferId,
    required String senderIP,
    String? deviceName,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
  }) async {
    final fileName = file.path.split('/').last;
    final fileSize = await file.length();

    try {
      // Prepare URL with metadata as query parameters
      String baseUrl;
      if (targetIP.contains(':')) {
        baseUrl = 'http://$targetIP/transfer';
      } else {
        baseUrl = 'http://$targetIP:${AppConstants.defaultPort}/transfer';
      }

      // Build URL with query parameters including transferId
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'fileName': fileName,
          'fileSize': fileSize.toString(),
          'senderIP': senderIP,
          if (deviceName != null) 'senderDeviceName': deviceName,
          'transferId': transferId,
        },
      );

      // Create multipart request
      final request = http.StreamedRequest('POST', uri);

      // Set content type
      request.headers['Content-Type'] = 'application/octet-stream';
      request.contentLength = fileSize;

      // Start sending the request (this returns a Future<StreamedResponse>)
      final responseFuture = request.send();

      // Track progress
      int bytesSent = 0;
      final fileStream = file.openRead();

      // Stream file data and wait for completion
      try {
        await for (final chunk in fileStream) {
          request.sink.add(chunk);
          bytesSent += chunk.length;

          // Calculate progress
          final progress = bytesSent / fileSize;

          // Call progress callback
          onProgress?.call(progress, bytesSent, fileSize);
        }

        // Close the sink after all data is sent
        await request.sink.close();
      } catch (e) {
        try {
          await request.sink.close();
        } catch (_) {
          // Ignore close errors
        }

        // Save failed transfer to history
        await _historyService.saveTransfer(
          TransferHistory(
            fileName: fileName,
            fileSize: fileSize,
            peerIP: targetIP.split(':').first,
            peerDeviceName: deviceName,
            timestamp: DateTime.now(),
            isReceived: false,
            success: false,
          ),
        );

        return TransferResult(success: false, errorMessage: '文件读取失败\n错误: $e');
      }

      // Now wait for the server response (file has been fully transmitted at this point)
      final streamedResponse = await responseFuture.timeout(
        Duration(seconds: 30 + (fileSize ~/ (1024 * 1024))),
      );

      // Read response body
      final responseBody = await streamedResponse.stream.bytesToString();

      // Check response status
      if (streamedResponse.statusCode != 200) {
        // Save failed transfer to history
        await _historyService.saveTransfer(
          TransferHistory(
            fileName: fileName,
            fileSize: fileSize,
            peerIP: targetIP.split(':').first,
            peerDeviceName: deviceName,
            timestamp: DateTime.now(),
            isReceived: false,
            success: false,
          ),
        );

        try {
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          return TransferResult(
            success: false,
            errorMessage: data['message'] as String? ?? '文件传输失败',
          );
        } catch (e) {
          return TransferResult(
            success: false,
            errorMessage: '文件传输失败\n状态码: ${streamedResponse.statusCode}',
          );
        }
      }

      // Parse success response
      try {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final savedPath = data['savedPath'] as String?;

        // Save to transfer history
        await _historyService.saveTransfer(
          TransferHistory(
            fileName: fileName,
            fileSize: fileSize,
            peerIP: targetIP.split(':').first,
            peerDeviceName: deviceName,
            timestamp: DateTime.now(),
            isReceived: false,
            // This is a send operation
            success: true,
            savedPath:
                null, // Sent files don't have a saved path on sender side
          ),
        );

        return TransferResult(success: true, savedPath: savedPath);
      } catch (e) {
        // Save failed transfer to history
        await _historyService.saveTransfer(
          TransferHistory(
            fileName: fileName,
            fileSize: fileSize,
            peerIP: targetIP.split(':').first,
            peerDeviceName: deviceName,
            timestamp: DateTime.now(),
            isReceived: false,
            success: false,
          ),
        );

        return TransferResult(success: false, errorMessage: '无法解析响应\n错误: $e');
      }
    } on TimeoutException {
      // Save failed transfer to history
      await _historyService.saveTransfer(
        TransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          peerIP: targetIP.split(':').first,
          peerDeviceName: deviceName,
          timestamp: DateTime.now(),
          isReceived: false,
          success: false,
        ),
      );

      return TransferResult(success: false, errorMessage: '文件传输超时');
    } on SocketException catch (e) {
      // Save failed transfer to history
      await _historyService.saveTransfer(
        TransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          peerIP: targetIP.split(':').first,
          peerDeviceName: deviceName,
          timestamp: DateTime.now(),
          isReceived: false,
          success: false,
        ),
      );

      return TransferResult(
        success: false,
        errorMessage: '网络连接失败\n错误: ${e.message}',
      );
    } catch (e) {
      // Save failed transfer to history
      await _historyService.saveTransfer(
        TransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          peerIP: targetIP.split(':').first,
          peerDeviceName: deviceName,
          timestamp: DateTime.now(),
          isReceived: false,
          success: false,
        ),
      );

      return TransferResult(
        success: false,
        errorMessage: ErrorMessages.unexpectedError(e.toString()),
      );
    }
  }

  /// Send a file to the target device
  ///
  /// First calls /confirm-receive endpoint to ask for user confirmation.
  /// If user accepts, then sends the file using /transfer endpoint.
  ///
  /// Parameters:
  /// Send a file to the target device
  ///
  /// First calls /confirm-receive endpoint to ask for user confirmation.
  /// If user accepts, then sends the file using /transfer endpoint.
  ///
  /// Parameters:
  /// - [targetIP]: IP address of the target device (format: "192.168.1.100:8080")
  /// - [file]: The file to send
  /// - [onProgress]: Optional callback for progress updates (0.0 to 1.0)
  /// - [onStatusChange]: Optional callback for status updates
  /// - [remainingFiles]: Number of remaining files in batch (optional)
  ///
  Future<TransferResult> sendFile({
    required String targetIP,
    required File file,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    void Function(String status)? onStatusChange,
    int? remainingFiles,
  }) async {
    final fileName = file.path.split('/').last;

    LogUtil.i('sendFile() targetIP: $targetIP');

    try {
      // Step 1: Check if file exists and is readable
      onStatusChange?.call('[步骤1/5] 检查文件...');

      if (!await file.exists()) {
        return TransferResult(
          success: false,
          errorMessage: '[步骤1失败] ${ErrorMessages.fileNotFound}',
        );
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > _maxFileSize) {
        return TransferResult(
          success: false,
          errorMessage: '[步骤1失败] ${ErrorMessages.fileTooLarge}',
        );
      }

      // Step 2: Perform health check first
      onStatusChange?.call('[步骤2/5] 正在检查目标设备...');
      final healthResult = await checkHealth(targetIP);
      if (!healthResult.isHealthy) {
        // Health check failed, return error
        return TransferResult(
          success: false,
          errorMessage: '[步骤2失败] 目标设备不可用\n错误: ${healthResult.errorMessage}',
        );
      }

      // Extract target device name from health check response
      String? targetDeviceName;
      if (healthResult.responseData != null &&
          healthResult.responseData!.containsKey('deviceName')) {
        targetDeviceName = healthResult.responseData!['deviceName'] as String?;
      }

      // Step 3: Get local IP address for senderIP field
      onStatusChange?.call('[步骤3/5] 准备传输信息...');

      final senderIP = await _getLocalIPAddress();

      // Get device name (use saved name or fallback to device model)
      String? deviceName = await _preferencesService.getDeviceName();
      if (deviceName == null || deviceName.isEmpty) {
        deviceName = await _getDeviceModel();
      }

      // Step 4: Call /confirm-receive endpoint to ask for user confirmation
      onStatusChange?.call('[步骤4/5] 等待接收方确认...');

      String confirmUrl;
      if (targetIP.contains(':')) {
        confirmUrl = 'http://$targetIP/confirm-receive';
      } else {
        confirmUrl =
            'http://$targetIP:${AppConstants.defaultPort}/confirm-receive';
      }

      final confirmUri = Uri.parse(confirmUrl).replace(
        queryParameters: {
          'fileName': fileName,
          'fileSize': fileSize.toString(),
          'senderIP': senderIP,
          if (deviceName != null) 'senderDeviceName': deviceName,
          if (remainingFiles != null)
            'remainingFiles': remainingFiles.toString(),
        },
      );

      // Use longer timeout for confirmation request to allow user time to respond
      // User has 30 seconds to confirm, so we use 35 seconds timeout
      http.Response confirmResponse;
      try {
        confirmResponse = await http.get(confirmUri).timeout(_confirmTimeout);
      } on TimeoutException {
        return TransferResult(
          success: false,
          errorMessage: '[步骤4失败] 等待接收方确认超时（35秒）\n接收方可能未响应或网络连接问题',
        );
      } on SocketException catch (e) {
        return TransferResult(
          success: false,
          errorMessage: '[步骤4失败] 无法连接到接收方\n错误: ${e.message}',
        );
      }

      // Check confirmation response
      if (confirmResponse.statusCode != 200) {
        try {
          final data = jsonDecode(confirmResponse.body) as Map<String, dynamic>;
          return TransferResult(
            success: false,
            errorMessage:
                '[步骤4失败] ${data['message'] as String? ?? '接收方拒绝接收'}\n状态码: ${confirmResponse.statusCode}',
          );
        } catch (e) {
          return TransferResult(
            success: false,
            errorMessage: '[步骤4失败] 接收方拒绝接收\n状态码: ${confirmResponse.statusCode}',
          );
        }
      }

      // Parse confirmation response
      String transferId;
      try {
        final confirmData =
            jsonDecode(confirmResponse.body) as Map<String, dynamic>;

        if (confirmData['accepted'] != true) {
          return TransferResult(
            success: false,
            errorMessage:
                '[步骤4失败] ${confirmData['message'] as String? ?? '接收方拒绝接收'}',
          );
        }

        transferId = confirmData['transferId'] as String;
      } catch (e) {
        return TransferResult(
          success: false,
          errorMessage: '[步骤4失败] 无法解析接收方响应\n错误: $e',
        );
      }

      // Step 5: User accepted, proceed with file transfer
      onStatusChange?.call('[步骤5/5] 正在传输文件...');

      // Prepare URL with metadata as query parameters
      String baseUrl;
      if (targetIP.contains(':')) {
        baseUrl = 'http://$targetIP/transfer';
      } else {
        baseUrl = 'http://$targetIP:${AppConstants.defaultPort}/transfer';
      }

      // Build URL with query parameters including transferId
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'fileName': fileName,
          'fileSize': fileSize.toString(),
          'senderIP': senderIP,
          if (deviceName != null) 'senderDeviceName': deviceName,
          'transferId': transferId,
        },
      );

      // Create a streaming request with raw binary body
      final request = http.StreamedRequest('POST', uri);
      request.headers['Content-Type'] = 'application/octet-stream';
      request.headers['Content-Length'] = fileSize.toString();

      // Start the request (this returns a Future<StreamedResponse>)
      final responseFuture = request.send();

      // Stream file data with progress tracking
      final fileStream = file.openRead();
      int bytesTransferred = 0;

      // Stream file data chunk by chunk with progress tracking
      // Phase 1: Reading file and sending over network (0-90% progress)
      // Note: request.sink.add() blocks until data is sent, so this phase
      // includes both file reading AND network transmission
      try {
        await for (final chunk in fileStream) {
          // Add data to sink first (this BLOCKS until data is sent over network)
          request.sink.add(chunk);
          // Update progress after adding to sink
          // Phase 1 progress: 0-90% (this is the actual network transmission)
          bytesTransferred += chunk.length;
          if (onProgress != null) {
            final progress = (bytesTransferred / fileSize) * 0.90;
            onProgress(progress, bytesTransferred, fileSize);
          }
        }
        // Close the request sink to indicate we're done sending data
        await request.sink.close();
      } catch (e) {
        request.sink.addError(e);
        await request.sink.close();
        return TransferResult(
          success: false,
          errorMessage: '[步骤5失败] 文件传输过程中出错\n错误: $e',
        );
      }

      // Phase 2: Waiting for server response (90-100% progress)
      // At this point, all data has been sent over the network
      // We're just waiting for the server to process and respond
      onStatusChange?.call('等待服务器响应...');

      // Set progress to 90%
      if (onProgress != null) {
        onProgress(0.90, fileSize, fileSize);
      }

      LogUtil.i(
        '[Progress] Phase 1 complete at 90%, waiting for server response...',
      );
      LogUtil.i(
        '[Progress] Phase 1 complete at 90%, waiting for server response...',
      );

      // Wait for response with extended timeout for large files
      final responseCompleter = Completer<http.Response>();

      final startWaitTime = DateTime.now();
      LogUtil.i('[Progress] Waiting for response at $startWaitTime...');

      // Handle response
      responseFuture
          .timeout(Duration(seconds: 60 + (fileSize ~/ (1024 * 1024))))
          .then((streamedResponse) async {
            final waitDuration = DateTime.now().difference(startWaitTime);
            LogUtil.i(
              '[Progress] Response received after ${waitDuration.inMilliseconds}ms!',
            );

            // Set progress to 100%
            if (onProgress != null) {
              onProgress(1.0, fileSize, fileSize);
            }

            final response = await http.Response.fromStream(streamedResponse);
            responseCompleter.complete(response);
          })
          .catchError((error) {
            LogUtil.i('[Progress] Error: $error');
            responseCompleter.completeError(error);
          });

      // Await the response
      http.Response response;
      try {
        response = await responseCompleter.future;
      } on TimeoutException {
        return TransferResult(
          success: false,
          errorMessage: '[步骤5失败] 等待服务器响应超时\n文件可能已传输但服务器未及时响应',
        );
      } catch (e) {
        return TransferResult(
          success: false,
          errorMessage: '[步骤5失败] 等待服务器响应时出错\n错误: $e',
        );
      }

      // Check response
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;

          if (data['success'] == true) {
            // Save to history
            await _historyService.saveTransfer(
              TransferHistory(
                fileName: fileName,
                fileSize: fileSize,
                peerIP: targetIP,
                peerDeviceName: targetDeviceName,
                timestamp: DateTime.now(),
                isReceived: false,
                success: true,
              ),
            );

            return TransferResult(
              success: true,
              savedPath: data['savedPath'] as String?,
            );
          } else {
            // Save failed transfer to history
            await _historyService.saveTransfer(
              TransferHistory(
                fileName: fileName,
                fileSize: fileSize,
                peerIP: targetIP,
                peerDeviceName: targetDeviceName,
                timestamp: DateTime.now(),
                isReceived: false,
                success: false,
              ),
            );

            return TransferResult(
              success: false,
              errorMessage:
                  '[步骤5失败] 服务器返回错误\n${data['message'] as String? ?? '未知错误'}',
            );
          }
        } catch (e) {
          return TransferResult(
            success: false,
            errorMessage: '[步骤5失败] 无法解析服务器响应\n错误: $e',
          );
        }
      } else if (response.statusCode == 403) {
        // Save rejected transfer to history
        await _historyService.saveTransfer(
          TransferHistory(
            fileName: fileName,
            fileSize: fileSize,
            peerIP: targetIP,
            peerDeviceName: targetDeviceName,
            timestamp: DateTime.now(),
            isReceived: false,
            success: false,
          ),
        );

        return TransferResult(
          success: false,
          errorMessage: '[步骤5失败] 接收方拒绝接收\n状态码: 403',
        );
      } else if (response.statusCode == 413) {
        return TransferResult(
          success: false,
          errorMessage: '[步骤5失败] 文件过大或存储空间不足\n状态码: 413',
        );
      } else {
        return TransferResult(
          success: false,
          errorMessage: '[步骤5失败] 服务器返回错误\n状态码: ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      return TransferResult(
        success: false,
        errorMessage: '网络连接失败\n错误: ${e.message}\n请检查网络连接和目标设备IP地址',
      );
    } on http.ClientException catch (e) {
      return TransferResult(
        success: false,
        errorMessage: '网络请求失败\n错误: $e\n请检查网络连接',
      );
    } on TimeoutException catch (e) {
      return TransferResult(
        success: false,
        errorMessage: '传输超时\n错误: $e\n请检查网络连接或稍后重试',
      );
    } catch (e, stackTrace) {
      LogUtil.i('Unexpected error in sendFile: $e');
      LogUtil.i('Stack trace: $stackTrace');
      return TransferResult(
        success: false,
        errorMessage: '发生未预期的错误\n错误: $e\n请查看日志获取更多信息',
      );
    }
  }

  /// Get the local IP address of the device
  ///
  /// Priority order:
  /// 1. Private network addresses (192.168.x.x, 172.16-31.x.x, 10.x.x.x)
  /// 2. Other non-loopback IPv4 addresses
  /// 3. Fallback to 127.0.0.1
  Future<String> _getLocalIPAddress() async {
    try {
      // Get all network interfaces
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      List<String> privateAddresses = [];
      List<String> otherAddresses = [];

      // Categorize addresses
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;

            // Check if it's a private network address
            if (_isPrivateNetwork(ip)) {
              privateAddresses.add(ip);
            } else {
              otherAddresses.add(ip);
            }
          }
        }
      }

      // Prefer private network addresses (typical LAN)
      if (privateAddresses.isNotEmpty) {
        // Sort to prefer 192.168.x.x over 10.x.x.x
        privateAddresses.sort((a, b) {
          if (a.startsWith('192.168.')) return -1;
          if (b.startsWith('192.168.')) return 1;
          if (a.startsWith('172.')) return -1;
          if (b.startsWith('172.')) return 1;
          return 0;
        });
        return privateAddresses.first;
      }

      // Use other addresses if no private network found
      if (otherAddresses.isNotEmpty) {
        return otherAddresses.first;
      }

      // Fallback to localhost if no network interface found
      return '127.0.0.1';
    } catch (e) {
      // If error, return localhost
      return '127.0.0.1';
    }
  }

  /// Check if an IP address is in a private network range
  ///
  /// Private network ranges:
  /// - 192.168.0.0/16 (192.168.0.0 - 192.168.255.255)
  /// - 172.16.0.0/12 (172.16.0.0 - 172.31.255.255)
  /// - 10.0.0.0/8 (10.0.0.0 - 10.255.255.255)
  bool _isPrivateNetwork(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    try {
      final first = int.parse(parts[0]);
      final second = int.parse(parts[1]);

      // 192.168.x.x
      if (first == 192 && second == 168) {
        return true;
      }

      // 172.16.x.x - 172.31.x.x
      if (first == 172 && second >= 16 && second <= 31) {
        return true;
      }

      // 10.x.x.x
      if (first == 10) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Ask user for confirmation to receive a file (without actually receiving it)
  ///
  /// This method is called by the /confirm-receive endpoint to show a confirmation
  /// dialog to the user BEFORE the file transfer begins.
  ///
  /// Parameters:
  /// Ask user for confirmation to receive a file (without actually receiving it)
  ///
  /// This method is called by the /confirm-receive endpoint to show a confirmation
  /// dialog to the user BEFORE the file transfer begins.
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing dialogs
  /// - [fileName]: Name of the file
  /// - [fileSize]: Size of the file in bytes
  /// - [senderIP]: IP address of the sender device
  /// - [remainingFiles]: Number of remaining files in batch (optional)
  ///
  /// Returns [ConfirmationResult] indicating whether the user accepted
  Future<ConfirmationResult> askReceiveConfirmation({
    required BuildContext context,
    required String fileName,
    required int fileSize,
    required String senderIP,
    String? senderDeviceName,
    int? remainingFiles,
  }) async {
    try {
      // Show confirmation dialog to user
      final notificationService = NotificationService();
      final confirmationResult = await notificationService
          .showReceiveConfirmation(
            context: context,
            senderIP: senderIP,
            senderDeviceName: senderDeviceName,
            fileName: fileName,
            fileSize: fileSize,
            remainingFiles: remainingFiles,
          );

      // Check if user rejected or timed out
      if (!confirmationResult.accepted) {
        return ConfirmationResult(
          accepted: false,
          errorMessage: confirmationResult.timedOut
              ? ErrorMessages.receiveTimeout
              : ErrorMessages.userRejected,
          autoAcceptRemaining: false,
        );
      }

      // User accepted
      return ConfirmationResult(
        accepted: true,
        autoAcceptRemaining: confirmationResult.autoAcceptRemaining,
      );
    } catch (e) {
      return ConfirmationResult(
        accepted: false,
        errorMessage: ErrorMessages.unexpectedError(e.toString()),
        autoAcceptRemaining: false,
      );
    }
  }

  /// Receive a file directly without user confirmation (confirmation already done)
  ///
  /// This method is called by the /transfer endpoint after user has already
  /// confirmed via /confirm-receive endpoint.
  ///
  /// Parameters:
  /// - [fileStream]: Stream of raw file data
  /// - [fileName]: Name of the file
  /// - [fileSize]: Size of the file in bytes
  /// - [senderIP]: IP address of the sender device
  /// - [senderDeviceName]: (optional) Name of the sender device
  /// - [onProgress]: Optional callback for progress updates (0.0 to 1.0)
  ///
  /// Returns [DirectReceiveResult] indicating whether the file was saved successfully
  Future<DirectReceiveResult> receiveFileDirectly({
    required Stream<List<int>> fileStream,
    required String fileName,
    required int fileSize,
    required String senderIP,
    String? senderDeviceName,
    void Function(double progress, int bytesReceived, int totalBytes)?
    onProgress,
  }) async {
    IOSink? sink;
    File? file;

    try {
      // Check storage space
      final hasEnoughSpace = await _checkStorageSpace(fileSize);
      if (!hasEnoughSpace) {
        // Drain the stream to prevent connection issues
        try {
          await fileStream.drain();
        } catch (e) {
          LogUtil.e('Error draining stream: $e');
        }

        return DirectReceiveResult(
          success: false,
          errorMessage: ErrorMessages.storageInsufficient,
        );
      }

      // Get downloads directory
      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        // Drain the stream to prevent connection issues
        try {
          await fileStream.drain();
        } catch (e) {
          LogUtil.e('Error draining stream: $e');
        }

        return DirectReceiveResult(
          success: false,
          errorMessage: ErrorMessages.downloadsDirectoryUnavailable,
        );
      }

      // Handle file name conflicts
      final finalFileName = await _resolveFileNameConflict(
        downloadsDir,
        fileName,
      );
      final filePath = '${downloadsDir.path}/$finalFileName';

      // Save file data using streaming for memory efficiency
      file = File(filePath);
      sink = file.openWrite();

      // Track progress
      int bytesReceived = 0;

      try {
        // Write file data from stream with progress tracking
        await for (final chunk in fileStream) {
          sink.add(chunk);

          // Update progress
          bytesReceived += chunk.length;
          if (onProgress != null) {
            final progress = bytesReceived / fileSize;
            onProgress(progress, bytesReceived, fileSize);
          }
        }

        // Ensure all data is written
        await sink.flush();
        await sink.close();
        sink = null; // Mark as closed
      } catch (e) {
        LogUtil.e('Error writing file: $e');

        // Clean up on error
        if (sink != null) {
          try {
            await sink.close();
          } catch (closeError) {
            LogUtil.e('Error closing sink: $closeError');
          }
          sink = null;
        }

        // Delete the partially written file
        // ignore: unnecessary_null_comparison
        if (file != null) {
          try {
            if (await file.exists()) {
              await file.delete();
            }
          } catch (deleteError) {
            LogUtil.e('Error deleting file: $deleteError');
          }
        }

        // Save failed transfer to history
        await _historyService.saveTransfer(
          TransferHistory(
            fileName: fileName,
            fileSize: fileSize,
            peerIP: senderIP,
            peerDeviceName: senderDeviceName,
            timestamp: DateTime.now(),
            isReceived: true,
            success: false,
          ),
        );

        return DirectReceiveResult(
          success: false,
          errorMessage: '文件保存失败\n错误: $e',
        );
      }

      // Verify file was saved correctly
      if (!await file.exists()) {
        return DirectReceiveResult(
          success: false,
          errorMessage: ErrorMessages.fileSaveFailed,
        );
      }

      final savedSize = await file.length();
      if (savedSize != fileSize) {
        LogUtil.w('File size mismatch: expected $fileSize, got $savedSize');

        // File size mismatch, delete the file
        try {
          await file.delete();
        } catch (deleteError) {
          LogUtil.e('Error deleting mismatched file: $deleteError');
        }

        // Save failed transfer to history
        await _historyService.saveTransfer(
          TransferHistory(
            fileName: fileName,
            fileSize: fileSize,
            peerIP: senderIP,
            peerDeviceName: senderDeviceName,
            timestamp: DateTime.now(),
            isReceived: true,
            success: false,
          ),
        );

        return DirectReceiveResult(
          success: false,
          errorMessage: ErrorMessages.fileSizeMismatch,
        );
      }

      // Save to history with saved path
      await _historyService.saveTransfer(
        TransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          peerIP: senderIP,
          peerDeviceName: senderDeviceName,
          timestamp: DateTime.now(),
          isReceived: true,
          success: true,
          savedPath: filePath,
        ),
      );

      return DirectReceiveResult(success: true, savedPath: filePath);
    } catch (e, stackTrace) {
      LogUtil.e('Unexpected error in receiveFileDirectly: $e');
      LogUtil.e('Stack trace: $stackTrace');

      // Clean up on error
      if (sink != null) {
        try {
          await sink.close();
        } catch (closeError) {
          LogUtil.e('Error closing sink: $closeError');
        }
      }

      // Delete the partially written file
      // ignore: unnecessary_null_comparison
      if (file != null) {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (deleteError) {
          LogUtil.e('Error deleting file: $deleteError');
        }
      }

      // Save failed transfer to history
      await _historyService.saveTransfer(
        TransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          peerIP: senderIP,
          peerDeviceName: senderDeviceName,
          timestamp: DateTime.now(),
          isReceived: true,
          success: false,
        ),
      );

      return DirectReceiveResult(
        success: false,
        errorMessage: ErrorMessages.unexpectedError(e.toString()),
      );
    }
  }

  /// Get the downloads directory for the current platform
  ///
  /// Returns the downloads directory, or null if it cannot be accessed
  Future<Directory?> _getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        // On Android, use the external storage downloads directory
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          // Navigate to the Downloads folder
          final downloadsPath = directory.path.replaceAll(
            'Android/data/com.example.icy_easy_send/files',
            'Download',
          );
          final downloadsDir = Directory(downloadsPath);

          // Create directory if it doesn't exist
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }

          return downloadsDir;
        }
      } else if (Platform.isIOS) {
        // On iOS, use the documents directory
        return await getApplicationDocumentsDirectory();
      } else {
        // On desktop platforms, use the downloads directory
        return await getDownloadsDirectory();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if there is enough storage space for the file
  ///
  /// Parameters:
  /// - [requiredBytes]: Number of bytes needed
  ///
  /// Returns true if there is enough space, false otherwise
  Future<bool> _checkStorageSpace(int requiredBytes) async {
    try {
      // Get the downloads directory
      final directory = await _getDownloadsDirectory();
      if (directory == null) {
        return false;
      }

      // Check available space using statfs (platform-specific)
      // For simplicity, we'll use a basic check
      // In production, you might want to use a platform channel for accurate space checking

      // Try to get filesystem stats
      // ignore: unused_local_variable
      final stat = await directory.stat();

      // For now, we'll assume there's enough space if we can access the directory
      // A more robust implementation would use platform channels to check actual free space
      // This is a simplified version that checks if the directory is accessible

      // Add a safety margin (100MB)
      // ignore: unused_local_variable
      const safetyMargin = 100 * 1024 * 1024;

      // For this implementation, we'll return true if the file is under 1GB
      // In production, you'd want to check actual available space
      return requiredBytes < (1024 * 1024 * 1024);
    } catch (e) {
      // If we can't check, assume there's not enough space to be safe
      return false;
    }
  }

  /// Resolve file name conflicts by adding a number suffix
  ///
  /// If a file with the same name exists, adds (1), (2), etc. to the filename
  ///
  /// Parameters:
  /// - [directory]: Directory where the file will be saved
  /// - [fileName]: Original file name
  ///
  /// Returns a unique file name that doesn't conflict with existing files
  Future<String> _resolveFileNameConflict(
    Directory directory,
    String fileName,
  ) async {
    // Split filename into name and extension
    final lastDotIndex = fileName.lastIndexOf('.');
    String baseName;
    String extension;

    if (lastDotIndex != -1 && lastDotIndex < fileName.length - 1) {
      baseName = fileName.substring(0, lastDotIndex);
      extension = fileName.substring(lastDotIndex);
    } else {
      baseName = fileName;
      extension = '';
    }

    // Check if file exists
    String candidateName = fileName;
    int counter = 1;

    while (await File('${directory.path}/$candidateName').exists()) {
      candidateName = '$baseName($counter)$extension';
      counter++;
    }

    return candidateName;
  }

  /// Get device model name
  ///
  /// Returns the device model name using device_info_plus package.
  /// Falls back to Platform.localHostname if device info is unavailable.
  Future<String?> _getDeviceModel() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return macInfo.computerName;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return linuxInfo.name;
      }

      // Fallback to hostname
      try {
        return Platform.localHostname;
      } catch (e) {
        return null;
      }
    } catch (e) {
      // If device_info_plus fails, try hostname
      try {
        return Platform.localHostname;
      } catch (e) {
        return null;
      }
    }
  }
}
