import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../../../services/preferences_service.dart';

/// Controller for device information
class DeviceController {
  final PreferencesService _preferencesService;

  DeviceController(this._preferencesService);

  /// Load device information
  Future<Map<String, String>> loadDeviceInfo() async {
    try {
      // Get device model
      final deviceInfo = DeviceInfoPlugin();
      String model = 'Unknown Device';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        model = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        model = iosInfo.model;
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        model = macInfo.model;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        model = windowsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        model = linuxInfo.name;
      }

      // Load saved device name or use model as default
      final savedName = await _preferencesService.getDeviceName();
      final deviceName = savedName ?? model;

      return {'model': model, 'name': deviceName};
    } catch (e) {
      return {'model': 'Unknown Device', 'name': 'Unknown Device'};
    }
  }

  /// Save device name
  Future<bool> saveDeviceName(String name) async {
    if (name.trim().isEmpty) {
      return false;
    }
    return await _preferencesService.saveDeviceName(name.trim());
  }
}
