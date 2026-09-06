import '../../../services/preferences_service.dart';
import '../../../utils/constants.dart';

/// Loads and saves connection-related preferences (IP, port, secret, history).
class ConnectionPrefsController {
  final PreferencesService _preferencesService;

  ConnectionPrefsController({PreferencesService? preferencesService})
    : _preferencesService = preferencesService ?? PreferencesService();

  Future<String?> loadLastUsedIP() {
    return _preferencesService.getLastUsedIP();
  }

  Future<int> loadLastUsedPort() {
    return _preferencesService.getLastUsedPort();
  }

  Future<String?> loadLastUsedTargetSecretKey() {
    return _preferencesService.getTargetDeviceSecretKey();
  }

  Future<void> saveTargetSecretKey(String secretKey) async {
    final trimmed = secretKey.trim();
    if (trimmed.isNotEmpty) {
      await _preferencesService.saveTargetDeviceSecretKey(trimmed);
    }
  }

  Future<void> clearTargetSecretKey() {
    return _preferencesService.clearTargetDeviceSecretKey();
  }

  Future<List<String>> loadIPHistory() {
    return _preferencesService.getIPHistory();
  }

  Future<bool> loadIPValidationEnabled() {
    return _preferencesService.getIPValidationEnabled();
  }

  Future<void> savePort(String portText) async {
    final port = int.tryParse(portText.trim());
    if (port != null && port >= 1 && port <= 65535) {
      await _preferencesService.saveLastUsedPort(port);
    }
  }

  Future<bool> deleteIPFromHistory(String ip) {
    return _preferencesService.removeIPFromHistory(ip);
  }

  String get defaultPortText => '${AppConstants.defaultPort}';
}
