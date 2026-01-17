import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';

/// Handler for health check endpoint
/// 
/// Provides a RESTful endpoint to check if the device is online and ready
/// to receive files.
class HealthCheckHandler {
  /// Handle GET /health requests
  /// 
  /// Returns a JSON response with:
  /// - status: "ok" indicating the device is healthy
  /// - timestamp: current timestamp in milliseconds
  /// - deviceName: name of the device
  Response handleHealthCheck(Request request) {
    final deviceName = _getDeviceName();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    final response = {
      'status': 'ok',
      'timestamp': timestamp,
      'deviceName': deviceName,
    };
    
    return Response.ok(
      jsonEncode(response),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }
  
  /// Get the device name
  /// 
  /// Returns the hostname of the device or a default name
  String _getDeviceName() {
    try {
      return Platform.localHostname;
    } catch (e) {
      return 'Unknown Device';
    }
  }
}
