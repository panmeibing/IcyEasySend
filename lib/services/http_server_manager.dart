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

  /// Get the current port number
  int? getCurrentPort() {
    return _currentPort;
  }
}
