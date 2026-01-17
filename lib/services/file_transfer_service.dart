import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'notification_service.dart';
import 'transfer_history_service.dart';
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

  TransferResult({
    required this.success,
    this.errorMessage,
    this.savedPath,
  });
}

/// Result of file receive operation
class ReceiveResult {
  final bool accepted;
  final String? savedPath;
  final String? errorMessage;

  ReceiveResult({
    required this.accepted,
    this.savedPath,
    this.errorMessage,
  });
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

  ConfirmationResult({
    required this.accepted,
    this.errorMessage,
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
  
  /// Check if target device is healthy and ready to receive files
  /// 
  /// Sends a GET request to the target device's /health endpoint.
  /// Returns [HealthCheckResult] indicating if the device is healthy.
  /// 
  /// Parameters:
  /// - [targetIP]: IP address of the target device (format: "192.168.1.100:8080")
  /// 
  /// Requirements: 6.1, 6.2
  Future<HealthCheckResult> checkHealth(String targetIP) async {
    try {
      // Ensure targetIP includes port, default to 8080 if not specified
      String url;
      if (targetIP.contains(':')) {
        url = 'http://$targetIP/health';
      } else {
        url = 'http://$targetIP:8080/health';
      }
      
      // Send GET request to health endpoint
      final response = await http.get(
        Uri.parse(url),
      ).timeout(_requestTimeout);
      
      // Check if response is successful
      if (response.statusCode == 200) {
        try {
          // Parse JSON response
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          
          // Verify response contains expected fields
          if (data.containsKey('status') && data['status'] == 'ok') {
            return HealthCheckResult(
              isHealthy: true,
              responseData: data,
            );
          } else {
            return HealthCheckResult(
              isHealthy: false,
              errorMessage: ErrorMessages.responseInvalidFormat,
            );
          }
        } catch (e) {
          return HealthCheckResult(
            isHealthy: false,
            errorMessage: ErrorMessages.responseParseError,
          );
        }
      } else {
        return HealthCheckResult(
          isHealthy: false,
          errorMessage: ErrorMessages.responseStatusCodeError(response.statusCode),
        );
      }
    } on SocketException {
      return HealthCheckResult(
        isHealthy: false,
        errorMessage: ErrorMessages.networkConnectionFailed,
      );
    } on http.ClientException {
      return HealthCheckResult(
        isHealthy: false,
        errorMessage: ErrorMessages.networkRequestFailed,
      );
    } on TimeoutException {
      return HealthCheckResult(
        isHealthy: false,
        errorMessage: ErrorMessages.networkTimeout,
      );
    } catch (e) {
      return HealthCheckResult(
        isHealthy: false,
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
  /// - [targetIP]: IP address of the target device (format: "192.168.1.100:8080")
  /// - [file]: The file to send
  /// - [onProgress]: Optional callback for progress updates (0.0 to 1.0)
  /// - [onStatusChange]: Optional callback for status updates
  /// 
  /// Requirements: 6.1, 6.3, 6.4, 6.5
  Future<TransferResult> sendFile({
    required String targetIP,
    required File file,
    void Function(double progress, int bytesTransferred, int totalBytes)? onProgress,
    void Function(String status)? onStatusChange,
  }) async {
    try {
      // Step 1: Check if file exists and is readable
      if (!await file.exists()) {
        return TransferResult(
          success: false,
          errorMessage: ErrorMessages.fileNotFound,
        );
      }
      
      // Check file size
      final fileSize = await file.length();
      if (fileSize > _maxFileSize) {
        return TransferResult(
          success: false,
          errorMessage: ErrorMessages.fileTooLarge,
        );
      }
      
      // Step 2: Perform health check first
      onStatusChange?.call('正在检查目标设备...');
      
      final healthResult = await checkHealth(targetIP);
      
      if (!healthResult.isHealthy) {
        // Health check failed, return error
        return TransferResult(
          success: false,
          errorMessage: '${ErrorMessages.targetDeviceUnavailable}\n${healthResult.errorMessage}',
        );
      }
      
      // Step 3: Get local IP address for senderIP field
      final senderIP = await _getLocalIPAddress();
      final fileName = file.path.split('/').last;
      
      // Step 4: Call /confirm-receive endpoint to ask for user confirmation
      onStatusChange?.call('等待接收方确认...');
      
      String confirmUrl;
      if (targetIP.contains(':')) {
        confirmUrl = 'http://$targetIP/confirm-receive';
      } else {
        confirmUrl = 'http://$targetIP:8080/confirm-receive';
      }
      
      final confirmUri = Uri.parse(confirmUrl).replace(queryParameters: {
        'fileName': fileName,
        'fileSize': fileSize.toString(),
        'senderIP': senderIP,
      });
      
      // Use longer timeout for confirmation request to allow user time to respond
      // User has 30 seconds to confirm, so we use 35 seconds timeout
      final confirmResponse = await http.get(confirmUri).timeout(_confirmTimeout);
      
      // Check confirmation response
      if (confirmResponse.statusCode != 200) {
        try {
          final data = jsonDecode(confirmResponse.body) as Map<String, dynamic>;
          return TransferResult(
            success: false,
            errorMessage: data['message'] as String? ?? ErrorMessages.transferRejected,
          );
        } catch (e) {
          return TransferResult(
            success: false,
            errorMessage: ErrorMessages.transferRejected,
          );
        }
      }
      
      // Parse confirmation response
      String transferId;
      try {
        final confirmData = jsonDecode(confirmResponse.body) as Map<String, dynamic>;
        
        if (confirmData['accepted'] != true) {
          return TransferResult(
            success: false,
            errorMessage: confirmData['message'] as String? ?? ErrorMessages.transferRejected,
          );
        }
        
        transferId = confirmData['transferId'] as String;
      } catch (e) {
        return TransferResult(
          success: false,
          errorMessage: ErrorMessages.responseParseError,
        );
      }
      
      // Step 5: User accepted, proceed with file transfer
      onStatusChange?.call('正在传输文件...');
      
      // Prepare URL with metadata as query parameters
      String baseUrl;
      if (targetIP.contains(':')) {
        baseUrl = 'http://$targetIP/transfer';
      } else {
        baseUrl = 'http://$targetIP:8080/transfer';
      }
      
      // Build URL with query parameters including transferId
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'fileName': fileName,
        'fileSize': fileSize.toString(),
        'senderIP': senderIP,
        'transferId': transferId,
      });
      
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
        rethrow;
      }
      
      // Phase 2: Waiting for server response (90-100% progress)
      // At this point, all data has been sent over the network
      // We're just waiting for the server to process and respond
      onStatusChange?.call('等待服务器响应...');
      
      // Set progress to 90%
      if (onProgress != null) {
        onProgress(0.90, fileSize, fileSize);
      }
      
      print('[Progress] Phase 1 complete at 90%, waiting for server response...');
      print('[Progress] Phase 1 complete at 90%, waiting for server response...');
      
      // Wait for response with extended timeout for large files
      final responseCompleter = Completer<http.Response>();
      
      final startWaitTime = DateTime.now();
      print('[Progress] Waiting for response at ${startWaitTime}...');
      
      // Handle response
      responseFuture.timeout(
        Duration(seconds: 60 + (fileSize ~/ (1024 * 1024))),
      ).then((streamedResponse) async {
        final waitDuration = DateTime.now().difference(startWaitTime);
        print('[Progress] Response received after ${waitDuration.inMilliseconds}ms!');
        
        // Set progress to 100%
        if (onProgress != null) {
          onProgress(1.0, fileSize, fileSize);
        }
        
        final response = await http.Response.fromStream(streamedResponse);
        responseCompleter.complete(response);
      }).catchError((error) {
        print('[Progress] Error: $error');
        responseCompleter.completeError(error);
      });
      
      // Await the response
      final response = await responseCompleter.future;
      
      // Check response
      if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            
            if (data['success'] == true) {
              // Save to history
              await _historyService.saveTransfer(TransferHistory(
                fileName: fileName,
                fileSize: fileSize,
                peerIP: targetIP,
                timestamp: DateTime.now(),
                isReceived: false,
                success: true,
              ));
              
              return TransferResult(
                success: true,
                savedPath: data['savedPath'] as String?,
              );
            } else {
              // Save failed transfer to history
              await _historyService.saveTransfer(TransferHistory(
                fileName: fileName,
                fileSize: fileSize,
                peerIP: targetIP,
                timestamp: DateTime.now(),
                isReceived: false,
                success: false,
              ));
              
              return TransferResult(
                success: false,
                errorMessage: data['message'] as String? ?? ErrorMessages.genericError('文件传输'),
              );
            }
          } catch (e) {
            return TransferResult(
              success: false,
              errorMessage: ErrorMessages.responseParseError,
            );
          }
        } else if (response.statusCode == 403) {
          // Save rejected transfer to history
          await _historyService.saveTransfer(TransferHistory(
            fileName: fileName,
            fileSize: fileSize,
            peerIP: targetIP,
            timestamp: DateTime.now(),
            isReceived: false,
            success: false,
          ));
          
          return TransferResult(
            success: false,
            errorMessage: ErrorMessages.transferRejected,
          );
        } else if (response.statusCode == 413) {
          return TransferResult(
            success: false,
            errorMessage: ErrorMessages.fileOrStorageFull,
          );
        } else {
          return TransferResult(
            success: false,
            errorMessage: ErrorMessages.responseStatusCodeError(response.statusCode),
          );
        }
    } on SocketException {
      return TransferResult(
        success: false,
        errorMessage: ErrorMessages.networkConnectionFailed,
      );
    } on http.ClientException {
      return TransferResult(
        success: false,
        errorMessage: ErrorMessages.networkRequestFailed,
      );
    } on TimeoutException {
      return TransferResult(
        success: false,
        errorMessage: ErrorMessages.transferTimeout,
      );
    } catch (e) {
      return TransferResult(
        success: false,
        errorMessage: ErrorMessages.unexpectedError(e.toString()),
      );
    }
  }
  
