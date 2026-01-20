import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
  Future<Response> handleHealthCheck(Request request) async {
    final deviceName = await _getDeviceName();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final response = {
      'status': 'ok',
      'timestamp': timestamp,
      'deviceName': deviceName,
    };

    return Response.ok(
      jsonEncode(response),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Get the device name
  ///
  /// Returns the device model name using device_info_plus package.
  /// Falls back to Platform.localHostname if device info is unavailable.
  Future<String> _getDeviceName() async {
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
        return 'Unknown Device';
      }
    } catch (e) {
      // If device_info_plus fails, try hostname
      try {
        return Platform.localHostname;
      } catch (e) {
        return 'Unknown Device';
      }
    }
  }
}
