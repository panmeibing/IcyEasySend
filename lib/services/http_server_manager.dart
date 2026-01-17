import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:flutter/material.dart';
import 'health_check_handler.dart';
import 'file_transfer_handler.dart';
import '../utils/error_messages.dart';

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
  
  // API handlers
  final HealthCheckHandler _healthCheckHandler = HealthCheckHandler();
  late final FileTransferHandler _fileTransferHandler;
  
  HTTPServerManager() {
    // Create file transfer handler with a context getter
    _fileTransferHandler = FileTransferHandler(
      contextGetter: () => _context,
    );
  }
  
  /// Set the BuildContext for showing dialogs
  void setContext(BuildContext context) {
    _context = context;
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
  /// in the range 8080-8090
  Future<ServerStartResult> startServer({int port = 8080}) async {
    // If server is already running, return success
    if (isRunning()) {
      return ServerStartResult(
        success: true,
        serverAddress: _serverAddress,
      );
    }

    // Try to start server on the specified port or find an available port
    for (int tryPort = port; tryPort <= 8090; tryPort++) {
      try {
        // Create router and configure routes
        final router = shelf_router.Router();
        
        // Configure health check endpoint
        router.get('/health', _healthCheckHandler.handleHealthCheck);
        
        // Configure confirm receive endpoint (called before file transfer)
        router.get('/confirm-receive', _fileTransferHandler.handleConfirmReceive);
        
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
        final localIP = await _getLocalIPAddress();
        _serverAddress = '$localIP:$tryPort';

        return ServerStartResult(
          success: true,
          serverAddress: _serverAddress,
        );
      } on SocketException {
        // Port is in use or other socket error, try next port
        if (tryPort == 8090) {
          // Last port in range, return error
          return ServerStartResult(
            success: false,
            errorMessage: ErrorMessages.serverPortsOccupied,
          );
        }
        // Continue to next port
        continue;
      } catch (e) {
        // Other errors
        return ServerStartResult(
          success: false,
          errorMessage: ErrorMessages.serverStartFailed(e.toString()),
        );
      }
    }

    // Should not reach here, but just in case
    return ServerStartResult(
      success: false,
      errorMessage: ErrorMessages.serverUnknownError,
    );
  }

  /// Stop the HTTP server
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _serverAddress = null;
      _currentPort = null;
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

  /// Get the current port number
  int? getCurrentPort() {
    return _currentPort;
  }
}