  /// Get the local IP address of the device
  Future<String> _getLocalIPAddress() async {
    try {
      // Get all network interfaces
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // Find the first non-loopback address
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }

      // Fallback to localhost if no network interface found
      return '127.0.0.1';
    } catch (e) {
      // If error, return localhost
      return '127.0.0.1';
    }
  }
  
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
  /// 
  /// Returns [ConfirmationResult] indicating whether the user accepted
  Future<ConfirmationResult> askReceiveConfirmation({
    required BuildContext context,
    required String fileName,
    required int fileSize,
    required String senderIP,
  }) async {
    try {
      // Show confirmation dialog to user
      final notificationService = NotificationService();
      final confirmationResult = await notificationService.showReceiveConfirmation(
        context: context,
        senderIP: senderIP,
        fileName: fileName,
        fileSize: fileSize,
      );
      
      // Check if user rejected or timed out
      if (!confirmationResult.accepted) {
        return ConfirmationResult(
          accepted: false,
          errorMessage: confirmationResult.timedOut 
              ? ErrorMessages.receiveTimeout
              : ErrorMessages.userRejected,
        );
      }
      
      // User accepted
      return ConfirmationResult(
        accepted: true,
      );
      
    } catch (e) {
      return ConfirmationResult(
        accepted: false,
        errorMessage: ErrorMessages.unexpectedError(e.toString()),
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
  /// 
  /// Returns [DirectReceiveResult] indicating whether the file was saved successfully
  Future<DirectReceiveResult> receiveFileDirectly({
    required Stream<List<int>> fileStream,
    required String fileName,
    required int fileSize,
    required String senderIP,
  }) async {
    try {
      // Check storage space
      final hasEnoughSpace = await _checkStorageSpace(fileSize);
      if (!hasEnoughSpace) {
        // Drain the stream
        await fileStream.drain();
        
        return DirectReceiveResult(
          success: false,
          errorMessage: ErrorMessages.storageInsufficient,
        );
      }
      
      // Get downloads directory
      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        // Drain the stream
        await fileStream.drain();
        
        return DirectReceiveResult(
          success: false,
          errorMessage: ErrorMessages.downloadsDirectoryUnavailable,
        );
      }
      
      // Handle file name conflicts
      final finalFileName = await _resolveFileNameConflict(downloadsDir, fileName);
      final filePath = '${downloadsDir.path}/$finalFileName';
      
      // Save file data using streaming for memory efficiency
      final file = File(filePath);
      final sink = file.openWrite();
      
      try {
        // Write file data from stream
        await for (final chunk in fileStream) {
          sink.add(chunk);
        }
        await sink.flush();
        await sink.close();
      } catch (e) {
        // Clean up on error
        await sink.close();
        if (await file.exists()) {
          await file.delete();
        }
        
        // Save failed transfer to history
        await _historyService.saveTransfer(TransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          peerIP: senderIP,
          timestamp: DateTime.now(),
          isReceived: true,
          success: false,
        ));
        
        return DirectReceiveResult(
          success: false,
          errorMessage: ErrorMessages.fileSaveFailed,
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
        // File size mismatch, delete the file
        await file.delete();
        
        // Save failed transfer to history
        await _historyService.saveTransfer(TransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          peerIP: senderIP,
          timestamp: DateTime.now(),
          isReceived: true,
          success: false,
        ));
        
        return DirectReceiveResult(
          success: false,
          errorMessage: ErrorMessages.fileSizeMismatch,
        );
      }
      
      // Save to history with saved path
      await _historyService.saveTransfer(TransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        peerIP: senderIP,
        timestamp: DateTime.now(),
        isReceived: true,
        success: true,
        savedPath: filePath,
      ));
      
      return DirectReceiveResult(
        success: true,
        savedPath: filePath,
      );
      
    } catch (e) {
      // Save failed transfer to history
      await _historyService.saveTransfer(TransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        peerIP: senderIP,
        timestamp: DateTime.now(),
        isReceived: true,
        success: false,
      ));
      
      return DirectReceiveResult(
        success: false,
        errorMessage: ErrorMessages.unexpectedError(e.toString()),
      );
    }
  }
  
  /// Receive a file from another device (using raw binary stream)
  /// 
  /// This method is called by the HTTP server when a file transfer request arrives.
  /// It shows a confirmation dialog to the user, and if accepted, saves the file
  /// to the downloads directory using streaming to optimize memory usage.
  /// 
  /// IMPORTANT: The fileStream will only be consumed AFTER user confirmation,
  /// ensuring that file data is not read from the network until the user accepts.
  /// 
  /// Parameters:
  /// - [context]: BuildContext for showing dialogs
  /// - [fileStream]: Stream of raw file data (consumed only after confirmation)
  /// - [fileName]: Name of the file
  /// - [fileSize]: Size of the file in bytes
  /// - [senderIP]: IP address of the sender device
  /// 
  /// Returns [ReceiveResult] indicating whether the file was accepted and saved
  /// 
  /// Requirements: 3.3, 3.4, 3.5, 9.1, 9.2, 9.3
  Future<ReceiveResult> receiveFileFromStream({
    required BuildContext context,
    required Stream<List<int>> fileStream,
    required String fileName,
    required int fileSize,
    required String senderIP,
  }) async {
    try {
      // Step 1: Show confirmation dialog to user BEFORE reading file data
      final notificationService = NotificationService();
      final confirmationResult = await notificationService.showReceiveConfirmation(
        context: context,
        senderIP: senderIP,
        fileName: fileName,
        fileSize: fileSize,
      );
      
      // Check if user rejected or timed out
      if (!confirmationResult.accepted) {
        // User rejected - drain the stream to complete the HTTP request properly
        await fileStream.drain();
        
        return ReceiveResult(
          accepted: false,
          errorMessage: confirmationResult.timedOut 
              ? ErrorMessages.receiveTimeout
              : ErrorMessages.userRejected,
        );
      }
      
      // Step 2: User accepted, check storage space
      final hasEnoughSpace = await _checkStorageSpace(fileSize);
      if (!hasEnoughSpace) {
        // Drain the stream
        await fileStream.drain();
        
        return ReceiveResult(
          accepted: false,
          errorMessage: ErrorMessages.storageInsufficient,
        );
      }
      
      // Step 3: Get downloads directory
      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        // Drain the stream
        await fileStream.drain();
        
        return ReceiveResult(
          accepted: false,
          errorMessage: ErrorMessages.downloadsDirectoryUnavailable,
        );
      }
      
      // Step 4: Handle file name conflicts
      final finalFileName = await _resolveFileNameConflict(downloadsDir, fileName);
      final filePath = '${downloadsDir.path}/$finalFileName';
      
      // Step 5: NOW read and save file data using streaming for memory efficiency
      final file = File(filePath);
      final sink = file.openWrite();
      
      try {
        // Write file data from stream - this is when data is actually read from network
        await for (final chunk in fileStream) {
          sink.add(chunk);
        }
        await sink.flush();
        await sink.close();
      } catch (e) {
        // Clean up on error
        await sink.close();
        if (await file.exists()) {
          await file.delete();
        }
        
        // Save failed transfer to history
        await _historyService.saveTransfer(TransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          peerIP: senderIP,
          timestamp: DateTime.now(),
          isReceived: true,
          success: false,
        ));
        
        return ReceiveResult(
          accepted: false,
          errorMessage: ErrorMessages.fileSaveFailed,
        );
      }
      
      // Verify file was saved correctly
      if (!await file.exists()) {
        return ReceiveResult(
          accepted: false,
          errorMessage: ErrorMessages.fileSaveFailed,
        );
      }
      
      final savedSize = await file.length();
      if (savedSize != fileSize) {
        // File size mismatch, delete the file
        await file.delete();
        
        // Save failed transfer to history
        await _historyService.saveTransfer(TransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          peerIP: senderIP,
          timestamp: DateTime.now(),
          isReceived: true,
          success: false,
        ));
        
        return ReceiveResult(
          accepted: false,
          errorMessage: ErrorMessages.fileSizeMismatch,
        );
      }
      
      // Step 6: Return success result
      // Save to history with saved path
      await _historyService.saveTransfer(TransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        peerIP: senderIP,
        timestamp: DateTime.now(),
        isReceived: true,
        success: true,
        savedPath: filePath,
      ));
      
      return ReceiveResult(
        accepted: true,
        savedPath: filePath,
      );
      
    } catch (e) {
      // Save failed transfer to history
      await _historyService.saveTransfer(TransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        peerIP: senderIP,
        timestamp: DateTime.now(),
        isReceived: true,
        success: false,
      ));
      
      return ReceiveResult(
        accepted: false,
        errorMessage: ErrorMessages.unexpectedError(e.toString()),
      );
    }
  }
  
  /// Receive a file from another device
  /// 
  /// This method is called by the HTTP server when a file transfer request arrives.
  /// It shows a confirmation dialog to the user, and if accepted, saves the file
  /// to the downloads directory using streaming to optimize memory usage.
  /// 
  /// IMPORTANT: The fileStream will only be consumed AFTER user confirmation,
  /// ensuring that file data is not read from the network until the user accepts.
  /// 
  /// Parameters:
  /// - [context]: BuildContext for showing dialogs
  /// - [fileStream]: MimeMultipart stream of file data (consumed only after confirmation)
  /// - [fileName]: Name of the file
  /// - [fileSize]: Size of the file in bytes
  /// - [senderIP]: IP address of the sender device
  /// 
  /// Returns [ReceiveResult] indicating whether the file was accepted and saved
  /// 
  /// Requirements: 3.3, 3.4, 3.5, 9.1, 9.2, 9.3
  Future<ReceiveResult> receiveFile({
    required BuildContext context,
    required MimeMultipart fileStream,
    required String fileName,
    required int fileSize,
    required String senderIP,
  }) async {
    try {
      // Step 1: Show confirmation dialog to user BEFORE reading file data
      final notificationService = NotificationService();
      final confirmationResult = await notificationService.showReceiveConfirmation(
        context: context,
        senderIP: senderIP,
        fileName: fileName,
        fileSize: fileSize,
      );
      
      // Check if user rejected or timed out
      if (!confirmationResult.accepted) {
        // User rejected - drain the stream to complete the HTTP request properly
        await fileStream.drain();
        
        return ReceiveResult(
          accepted: false,
          errorMessage: confirmationResult.timedOut 
              ? ErrorMessages.receiveTimeout
              : ErrorMessages.userRejected,
        );
      }
      
      // Step 2: User accepted, check storage space
      final hasEnoughSpace = await _checkStorageSpace(fileSize);
      if (!hasEnoughSpace) {
        // Drain the stream
        await fileStream.drain();
        
        return ReceiveResult(
          accepted: false,
          errorMessage: ErrorMessages.storageInsufficient,
        );
      }
      
      // Step 3: Get downloads directory
      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        // Drain the stream
        await fileStream.drain();
        
        return ReceiveResult(
          accepted: false,
          errorMessage: ErrorMessages.downloadsDirectoryUnavailable,
        );
      }
      
      // Step 4: Handle file name conflicts
      final finalFileName = await _resolveFileNameConflict(downloadsDir, fileName);
      final filePath = '${downloadsDir.path}/$finalFileName';
      
      // Step 5: NOW read and save file data using streaming for memory efficiency
      final file = File(filePath);
      final sink = file.openWrite();
      
      try {
        // Write file data from stream - this is when data is actually read from network
        await for (final chunk in fileStream) {
          sink.add(chunk);
        }
        await sink.flush();
        await sink.close();
      } catch (e) {
        // Clean up on error
        await sink.close();
        if (await file.exists()) {
          await file.delete();
        }
        
        // Save failed transfer to history
        await _historyService.saveTransfer(TransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          peerIP: senderIP,
          timestamp: DateTime.now(),
          isReceived: true,
          success: false,
        ));
        
        return ReceiveResult(
          accepted: false,
          errorMessage: ErrorMessages.fileSaveFailed,
        );
      }
      
      // Verify file was saved correctly
      if (!await file.exists()) {
        return ReceiveResult(
          accepted: false,
          errorMessage: ErrorMessages.fileSaveFailed,
        );
      }
      
      final savedSize = await file.length();
      if (savedSize != fileSize) {
        // File size mismatch, delete the file
        await file.delete();
        
        // Save failed transfer to history
        await _historyService.saveTransfer(TransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          peerIP: senderIP,
          timestamp: DateTime.now(),
          isReceived: true,
          success: false,
        ));
        
        return ReceiveResult(
          accepted: false,
          errorMessage: ErrorMessages.fileSizeMismatch,
        );
      }
      
      // Step 6: Return success result
      // Save to history with saved path
      await _historyService.saveTransfer(TransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        peerIP: senderIP,
        timestamp: DateTime.now(),
        isReceived: true,
        success: true,
        savedPath: filePath,
      ));
      
      return ReceiveResult(
        accepted: true,
        savedPath: filePath,
      );
      
    } catch (e) {
      // Save failed transfer to history
      await _historyService.saveTransfer(TransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        peerIP: senderIP,
        timestamp: DateTime.now(),
        isReceived: true,
        success: false,
      ));
      
      return ReceiveResult(
        accepted: false,
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
          final downloadsPath = directory.path.replaceAll('Android/data/com.example.icy_easy_send/files', 'Download');
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
  Future<String> _resolveFileNameConflict(Directory directory, String fileName) async {
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
}
