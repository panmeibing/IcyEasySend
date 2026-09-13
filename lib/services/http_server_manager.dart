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
import 'android_foreground_service.dart';
import 'clipboard_handler.dart';
import 'discover_register_handler.dart';
import 'file_transfer_handler.dart';
import 'health_check_handler.dart';
import 'identity_service.dart';
import 'multicast_discovery_service.dart';
import 'pairing_handler.dart';
import 'preferences_service.dart';
import 'relay/relay_service.dart';
import 'web_share_asset_handler.dart';
import 'web_share_handler.dart';
import 'web_share_service.dart';

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
  final List<VoidCallback> _serverStatusCallbacks = [];
  bool _isInBackground = false;

  /// Bumped on each successful bind / stop so deferred multicast/relay/FGS
  /// work from an older start cannot race past [stopServer].
  int _lifecycleGeneration = 0;

  final String logTag = LogTags.server;

  // API handlers
  final HealthCheckHandler _healthCheckHandler;
  final DiscoverRegisterHandler _discoverRegisterHandler;
  late final FileTransferHandler _fileTransferHandler;
  late final ClipboardHandler _clipboardHandler;
  late final WebShareHandler _webShareHandler;
  late final WebShareAssetHandler _webShareAssetHandler;
  late final PairingHandler _pairingHandler;

  // Network connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _networkPollTimer;
  String? _lastKnownIP;
  String? _lastNetworkFingerprint;
  bool _handlingNetworkChange = false;

  /// How often to re-check interfaces while the server is up.
  ///
  /// Needed because switching Wi‑Fi↔Wi‑Fi often keeps [ConnectivityResult.wifi]
  /// and does not fire [Connectivity.onConnectivityChanged].
  static const Duration _networkPollInterval = Duration(seconds: 4);

  HTTPServerManager({
    HealthCheckHandler? healthCheckHandler,
    DiscoverRegisterHandler? discoverRegisterHandler,
    FileTransferHandler? fileTransferHandler,
    ClipboardHandler? clipboardHandler,
    WebShareHandler? webShareHandler,
    WebShareAssetHandler? webShareAssetHandler,
    PairingHandler? pairingHandler,
  }) : _healthCheckHandler = healthCheckHandler ?? HealthCheckHandler(),
       _discoverRegisterHandler =
           discoverRegisterHandler ?? DiscoverRegisterHandler() {
    // Create file transfer handler with a context getter if not provided
    _fileTransferHandler =
        fileTransferHandler ??
        FileTransferHandler(
          contextGetter: () => _context,
          isInBackgroundGetter: () => _isInBackground,
          historyRefreshCallbackGetter: () => _historyRefreshCallback,
        );

    // Create clipboard handler with a context getter if not provided
    _clipboardHandler =
        clipboardHandler ??
        ClipboardHandler(
          contextGetter: () => _context,
          isInBackgroundGetter: () => _isInBackground,
        );

    _webShareHandler = webShareHandler ?? WebShareHandler();
    _webShareAssetHandler = webShareAssetHandler ?? WebShareAssetHandler();

    _pairingHandler =
        pairingHandler ??
        PairingHandler(
          contextGetter: () => _context,
          isInBackgroundGetter: () => _isInBackground,
        );

    // The relay reaches the user through the same dialogs as the LAN, so it
    // needs the same accessors. It is bound here rather than started, because
    // whether it connects at all depends on settings this object knows
    // nothing about.
    RelayService.instance.bindUi(
      contextGetter: () => _context,
      isInBackgroundGetter: () => _isInBackground,
      historyRefreshCallbackGetter: () => _historyRefreshCallback,
    );
  }

  /// Whether the app UI is currently in the background.
  bool get isInBackground => _isInBackground;

  /// Update background state from [WidgetsBindingObserver].
  void setInBackground(bool value) {
    if (_isInBackground == value) return;
    _isInBackground = value;
    LogUtil.iTag(logTag, '应用后台状态: $_isInBackground');
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

  /// Called when the LAN listener starts or stops (not IP-only changes).
  void addServerStatusCallback(VoidCallback callback) {
    if (!_serverStatusCallbacks.contains(callback)) {
      _serverStatusCallbacks.add(callback);
    }
  }

  void removeServerStatusCallback(VoidCallback callback) {
    _serverStatusCallbacks.remove(callback);
  }

  /// Notify all registered callbacks about network change
  void _notifyNetworkChange() {
    for (final callback in _networkChangeCallbacks) {
      callback();
    }
  }

  void _notifyServerStatus() {
    for (final callback in _serverStatusCallbacks) {
      callback();
    }
  }

  /// Start monitoring network connectivity changes
  void startNetworkMonitoring() {
    LogUtil.iTag(logTag, '开始监听网络变化...');

    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        LogUtil.iTag(logTag, '检测到网络变化: $results');
        // Wait a bit for network to stabilize
        await Future.delayed(const Duration(seconds: 1));
        await _evaluateNetworkChange(reason: 'connectivity');
      },
      onError: (error) {
        LogUtil.eTag(logTag, '网络监听出错: $error');
      },
    );

    _networkPollTimer?.cancel();
    _networkPollTimer = Timer.periodic(_networkPollInterval, (_) {
      unawaited(_evaluateNetworkChange(reason: 'poll'));
    });
  }

  /// Stop monitoring network connectivity changes
  void stopNetworkMonitoring() {
    LogUtil.iTag(logTag, '停止监听网络变化');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _networkPollTimer?.cancel();
    _networkPollTimer = null;
  }

  /// Restart when the preferred IP or the live interface set changes.
  Future<void> _evaluateNetworkChange({required String reason}) async {
    if (_handlingNetworkChange) {
      return;
    }
    if (!isRunning()) {
      LogUtil.dTag(logTag, '服务器未运行，跳过网络变化处理 ($reason)');
      return;
    }

    // Lock before awaits so poll + connectivity cannot both restart.
    _handlingNetworkChange = true;
    try {
      final snapshot = await NetworkUtil.captureLocalNetwork(
        logSelection: reason != 'poll',
      );
      if (!isRunning()) {
        return;
      }

      final currentIP = snapshot.preferredIp;
      final fingerprint = snapshot.fingerprint;

      final ipChanged = _lastKnownIP != null && _lastKnownIP != currentIP;
      final interfacesChanged =
          _lastNetworkFingerprint != null &&
          _lastNetworkFingerprint != fingerprint;

      if (!ipChanged && !interfacesChanged) {
        LogUtil.dTag(
          logTag,
          '网络未变化 ($reason): ip=$currentIP',
        );
        _lastKnownIP = currentIP;
        _lastNetworkFingerprint = fingerprint;
        return;
      }

      LogUtil.iTag(
        logTag,
        '网络已变化 ($reason): '
        'ip=$_lastKnownIP->$currentIP, '
        'fingerprint changed=$interfacesChanged',
      );

      await _restartServerOnNetworkChange();
    } finally {
      _handlingNetworkChange = false;
    }
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
        router.post(
          '/discover/register',
          _discoverRegisterHandler.handleRegister,
        );

        // Configure batch confirm receive endpoint (preferred for multiple files)
        router.post(
          '/batch-confirm-receive',
          _fileTransferHandler.handleBatchConfirmReceive,
        );

        // Configure file transfer endpoint
        router.post('/transfer', _fileTransferHandler.handleFileTransfer);

        // Configure clipboard request endpoint
        router.post('/clipboard-request', _clipboardHandler.handleClipboardRequest);

        // Configure device pairing endpoints
        router.post('/pair/request', _pairingHandler.handlePairRequest);
        router.post('/pair/confirm', _pairingHandler.handlePairConfirm);

        // Guest web-share download endpoints (QR / browser receive).
        // Register more specific paths before `/s/<token>`.
        router.get(
          WebShareAssetHandler.logoRoutePath,
          _webShareAssetHandler.handleLogo,
        );
        router.get(
          '/s/<token>/file/<fileId>',
          _webShareHandler.handleFileDownload,
        );
        router.get('/s/<token>/meta', _webShareHandler.handleShareMeta);
        router.get('/s/<token>', _webShareHandler.handleSharePage);

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
        _healthCheckHandler.serverPortGetter = () => _currentPort;

        // Get the local IP address
        final network = await NetworkUtil.captureLocalNetwork(logSelection: true);
        final localIP = network.preferredIp;
        _serverAddress = '$localIP:$tryPort';
        _lastKnownIP = localIP;
        _lastNetworkFingerprint = network.fingerprint;

        LogUtil.iTag(logTag, '✅ 服务器启动成功！');
        LogUtil.iTag(logTag, '监听地址: 0.0.0.0:$tryPort');
        LogUtil.iTag(logTag, '本机IP: $localIP');
        LogUtil.iTag(logTag, '完整地址: $_serverAddress');
        LogUtil.iTag(logTag, separator * 3);

        // Health probe is best-effort and must not block readiness.
        unawaited(_testHealthEndpoint(localIP, tryPort));

        // HTTP bind is enough for inbound transfers and web-share. Discovery,
        // relay, and the Android FGS are useful but not required for the home
        // shell to show "server up" — kick them off without awaiting.
        final generation = ++_lifecycleGeneration;
        unawaited(_startPostBindServices(tryPort, generation));

        _notifyServerStatus();
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

  /// Multicast discovery, optional relay, and Android foreground service.
  /// Skipped if [stopServer] (or a newer bind) has advanced the generation.
  Future<void> _startPostBindServices(int port, int generation) async {
    if (generation != _lifecycleGeneration || _server == null) return;

    await _startMulticastDiscovery(port);
    if (generation != _lifecycleGeneration || _server == null) return;

    // Independent of the LAN server, but started alongside it so there is one
    // window in which the app becomes reachable by any route.
    await RelayService.instance.start();
    if (generation != _lifecycleGeneration || _server == null) return;

    if (Platform.isAndroid) {
      await AndroidForegroundService.start();
    }
  }

  /// Test health endpoint after server starts
  Future<void> _testHealthEndpoint(String ip, int port) async {
    try {
      LogUtil.dTag(logTag, '测试健康检查端点...');
      final testUrl = NetworkUtil.buildHttpUrl(ip, '/health', targetPort: port);
      LogUtil.dTag(logTag, '测试URL: $testUrl');

      // Wait a bit for server to be fully ready
      await Future.delayed(const Duration(milliseconds: 500));

      final client = HttpClient();
      try {
        final request = await client
            .getUrl(Uri.parse(testUrl))
            .timeout(const Duration(seconds: 3));
        final response = await request.close();

        if (response.statusCode == 200) {
          LogUtil.iTag(logTag, '✅ 健康检查端点测试成功！');
        } else {
          LogUtil.wTag(logTag, '健康检查端点返回状态码: ${response.statusCode}');
        }

        // Drained so the connection can be released rather than sitting on an
        // unread body until the client is torn down.
        await response.drain<void>();
      } finally {
        client.close(force: true);
      }
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '健康检查端点测试失败: $e (这可能表示存在网络配置问题)', e, stackTrace);
    }
  }

  /// Stop the HTTP server
  Future<void> stopServer() async {
    _lifecycleGeneration++;
    await _stopMulticastDiscovery();
    await RelayService.instance.stop();
    _pairingHandler.dispose();

    if (Platform.isAndroid) {
      await AndroidForegroundService.stop();
    }

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
      _notifyServerStatus();
    } else {
      LogUtil.dTag(logTag, '服务器未运行，无需停止');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    stopNetworkMonitoring();
    WebShareService.instance.clearAll();
    await stopServer();
  }

  /// Get the current port number
  int? getCurrentPort() {
    return _currentPort;
  }

  /// Get the file transfer handler for registering progress callbacks
  FileTransferHandler getFileTransferHandler() {
    return _fileTransferHandler;
  }

  /// Prefers the public-key fingerprint so peers can recognise an already
  /// paired device straight from an announcement.
  Future<String> _resolveAnnouncedDeviceId(PreferencesService prefs) async {
    try {
      return await IdentityService.instance.getDeviceId();
    } catch (e) {
      LogUtil.wTag(logTag, '设备身份不可用，组播回退到本地随机 ID: $e');
      return prefs.getOrCreateDeviceId();
    }
  }

  Future<void> _startMulticastDiscovery(int port) async {
    try {
      final prefs = PreferencesService();
      final deviceId = await _resolveAnnouncedDeviceId(prefs);
      final customName = await prefs.getDeviceName();
      final deviceName = customName ?? await NetworkUtil.getDeviceName();
      final localIps = await NetworkUtil.getLocalPrivateIPs();

      final multicast = MulticastDiscoveryService.instance;
      await multicast.stopListener();
      await multicast.configure(
        deviceId: deviceId,
        deviceName: deviceName,
        serverPort: port,
        localIps: localIps,
        serverRunning: true,
      );
      await multicast.startListener();
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '组播发现服务启动失败: $e', e, stackTrace);
    }
  }

  Future<void> _stopMulticastDiscovery() async {
    try {
      await MulticastDiscoveryService.instance.stopListener();
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '组播发现服务停止失败: $e', e, stackTrace);
    }
  }
}
