import '../../../services/preferences_service.dart';
import '../../../utils/network_util.dart';

/// Controller for device information
class DeviceController {
  final PreferencesService _preferencesService;

  DeviceController(this._preferencesService);

  /// Load device information
  Future<Map<String, String>> loadDeviceInfo() async {
    try {
      final model = await NetworkUtil.getDeviceName();
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
