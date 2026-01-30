import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../../utils/constants.dart';
import '../../utils/error_messages.dart';
import '../../utils/http_helper.dart';
import '../../utils/log_util.dart';
import '../../utils/network_util.dart';
import '../../utils/operation_result.dart';
import '../preferences_service.dart';
import '../validation_service.dart';
import '../transfer_history_service.dart';
import 'health_checker.dart';
import 'transfer_history_manager.dart';
import 'transfer_request_builder.dart';

/// Service for sending files to target devices
class FileSender {
  final HealthChecker _healthChecker;
  final TransferHistoryManager _historyManager;
  final TransferRequestBuilder _requestBuilder;
  final ValidationService _validationService;
  final PreferencesService _preferencesService;

  FileSender({
    HealthChecker? healthChecker,
    TransferHistoryService? historyService,
    TransferRequestBuilder? requestBuilder,
    ValidationService? validationService,
    PreferencesService? preferencesService,
  }) : _healthChecker = healthChecker ?? HealthChecker(),
       _historyManager = TransferHistoryManager(historyService: historyService),
       _requestBuilder = requestBuilder ?? TransferRequestBuilder(),
       _validationService = validationService ?? ValidationService(),
       _preferencesService = preferencesService ?? PreferencesService();

  /// Send a file with a pre-obtained transfer ID
  Future<OperationResult<TransferData>> sendFileWithTransferId({
    required String targetIP,
    required File file,
    required String transferId,
    required String senderIP,
    String? deviceName,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
  }) async {
    final fileName = path.basename(file.path);
    final fileSize = await file.length();

    LogUtil.i(
      "sendFileWithTransferId() transferId: [$transferId], targetIP: [$targetIP], fileSize: [$fileSize], fileName: [$fileName]",
    );

    try {
      final request = _requestBuilder.buildTransferRequest(
        targetIP: targetIP,
        fileName: fileName,
        fileSize: fileSize,
        senderIP: senderIP,
        deviceName: deviceName,
        transferId: transferId,
      );

      final responseFuture = request.send();

      await _streamFileData(
        file: file,
        fileSize: fileSize,
        request: request,
        onProgress: onProgress,
      );

      final streamedResponse = await _waitForServerResponse(
        responseFuture: responseFuture,
        fileSize: fileSize,
      );

      final responseBody = await streamedResponse.stream.bytesToString();
      return await _handleTransferResponse(
        statusCode: streamedResponse.statusCode,
        responseBody: responseBody,
        fileName: fileName,
        fileSize: fileSize,
        targetIP: targetIP,
        deviceName: deviceName,
      );
    } on TimeoutException {
      await _historyManager.saveTransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        targetIP: targetIP,
        success: false,
        isReceived: false,
        deviceName: deviceName,
      );
      return OperationResult.failure('文件传输超时');
    } on SocketException catch (e) {
      LogUtil.e(e.toString());
      await _historyManager.saveTransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        targetIP: targetIP,
        success: false,
        isReceived: false,
        deviceName: deviceName,
      );
      return OperationResult.failure('网络连接失败\n错误: ${e.message}');
    } catch (e) {
      LogUtil.e(e.toString());
      await _historyManager.saveTransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        targetIP: targetIP,
        success: false,
        isReceived: false,
        deviceName: deviceName,
      );
      return OperationResult.failure(
        ErrorMessages.unexpectedError(e.toString()),
      );
    }
  }

  /// Send a file to the target device with confirmation
  Future<OperationResult<TransferData>> sendFile({
    required String targetIP,
    required File file,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    void Function(String status)? onStatusChange,
    int? remainingFiles,
  }) async {
    final fileName = path.basename(file.path);

    LogUtil.i('sendFile() targetIP: $targetIP');

    try {
      // Step 1: Validate file
      final validationResult = await _validateFileForSending(
        file,
        onStatusChange,
      );
      if (!validationResult.isSuccess) {
        return validationResult;
      }
      final fileSize = int.parse(validationResult.data!.savedPath!);

      // Step 2: Check target device health
      final healthCheckResult = await _performHealthCheck(
        targetIP,
        onStatusChange,
      );
      if (!healthCheckResult.isSuccess) {
        return healthCheckResult;
      }
      final targetDeviceName = healthCheckResult.data!.savedPath;

      // Step 3: Prepare sender information
      final senderInfo = await _prepareSenderInformation(onStatusChange);

      // Step 4: Request confirmation from receiver
      final confirmResult = await _requestReceiverConfirmation(
        targetIP: targetIP,
        fileName: fileName,
        fileSize: fileSize,
        senderInfo: senderInfo,
        remainingFiles: remainingFiles,
        onStatusChange: onStatusChange,
      );
      if (!confirmResult.isSuccess) {
        return confirmResult;
      }
      final transferId = confirmResult.data!.savedPath!;

      // Step 5: Perform file transfer
      return await _executeFileTransfer(
        targetIP: targetIP,
        file: file,
        fileName: fileName,
        fileSize: fileSize,
        transferId: transferId,
        senderInfo: senderInfo,
        targetDeviceName: targetDeviceName,
        onProgress: onProgress,
        onStatusChange: onStatusChange,
      );
    } on SocketException catch (e) {
      return OperationResult.failure(
        '网络连接失败\n错误: ${e.message}\n请检查网络连接和目标设备IP地址',
      );
    } on http.ClientException catch (e) {
      return OperationResult.failure('网络请求失败\n错误: $e\n请检查网络连接');
    } on TimeoutException catch (e) {
      return OperationResult.failure('传输超时\n错误: $e\n请检查网络连接或稍后重试');
    } catch (e, stackTrace) {
      LogUtil.i('Unexpected error in sendFile: $e');
      LogUtil.i('Stack trace: $stackTrace');
      return OperationResult.failure('发生未预期的错误\n错误: $e\n请查看日志获取更多信息');
    }
  }

  /// Stream file data to server with progress tracking
  Future<void> _streamFileData({
    required File file,
    required int fileSize,
    required http.StreamedRequest request,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
  }) async {
    int bytesSent = 0;
    final fileStream = file.openRead();

    try {
      await for (final chunk in fileStream) {
        request.sink.add(chunk);
        bytesSent += chunk.length;

        final progress = bytesSent / fileSize;
        onProgress?.call(progress, bytesSent, fileSize);
      }

      await request.sink.close();
    } catch (e) {
      LogUtil.e(e.toString());
      try {
        await request.sink.close();
      } catch (_) {
        // Ignore close errors
      }
      rethrow;
    }
  }

  /// Wait for server response after file transfer
  Future<http.StreamedResponse> _waitForServerResponse({
    required Future<http.StreamedResponse> responseFuture,
    required int fileSize,
  }) async {
    final timeout =
        Duration(seconds: fileSize ~/ (AppConstants.bytesPerMB)) +
        Duration(seconds: AppConstants.requestTimeout);
    return await responseFuture.timeout(timeout);
  }

  /// Handle server response and save to history
  Future<OperationResult<TransferData>> _handleTransferResponse({
    required int statusCode,
    required String responseBody,
    required String fileName,
    required int fileSize,
    required String targetIP,
    String? deviceName,
  }) async {
    if (statusCode != 200) {
      await _historyManager.saveTransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        targetIP: targetIP,
        success: false,
        isReceived: false,
        deviceName: deviceName,
      );

      try {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return OperationResult.failure(data['message'] as String? ?? '文件传输失败');
      } catch (e) {
        LogUtil.e(e.toString());
        return OperationResult.failure('文件传输失败\n状态码: $statusCode');
      }
    }

    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final savedPath = data['savedPath'] as String?;

      await _historyManager.saveTransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        targetIP: targetIP,
        success: true,
        isReceived: false,
        deviceName: deviceName,
      );

      return OperationResult.success(
        data: TransferData(savedPath: savedPath, bytesTransferred: fileSize),
      );
    } catch (e) {
      LogUtil.e(e.toString());
      await _historyManager.saveTransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        targetIP: targetIP,
        success: false,
        isReceived: false,
        deviceName: deviceName,
      );
      return OperationResult.failure('无法解析响应\n错误: $e');
    }
  }

  Future<OperationResult<TransferData>> _validateFileForSending(
    File file,
    void Function(String status)? onStatusChange,
  ) async {
    onStatusChange?.call('[步骤1/5] 检查文件...');

    final validationResult = await _validationService.validateFileForSending(
      file,
    );

    if (!validationResult.isSuccess) {
      return OperationResult.failure(
        '[步骤1失败] ${validationResult.errorMessage}',
      );
    }

    final fileData = validationResult.data!;

    return OperationResult.success(
      data: TransferData(
        savedPath: fileData.fileSize.toString(),
        bytesTransferred: 0,
      ),
    );
  }

  Future<OperationResult<TransferData>> _performHealthCheck(
    String targetIP,
    void Function(String status)? onStatusChange,
  ) async {
    onStatusChange?.call('[步骤2/5] 正在检查目标设备...');

    final healthResult = await _healthChecker.checkHealth(targetIP);
    if (!healthResult.isSuccess) {
      return OperationResult.failure(
        '[步骤2失败] 目标设备不可用\n错误: ${healthResult.errorMessage}',
      );
    }

    String? targetDeviceName;
    if (healthResult.metadata != null &&
        healthResult.metadata!.containsKey('deviceName')) {
      targetDeviceName = healthResult.metadata!['deviceName'] as String?;
    }

    return OperationResult.success(
      data: TransferData(
        savedPath: targetDeviceName ?? '',
        bytesTransferred: 0,
      ),
    );
  }

  Future<Map<String, String>> _prepareSenderInformation(
    void Function(String status)? onStatusChange,
  ) async {
    onStatusChange?.call('[步骤3/5] 准备传输信息...');

    final senderIP = await NetworkUtil.getLocalIPAddress();
    String? deviceName = await _preferencesService.getDeviceName();
    if (deviceName == null || deviceName.isEmpty) {
      deviceName = await NetworkUtil.getDeviceName();
    }

    return {'senderIP': senderIP, 'deviceName': deviceName};
  }

  Future<OperationResult<TransferData>> _requestReceiverConfirmation({
    required String targetIP,
    required String fileName,
    required int fileSize,
    required Map<String, String> senderInfo,
    int? remainingFiles,
    void Function(String status)? onStatusChange,
  }) async {
    onStatusChange?.call('[步骤4/5] 等待接收方确认...');

    final confirmUri = _requestBuilder.buildConfirmationUri(
      targetIP: targetIP,
      fileName: fileName,
      fileSize: fileSize,
      senderIP: senderInfo['senderIP']!,
      deviceName: senderInfo['deviceName']!,
      remainingFiles: remainingFiles,
    );

    final confirmResult = await HttpHelper.get(
      confirmUri.toString(),
      timeout: AppConstants.confirmTimeout,
    );

    if (!confirmResult.isSuccess) {
      return OperationResult.failure('[步骤4失败] ${confirmResult.errorMessage}');
    }

    final confirmResponse = confirmResult.data!;

    if (!HttpHelper.isSuccessResponse(confirmResponse)) {
      final errorMsg = HttpHelper.extractErrorMessage(
        confirmResponse,
        '接收方拒绝接收',
      );
      return OperationResult.failure(
        '[步骤4失败] $errorMsg\n状态码: ${confirmResponse.statusCode}',
      );
    }

    final parseResult = HttpHelper.parseJsonResponse(confirmResponse);
    if (!parseResult.isSuccess) {
      return OperationResult.failure('[步骤4失败] ${parseResult.errorMessage}');
    }

    final confirmData = parseResult.data!;

    if (confirmData['accepted'] != true) {
      return OperationResult.failure(
        '[步骤4失败] ${confirmData['message'] as String? ?? '接收方拒绝接收'}',
      );
    }

    final transferId = confirmData['transferId'] as String;
    return OperationResult.success(
      data: TransferData(savedPath: transferId, bytesTransferred: 0),
    );
  }

  Future<OperationResult<TransferData>> _executeFileTransfer({
    required String targetIP,
    required File file,
    required String fileName,
    required int fileSize,
    required String transferId,
    required Map<String, String> senderInfo,
    required String? targetDeviceName,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    void Function(String status)? onStatusChange,
  }) async {
    onStatusChange?.call('[步骤5/5] 正在传输文件...');

    final baseUrl = NetworkUtil.buildHttpUrl(targetIP, '/transfer');
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'fileName': fileName,
        'fileSize': fileSize.toString(),
        'senderIP': senderInfo['senderIP']!,
        'senderDeviceName': senderInfo['deviceName']!,
        'transferId': transferId,
      },
    );

    final request = http.StreamedRequest('POST', uri);
    request.headers['Content-Type'] = 'application/octet-stream';
    request.headers['Content-Length'] = fileSize.toString();

    final responseFuture = request.send();

    await _streamFileDataToServer(
      file: file,
      fileSize: fileSize,
      request: request,
      onProgress: onProgress,
    );

    final response = await _waitForTransferResponse(
      responseFuture: responseFuture,
      fileSize: fileSize,
      onProgress: onProgress,
      onStatusChange: onStatusChange,
    );

    return await _processTransferResponse(
      response: response,
      fileName: fileName,
      fileSize: fileSize,
      targetIP: targetIP,
      targetDeviceName: targetDeviceName,
    );
  }

  Future<void> _streamFileDataToServer({
    required File file,
    required int fileSize,
    required http.StreamedRequest request,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
  }) async {
    final fileStream = file.openRead();
    int bytesTransferred = 0;

    try {
      await for (final chunk in fileStream) {
        request.sink.add(chunk);
        bytesTransferred += chunk.length;

        if (onProgress != null) {
          final progress = (bytesTransferred / fileSize) * 0.90;
          onProgress(progress, bytesTransferred, fileSize);
        }
      }
      await request.sink.close();
    } catch (e) {
      request.sink.addError(e);
      await request.sink.close();
      throw OperationResult<TransferData>.failure('[步骤5失败] 文件传输过程中出错\n错误: $e');
    }
  }

  Future<http.Response> _waitForTransferResponse({
    required Future<http.StreamedResponse> responseFuture,
    required int fileSize,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    void Function(String status)? onStatusChange,
  }) async {
    onStatusChange?.call('等待服务器响应...');
    onProgress?.call(0.90, fileSize, fileSize);

    LogUtil.i(
      '[Progress] Phase 1 complete at 90%, waiting for server response...',
    );

    final responseCompleter = Completer<http.Response>();
    final startWaitTime = DateTime.now();
    LogUtil.i('[Progress] Waiting for response at $startWaitTime...');

    responseFuture
        .timeout(
          Duration(seconds: 60 + (fileSize ~/ (AppConstants.bytesPerMB))),
        )
        .then((streamedResponse) async {
          final waitDuration = DateTime.now().difference(startWaitTime);
          LogUtil.i(
            '[Progress] Response received after ${waitDuration.inMilliseconds}ms!',
          );

          onProgress?.call(1.0, fileSize, fileSize);

          final response = await http.Response.fromStream(streamedResponse);
          responseCompleter.complete(response);
        })
        .catchError((error) {
          LogUtil.i('[Progress] Error: $error');
          responseCompleter.completeError(error);
        });

    try {
      return await responseCompleter.future;
    } on TimeoutException {
      throw OperationResult<TransferData>.failure(
        '[步骤5失败] 等待服务器响应超时\n文件可能已传输但服务器未及时响应',
      );
    } catch (e) {
      throw OperationResult<TransferData>.failure('[步骤5失败] 等待服务器响应时出错\n错误: $e');
    }
  }

  Future<OperationResult<TransferData>> _processTransferResponse({
    required http.Response response,
    required String fileName,
    required int fileSize,
    required String targetIP,
    required String? targetDeviceName,
  }) async {
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final success = data['success'] == true;

        await _historyManager.saveTransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          targetIP: targetIP,
          success: success,
          isReceived: false,
          deviceName: targetDeviceName,
        );

        if (success) {
          return OperationResult.success(
            data: TransferData(
              savedPath: data['savedPath'] as String?,
              bytesTransferred: fileSize,
            ),
          );
        } else {
          return OperationResult.failure(
            '[步骤5失败] 服务器返回错误\n${data['message'] as String? ?? '未知错误'}',
          );
        }
      } catch (e) {
        return OperationResult.failure('[步骤5失败] 无法解析服务器响应\n错误: $e');
      }
    } else if (response.statusCode == 403) {
      await _historyManager.saveTransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        targetIP: targetIP,
        success: false,
        isReceived: false,
        deviceName: targetDeviceName,
      );

      return OperationResult.failure('[步骤5失败] 接收方拒绝接收\n状态码: 403');
    } else if (response.statusCode == 413) {
      return OperationResult.failure('[步骤5失败] 文件过大或存储空间不足\n状态码: 413');
    } else {
      return OperationResult.failure(
        '[步骤5失败] 服务器返回错误\n状态码: ${response.statusCode}',
      );
    }
  }
}

/// Transfer data result
class TransferData {
  final String? savedPath;
  final int bytesTransferred;

  TransferData({this.savedPath, required this.bytesTransferred});
}
