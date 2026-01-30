import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';

import '../utils/error_messages.dart';
import '../utils/log_util.dart';
import 'batch_receive_manager.dart';
import 'file_transfer_service.dart';

/// Handler for file transfer endpoint
///
/// Provides a RESTful endpoint to receive files from other devices.
class FileTransferHandler {
  final BuildContext? Function()? contextGetter;
  final FileTransferService _fileTransferService;
  final BatchReceiveManager _batchReceiveManager;
  final String logTag = LogTags.server;

  // Store pending transfer confirmations with transfer ID as key
  final Map<String, bool> _pendingConfirmations = {};

  // Store progress callbacks for active transfers: transferId -> callback
  final Map<String, void Function(double, int, int)> _progressCallbacks = {};

  FileTransferHandler({
    this.contextGetter,
    FileTransferService? fileTransferService,
    BatchReceiveManager? batchReceiveManager,
  }) : _fileTransferService = fileTransferService ?? FileTransferService(),
       _batchReceiveManager = batchReceiveManager ?? BatchReceiveManager();

  /// Register a progress callback for a transfer
  void registerProgressCallback(
    String transferId,
    void Function(double progress, int bytesReceived, int totalBytes) callback,
  ) {
    _progressCallbacks[transferId] = callback;
  }

  /// Unregister a progress callback
  void unregisterProgressCallback(String transferId) {
    _progressCallbacks.remove(transferId);
  }

