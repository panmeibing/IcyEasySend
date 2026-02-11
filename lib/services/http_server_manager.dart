import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;

import '../utils/constants.dart';
import '../utils/error_messages.dart';
import '../utils/log_util.dart';
import '../utils/network_util.dart';
import 'file_transfer_handler.dart';
import 'health_check_handler.dart';

/// Result of server start operation
class ServerStartResult {
  final bool success;
  final String? errorMessage;
  final String? serverAddress;

  ServerStartResult({
    required this.success,
    this.errorMessage,
    this.serverAddress,
  });
}

/// Manages the HTTP server lifecycle
class HTTPServerManager {
  HttpServer? _server;
  String? _serverAddress;
  int? _currentPort;
  BuildContext? _context;
  VoidCallback? _historyRefreshCallback;
  final List<VoidCallback> _networkChangeCallbacks = [];

  final String logTag = LogTags.server;

  // API handlers
  final HealthCheckHandler _healthCheckHandler;
  late final FileTransferHandler _fileTransferHandler;

  // Network connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String? _lastKnownIP;

  HTTPServerManager({
    HealthCheckHandler? healthCheckHandler,
    FileTransferHandler? fileTransferHandler,
  }) : _healthCheckHandler = healthCheckHandler ?? HealthCheckHandler() {
    // Create file transfer handler with a context getter if not provided
    _fileTransferHandler =
        fileTransferHandler ??
        FileTransferHandler(
          contextGetter: () => _context,
          historyRefreshCallbackGetter: () => _historyRefreshCallback,
        );
  }

  /// Set the BuildContext for showing dialogs
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Set the callback to refresh history page
  void setHistoryRefreshCallback(VoidCallback callback) {
    _historyRefreshCallback = callback;
  }

  /// Add a callback to be notified of network changes
  void addNetworkChangeCallback(VoidCallback callback) {
    if (!_networkChangeCallbacks.contains(callback)) {
      _networkChangeCallbacks.add(callback);
    }
  }

  /// Remove a network change callback
  void removeNetworkChangeCallback(VoidCallback callback) {
    _networkChangeCallbacks.remove(callback);
  }

  /// Notify all registered callbacks about network change
  void _notifyNetworkChange() {
    for (final callback in _networkChangeCallbacks) {
      callback();
    }
  }

