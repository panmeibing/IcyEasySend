import '../../../services/preferences_service.dart';

/// Snapshot of connection fields needed to paint Home without N round-trips.
class HomeConnectionPrefs {
  final String? lastUsedIP;
  final int lastUsedPort;
  final String? targetSecretKey;
  final List<String> ipHistory;
  final bool enableIPValidation;

  const HomeConnectionPrefs({
    required this.lastUsedIP,
    required this.lastUsedPort,
    required this.targetSecretKey,
    required this.ipHistory,
    required this.enableIPValidation,
  });
}

/// Loads and saves connection-related preferences (IP, port, secret, history).
class ConnectionPrefsController {
  final PreferencesService _preferencesService;

  ConnectionPrefsController({PreferencesService? preferencesService})
    : _preferencesService = preferencesService ?? PreferencesService();

  /// One SharedPreferences warm-up + parallel reads for Home cold start.
  Future<HomeConnectionPrefs> loadHomeConnectionPrefs() async {
    final results = await Future.wait<Object?>([
      _preferencesService.getLastUsedIP(),
      _preferencesService.getLastUsedPort(),
      _preferencesService.getTargetDeviceSecretKey(),
      _preferencesService.getIPHistory(),
      _preferencesService.getIPValidationEnabled(),
    ]);

    return HomeConnectionPrefs(
      lastUsedIP: results[0] as String?,
      lastUsedPort: results[1] as int,
      targetSecretKey: results[2] as String?,
      ipHistory: results[3] as List<String>,
      enableIPValidation: results[4] as bool,
    );
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
}
