import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:flutter/material.dart';
import 'file_transfer_service.dart';
import '../utils/error_messages.dart';

/// Result of file transfer operation
class FileTransferResult {
  final bool success;
  final String message;
  final String? savedPath;

  FileTransferResult({
    required this.success,
    required this.message,
    this.savedPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (savedPath != null) 'savedPath': savedPath,
    };
  }
}

/// Handler for file transfer endpoint
///
/// Provides a RESTful endpoint to receive files from other devices.
class FileTransferHandler {
  final BuildContext? Function()? contextGetter;
  final FileTransferService _fileTransferService;

  // Store pending transfer confirmations with transfer ID as key
  final Map<String, bool> _pendingConfirmations = {};

  // Store auto-accept state for batch transfers: senderIP -> remaining count
  final Map<String, int> _autoAcceptRemaining = {};

  FileTransferHandler({
    this.contextGetter,
    FileTransferService? fileTransferService,
  }) : _fileTransferService = fileTransferService ?? FileTransferService();

  /// Handle GET /confirm-receive requests
  ///
  /// This endpoint is called BEFORE file transfer to ask user for confirmation.
  /// Expects query parameters:
  /// - fileName: name of the file
  /// - fileSize: size of the file in bytes
  /// - senderIP: IP address of the sender
  /// - senderDeviceName: (optional) name of the sender device
  /// - remainingFiles: (optional) number of remaining files in batch
  ///
  /// Returns a JSON response with:
  /// - accepted: true if user accepted, false if rejected
  /// - transferId: unique ID for this transfer (if accepted)
  /// - message: error or success message
  Future<Response> handleConfirmReceive(Request request) async {
    try {
      // Extract metadata from query parameters
      final queryParams = request.url.queryParameters;
      final fileName = queryParams['fileName'];
      final fileSizeStr = queryParams['fileSize'];
      final senderIP = queryParams['senderIP'];
      final senderDeviceName = queryParams['senderDeviceName'];
      final remainingFilesStr = queryParams['remainingFiles'];

      // Validate required parameters
      if (fileName == null || fileName.isEmpty) {
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'message': '缺少文件名参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (fileSizeStr == null) {
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'message': '缺少文件大小参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final fileSize = int.tryParse(fileSizeStr);
      if (fileSize == null) {
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'message': '文件大小参数格式错误'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (senderIP == null || senderIP.isEmpty) {
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'message': '缺少发送者 IP 参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Parse remaining files count
      final remainingFiles = remainingFilesStr != null
          ? int.tryParse(remainingFilesStr)
          : null;

      // Check if we have auto-accept enabled for this sender
      final autoAcceptCount = _autoAcceptRemaining[senderIP] ?? 0;

      bool autoAccept = false;

      if (autoAcceptCount > 0) {
        // Auto-accept this file
        _autoAcceptRemaining[senderIP] = autoAcceptCount - 1;

        // Clean up if no more auto-accepts
        if (_autoAcceptRemaining[senderIP]! <= 0) {
          _autoAcceptRemaining.remove(senderIP);
        }
      } else {
        // Check if context is available for showing dialogs
        final ctx = contextGetter?.call();

        if (ctx == null) {
          return Response(
            500,
            body: jsonEncode({'accepted': false, 'message': '无法显示确认对话框：缺少上下文'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Ask user for confirmation
        final confirmResult = await _fileTransferService.askReceiveConfirmation(
          context: ctx,
          fileName: fileName,
          fileSize: fileSize,
          senderIP: senderIP,
          senderDeviceName: senderDeviceName,
          remainingFiles: remainingFiles,
        );

        if (!confirmResult.accepted) {
          // User rejected, clear any auto-accept state
          _autoAcceptRemaining.remove(senderIP);

          return Response(
            403,
            body: jsonEncode({
              'accepted': false,
              'message':
                  confirmResult.errorMessage ?? ErrorMessages.userRejected,
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }

        autoAccept = confirmResult.autoAcceptRemaining;

        // If user chose to auto-accept remaining files, store the count
        if (autoAccept && remainingFiles != null && remainingFiles > 0) {
          _autoAcceptRemaining[senderIP] = remainingFiles;
        }
      }

      // User accepted (or auto-accepted), generate a transfer ID and store confirmation
      final transferId =
          '${senderIP}_${fileName}_${DateTime.now().millisecondsSinceEpoch}';
      _pendingConfirmations[transferId] = true;

      // Return success response with transfer ID
      return Response.ok(
        jsonEncode({
          'accepted': true,
          'transferId': transferId,
          'message': autoAcceptCount > 0 ? '自动接收文件' : '用户已确认接收文件',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      print('Error in confirm receive: $e');
      print('Stack trace: $stackTrace');
      return Response(
        500,
        body: jsonEncode({
          'accepted': false,
          'message': ErrorMessages.unexpectedError(e.toString()),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Handle POST /transfer requests
  ///
  /// Expects metadata in query parameters:
  /// - fileName: name of the file
  /// - fileSize: size of the file in bytes
  /// - senderIP: IP address of the sender
  /// - transferId: transfer ID from confirm-receive response
  ///
  /// File data should be sent as raw binary in request body
  ///
  /// NOTE: User confirmation should be done via /confirm-receive endpoint first
  Future<Response> handleFileTransfer(Request request) async {
    try {
      // Extract metadata from query parameters
      final queryParams = request.url.queryParameters;
      final fileName = queryParams['fileName'];
      final fileSizeStr = queryParams['fileSize'];
      final senderIP = queryParams['senderIP'];
      final senderDeviceName = queryParams['senderDeviceName'];
      final transferId = queryParams['transferId'];

      // Validate required parameters
      if (fileName == null || fileName.isEmpty) {
        return Response(
          400,
          body: jsonEncode({'success': false, 'message': '缺少文件名参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (fileSizeStr == null) {
        return Response(
          400,
          body: jsonEncode({'success': false, 'message': '缺少文件大小参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final fileSize = int.tryParse(fileSizeStr);
      if (fileSize == null) {
        return Response(
          400,
          body: jsonEncode({'success': false, 'message': '文件大小参数格式错误'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (senderIP == null || senderIP.isEmpty) {
        return Response(
          400,
          body: jsonEncode({'success': false, 'message': '缺少发送者 IP 参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (transferId == null || transferId.isEmpty) {
        return Response(
          400,
          body: jsonEncode({
            'success': false,
            'message': '缺少传输 ID 参数，请先调用 /confirm-receive 接口',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if this transfer was confirmed
      if (!_pendingConfirmations.containsKey(transferId)) {
        return Response(
          403,
          body: jsonEncode({
            'success': false,
            'message': '未找到确认记录，请先调用 /confirm-receive 接口',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Remove the confirmation record (one-time use)
      _pendingConfirmations.remove(transferId);

      // Get the request body stream (file data)
      final fileStream = request.read();

      // Call FileTransferService to save the file directly (no confirmation needed)
      final receiveResult = await _fileTransferService.receiveFileDirectly(
        fileStream: fileStream,
        fileName: fileName,
        fileSize: fileSize,
        senderIP: senderIP,
        senderDeviceName: senderDeviceName,
      );

      // Check if file was saved successfully
      if (!receiveResult.success) {
        return Response(
          500,
          body: jsonEncode({
            'success': false,
            'message':
                receiveResult.errorMessage ?? ErrorMessages.fileSaveFailed,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Return success response
      final result = FileTransferResult(
        success: true,
        message: '文件接收成功',
        savedPath: receiveResult.savedPath,
      );

      return Response.ok(
        jsonEncode(result.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      print('Error in file transfer: $e');
      print('Stack trace: $stackTrace');
      return Response(
        500,
        body: jsonEncode({
          'success': false,
          'message': ErrorMessages.unexpectedError(e.toString()),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