  /// Handle POST /batch-confirm-receive requests
  ///
  /// This endpoint is called BEFORE file transfer to ask user for confirmation of multiple files.
  /// Expects JSON body with:
  /// - files: array of file objects with fileName and fileSize
  /// - senderIP: IP address of the sender
  /// - senderDeviceName: (optional) name of the sender device
  ///
  /// Returns a JSON response with:
  /// - accepted: true if user accepted, false if rejected
  /// - transferIds: map of fileName -> transferId (if accepted)
  /// - message: error or success message
  Future<Response> handleBatchConfirmReceive(Request request) async {
    LogUtil.iTag(logTag, '收到批量确认请求: /batch-confirm-receive');

    try {
      // Parse JSON body
      final bodyString = await request.readAsString();
      final Map<String, dynamic> body;

      try {
        body = jsonDecode(bodyString) as Map<String, dynamic>;
      } catch (e) {
        LogUtil.wTag(logTag, '无效的JSON格式: $bodyString');
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'message': '无效的JSON格式'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Extract parameters
      final files = body['files'] as List<dynamic>?;
      final senderIP = body['senderIP'] as String?;
      final senderDeviceName = body['senderDeviceName'] as String?;

      LogUtil.dTag(
        logTag,
        '批量确认参数: 文件数=${files?.length ?? 0}, 发送方=$senderIP, 设备名=$senderDeviceName',
      );

      // Validate required parameters
      if (files == null || files.isEmpty) {
        LogUtil.wTag(logTag, '缺少文件列表参数');
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'message': '缺少文件列表参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (senderIP == null || senderIP.isEmpty) {
        LogUtil.wTag(logTag, '缺少发送者IP参数');
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'message': '缺少发送者 IP 参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if context is available for showing dialogs
      final ctx = contextGetter?.call();

      if (ctx == null || !ctx.mounted) {
        LogUtil.eTag(logTag, '无法显示确认对话框：缺少上下文');
        return Response(
          500,
          body: jsonEncode({'accepted': false, 'message': '无法显示确认对话框：缺少上下文'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Create PendingFileInfo for each file
      final pendingFiles = <PendingFileInfo>[];
      final transferIds = <String, String>{};

      for (final fileData in files) {
        final fileMap = fileData as Map<String, dynamic>;
        final fileName = fileMap['fileName'] as String?;
        final fileSize = fileMap['fileSize'] as int?;

        if (fileName == null || fileSize == null) {
          LogUtil.wTag(logTag, '跳过无效的文件条目: $fileMap');
          continue; // Skip invalid file entries
        }

        // Generate transfer ID
        final transferId =
            '${senderIP}_${fileName}_${DateTime.now().millisecondsSinceEpoch}';
        transferIds[fileName] = transferId;

        // Create file info
        final fileInfo = PendingFileInfo(
          fileName: fileName,
          fileSize: fileSize,
          senderIP: senderIP,
          senderDeviceName: senderDeviceName,
          completer: Completer<bool>(),
          transferId: transferId,
        );

        pendingFiles.add(fileInfo);
      }

      if (pendingFiles.isEmpty) {
        LogUtil.wTag(logTag, '没有有效的文件');
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'message': '没有有效的文件'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      LogUtil.iTag(logTag, '显示批量接收确认对话框: ${pendingFiles.length}个文件');

      // Show batch dialog with all files at once
      final accepted = await _batchReceiveManager
          .requestBatchReceiveConfirmation(
            context: ctx,
            files: pendingFiles,
            senderIP: senderIP,
            senderDeviceName: senderDeviceName,
          );

      if (!accepted) {
        LogUtil.iTag(logTag, '用户拒绝接收批量文件');
        return Response(
          403,
          body: jsonEncode({
            'accepted': false,
            'message': ErrorMessages.userRejected,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // User accepted, store confirmations and register progress callbacks
      for (final fileInfo in pendingFiles) {
        _pendingConfirmations[fileInfo.transferId] = true;

        // Register progress callback to update batch dialog
        registerProgressCallback(fileInfo.transferId, (
          progress,
          bytesReceived,
          totalBytes,
        ) {
          _batchReceiveManager.updateProgress(
            fileInfo.transferId,
            progress,
            bytesReceived,
            totalBytes,
          );
        });
      }

      LogUtil.iTag(logTag, '用户确认接收批量文件: ${pendingFiles.length}个文件');

      // Return success response with transfer IDs
      return Response.ok(
        jsonEncode({
          'accepted': true,
          'transferIds': transferIds,
          'message': '用户已确认接收所有文件',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '批量确认接收处理异常: $e', e, stackTrace);
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

  /// Handle GET /confirm-receive requests (legacy single file confirmation)
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
    LogUtil.iTag(logTag, '收到单文件确认请求: /confirm-receive');

    try {
      // Extract metadata from query parameters
      final queryParams = request.url.queryParameters;
      final fileName = queryParams['fileName'];
      final fileSizeStr = queryParams['fileSize'];
      final senderIP = queryParams['senderIP'];
      final senderDeviceName = queryParams['senderDeviceName'];

      LogUtil.dTag(
        logTag,
        '确认参数: 文件=$fileName, 大小=$fileSizeStr, 发送方=$senderIP',
      );

      // Validate required parameters
      if (fileName == null || fileName.isEmpty) {
        LogUtil.wTag(logTag, '缺少文件名参数');
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'message': '缺少文件名参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (fileSizeStr == null) {
        LogUtil.wTag(logTag, '缺少文件大小参数');
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'message': '缺少文件大小参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final fileSize = int.tryParse(fileSizeStr);
      if (fileSize == null) {
        LogUtil.wTag(logTag, '文件大小参数格式错误: $fileSizeStr');
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'message': '文件大小参数格式错误'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (senderIP == null || senderIP.isEmpty) {
        LogUtil.wTag(logTag, '缺少发送者IP参数');
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'message': '缺少发送者 IP 参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if context is available for showing dialogs
      final ctx = contextGetter?.call();

      if (ctx == null || !ctx.mounted) {
        LogUtil.eTag(logTag, '无法显示确认对话框：缺少上下文');
        return Response(
          500,
          body: jsonEncode({'accepted': false, 'message': '无法显示确认对话框：缺少上下文'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Generate transfer ID
      final transferId =
          '${senderIP}_${fileName}_${DateTime.now().millisecondsSinceEpoch}';

      LogUtil.iTag(logTag, '显示接收确认对话框: $fileName');

      // Use batch receive manager to handle confirmation
      // This will batch multiple files from the same sender into one dialog
      final accepted = await _batchReceiveManager.requestReceiveConfirmation(
        context: ctx,
        fileName: fileName,
        fileSize: fileSize,
        senderIP: senderIP,
        senderDeviceName: senderDeviceName,
        transferId: transferId,
      );

      if (!accepted) {
        LogUtil.iTag(logTag, '用户拒绝接收文件: $fileName');
        return Response(
          403,
          body: jsonEncode({
            'accepted': false,
            'message': ErrorMessages.userRejected,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // User accepted, store confirmation
      _pendingConfirmations[transferId] = true;

      // Register progress callback to update batch dialog
      registerProgressCallback(transferId, (
        progress,
        bytesReceived,
        totalBytes,
      ) {
        _batchReceiveManager.updateProgress(
          transferId,
          progress,
          bytesReceived,
          totalBytes,
        );
      });

      LogUtil.iTag(logTag, '用户确认接收文件: $fileName, transferId=$transferId');

      // Return success response with transfer ID
      return Response.ok(
        jsonEncode({
          'accepted': true,
          'transferId': transferId,
          'message': '用户已确认接收文件',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '确认接收处理异常: $e', e, stackTrace);
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
    LogUtil.iTag(LogTags.transfer, '收到文件传输请求: /transfer');

    try {
      // Extract metadata from query parameters
      final queryParams = request.url.queryParameters;
      final fileName = queryParams['fileName'];
      final fileSizeStr = queryParams['fileSize'];
      final senderIP = queryParams['senderIP'];
      final senderDeviceName = queryParams['senderDeviceName'];
      final transferId = queryParams['transferId'];

      LogUtil.dTag(
        LogTags.transfer,
        '传输参数: 文件=$fileName, 大小=$fileSizeStr, 发送方=$senderIP, transferId=$transferId',
      );

      // Validate required parameters
      if (fileName == null || fileName.isEmpty) {
        LogUtil.wTag(LogTags.transfer, '缺少文件名参数');
        return Response(
          400,
          body: jsonEncode({'success': false, 'message': '缺少文件名参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (fileSizeStr == null) {
        LogUtil.wTag(LogTags.transfer, '缺少文件大小参数');
        return Response(
          400,
          body: jsonEncode({'success': false, 'message': '缺少文件大小参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final fileSize = int.tryParse(fileSizeStr);
      if (fileSize == null) {
        LogUtil.wTag(LogTags.transfer, '文件大小参数格式错误: $fileSizeStr');
        return Response(
          400,
          body: jsonEncode({'success': false, 'message': '文件大小参数格式错误'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (senderIP == null || senderIP.isEmpty) {
        LogUtil.wTag(LogTags.transfer, '缺少发送者IP参数');
        return Response(
          400,
          body: jsonEncode({'success': false, 'message': '缺少发送者 IP 参数'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (transferId == null || transferId.isEmpty) {
        LogUtil.wTag(LogTags.transfer, '缺少传输ID参数');
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
        LogUtil.wTag(LogTags.transfer, '未找到确认记录: $transferId');
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

      LogUtil.iTag(
        LogTags.transfer,
        '开始接收文件流: $fileName, 大小=${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
      );

      // Get the request body stream (file data)
      final fileStream = request.read();

      // Get progress callback if registered
      final progressCallback = _progressCallbacks[transferId];

      // Call FileTransferService to save the file directly (no confirmation needed)
      final receiveResult = await _fileTransferService.receiveFileDirectly(
        fileStream: fileStream,
        fileName: fileName,
        fileSize: fileSize,
        senderIP: senderIP,
        senderDeviceName: senderDeviceName,
        onProgress: progressCallback,
      );

      // Clean up progress callback
      unregisterProgressCallback(transferId);

      // Check if file was saved successfully
      if (!receiveResult.isSuccess) {
        LogUtil.wTag(
          LogTags.transfer,
          '文件接收失败: $fileName, 原因=${receiveResult.errorMessage}',
        );
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
      final result = {
        'success': true,
        'message': '文件接收成功',
        'savedPath': receiveResult.data?.savedPath,
      };

      LogUtil.iTag(
        LogTags.transfer,
        '文件传输完成: $fileName, 保存路径=${receiveResult.data?.savedPath}',
      );

      return Response.ok(
        jsonEncode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      LogUtil.eTag(LogTags.transfer, '文件传输处理异常: $e', e, stackTrace);
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