  /// Start monitoring network connectivity changes
  void startNetworkMonitoring() {
    LogUtil.iTag(logTag, '开始监听网络变化...');

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        LogUtil.iTag(logTag, '检测到网络变化: $results');

        // Wait a bit for network to stabilize
        await Future.delayed(const Duration(seconds: 1));

        // Check if server is running
        if (!isRunning()) {
          LogUtil.dTag(logTag, '服务器未运行，跳过网络变化处理');
          return;
        }

        // Get current IP address
        final currentIP = await NetworkUtil.getLocalIPAddress();

        // Check if IP has changed
        if (_lastKnownIP != null && _lastKnownIP != currentIP) {
          LogUtil.iTag(logTag, 'IP地址已变化: $_lastKnownIP -> $currentIP');

          // Restart server to update IP
          await _restartServerOnNetworkChange();
        } else {
          LogUtil.dTag(logTag, 'IP地址未变化: $currentIP');
          _lastKnownIP = currentIP;
        }
      },
      onError: (error) {
        LogUtil.eTag(logTag, '网络监听出错: $error');
      },
    );
  }

  /// Stop monitoring network connectivity changes
  void stopNetworkMonitoring() {
    LogUtil.iTag(logTag, '停止监听网络变化');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Restart server when network changes
  Future<void> _restartServerOnNetworkChange() async {
    LogUtil.iTag(logTag, '网络变化，重启服务器以更新IP地址...');

    final currentPort = _currentPort;

    // Stop current server
    await stopServer();

    // Start server with same port
    final result = await startServer(port: currentPort);

    if (result.success) {
      LogUtil.iTag(logTag, '服务器重启成功，新地址: ${result.serverAddress}');

      // Notify all registered callbacks
      _notifyNetworkChange();
    } else {
      LogUtil.eTag(logTag, '服务器重启失败: ${result.errorMessage}');
    }
  }

  /// Trigger history refresh (called after file transfer completes)
  void refreshHistory() {
    _historyRefreshCallback?.call();
  }

  /// Check if server is currently running
  bool isRunning() {
    return _server != null;
  }

  /// Get the current server address (IP:Port)
  String? getServerAddress() {
    return _serverAddress;
  }

  /// Start the HTTP server on the specified port or find an available port
  /// in the range [AppConstants.defaultPort] to [AppConstants.maxServerPort]
  Future<ServerStartResult> startServer({int? port}) async {
    // Use default port if not specified
    final startPort = port ?? AppConstants.defaultPort;

    // If server is already running, return success
    if (isRunning()) {
      LogUtil.iTag(logTag, '服务器已在运行: $_serverAddress');
      return ServerStartResult(success: true, serverAddress: _serverAddress);
    }

    String separator = AppConstants.diagInfoSeparator;
    LogUtil.iTag(logTag, separator * 3);
    LogUtil.iTag(logTag, '开始启动HTTP服务器');
    LogUtil.iTag(logTag, '尝试端口范围: $startPort-${AppConstants.maxServerPort}');
    LogUtil.iTag(logTag, separator * 3);

    // Try to start server on the specified port or find an available port
    for (
      int tryPort = startPort;
      tryPort <= AppConstants.maxServerPort;
      tryPort++
    ) {
      try {
        LogUtil.dTag(logTag, '尝试绑定端口: $tryPort');

        // Create router and configure routes
        final router = shelf_router.Router();

        // Configure health check endpoint
        router.get('/health', _healthCheckHandler.handleHealthCheck);

        // Configure batch confirm receive endpoint (preferred for multiple files)
        router.post(
          '/batch-confirm-receive',
          _fileTransferHandler.handleBatchConfirmReceive,
        );

        // Configure file transfer endpoint
        router.post('/transfer', _fileTransferHandler.handleFileTransfer);

        // Create handler with middleware
        final handler = Pipeline()
            .addMiddleware(logRequests())
            .addHandler(router.call);

        // Try to bind to the port
        _server = await shelf_io.serve(
          handler,
          InternetAddress.anyIPv4,
          tryPort,
        );

        _currentPort = tryPort;

        // Get the local IP address
        final localIP = await NetworkUtil.getLocalIPAddress();
        _serverAddress = '$localIP:$tryPort';
        _lastKnownIP = localIP; // Store current IP for change detection

        LogUtil.iTag(logTag, '✅ 服务器启动成功！');
        LogUtil.iTag(logTag, '监听地址: 0.0.0.0:$tryPort');
        LogUtil.iTag(logTag, '本机IP: $localIP');
        LogUtil.iTag(logTag, '完整地址: $_serverAddress');
        LogUtil.iTag(logTag, separator * 3);

        // 测试健康检查端点
        _testHealthEndpoint(localIP, tryPort);

        return ServerStartResult(success: true, serverAddress: _serverAddress);
      } on SocketException catch (e) {
        // Port is in use or other socket error, try next port
        LogUtil.wTag(logTag, '端口 $tryPort 不可用: ${e.message}');
        if (tryPort == AppConstants.maxServerPort) {
          // Last port in range, return error
          LogUtil.eTag(
            logTag,
            '所有端口(${AppConstants.defaultPort}-${AppConstants.maxServerPort})都不可用',
          );
          return ServerStartResult(
            success: false,
            errorMessage: ErrorMessages.serverPortsOccupied,
          );
        }
        // Continue to next port
        continue;
      } catch (e, stackTrace) {
        // Other errors
        LogUtil.eTag(logTag, '服务器启动失败: $e', e, stackTrace);
        return ServerStartResult(
          success: false,
          errorMessage: ErrorMessages.serverStartFailed(e.toString()),
        );
      }
    }

    // Should not reach here, but just in case
    LogUtil.eTag(logTag, '未知错误：无法启动服务器');
    return ServerStartResult(
      success: false,
      errorMessage: ErrorMessages.serverUnknownError,
    );
  }

  /// Test health endpoint after server starts
  void _testHealthEndpoint(String ip, int port) async {
    try {
      LogUtil.dTag(logTag, '测试健康检查端点...');
      final testUrl = NetworkUtil.buildHttpUrl(ip, '/health', targetPort: port);
      LogUtil.dTag(logTag, '测试URL: $testUrl');

      // Wait a bit for server to be fully ready
      await Future.delayed(const Duration(milliseconds: 500));

      final response = await HttpClient()
          .getUrl(Uri.parse(testUrl))
          .timeout(const Duration(seconds: 3))
          .then((request) => request.close())
          .then((response) => response);

      if (response.statusCode == 200) {
        LogUtil.iTag(logTag, '✅ 健康检查端点测试成功！');
      } else {
        LogUtil.wTag(logTag, '健康检查端点返回状态码: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '健康检查端点测试失败: $e (这可能表示存在网络配置问题)', e, stackTrace);
    }
  }

  /// Stop the HTTP server
  Future<void> stopServer() async {
    if (_server != null) {
      LogUtil.iTag(logTag, '正在停止HTTP服务器...');
      try {
        await _server!.close(force: true);
        LogUtil.iTag(logTag, '服务器已停止: $_serverAddress');
        _server = null;
        _serverAddress = null;
        _currentPort = null;
      } catch (e, stackTrace) {
        LogUtil.eTag(logTag, '停止服务器时出错: $e', e, stackTrace);
        // Still clean up the references
        _server = null;
        _serverAddress = null;
        _currentPort = null;
      }
    } else {
      LogUtil.dTag(logTag, '服务器未运行，无需停止');
    }
  }

  /// Dispose resources
  void dispose() {
    stopNetworkMonitoring();
    stopServer();
  }

  /// Get the current port number
  int? getCurrentPort() {
    return _currentPort;
  }

  /// Get the file transfer handler for registering progress callbacks
  FileTransferHandler getFileTransferHandler() {
    return _fileTransferHandler;
  }
}
