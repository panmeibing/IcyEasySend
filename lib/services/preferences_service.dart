import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/relay_blocked_peer.dart';
import '../models/relay_config.dart';
import '../utils/constants.dart';

/// Service for managing app preferences and settings
///
/// Provides functionality to:
/// - Save and retrieve last used IP address
/// - Manage user preferences
class PreferencesService {
  // Keys for SharedPreferences
  static const String _keyLastUsedIP = 'last_used_ip';
  static const String _keyLastUsedPort = 'last_used_port';
  static const String _keyIPHistory = 'ip_history';
  static const String _keyDeviceName = 'device_name';
  static const String _keyDeviceId = 'device_id';
  static const String _keyConcurrentTransfers = 'concurrent_transfers';
  static const String _keyMaxHistoryItems = 'max_history_items';
  static const String _keyMaxClipboardSize = 'max_clipboard_size';
  static const String _keyEnableIPValidation = 'enable_ip_validation';
  static const String _keyDeviceSecretKey = 'device_secret_key';
  static const String _keyTargetDeviceSecretKey = 'target_device_secret_key';
  static const String _keyCustomReceiveSavePath = 'custom_receive_save_path';
  static const String _keyClipboardOverlayEnabled = 'clipboard_overlay_enabled';
  static const String _keyRelayConfig = 'relay_config';
  static const String _keyRelayPairingEnabled = 'relay_pairing_enabled';
  static const String _keyRelayPairBlocklist = 'relay_pair_blocklist';

  /// Upper bound on remembered blocks.
  static const int _maxRelayPairBlocklist = 200;

  /// Legacy cooldown entries: `deviceId:expiryEpochMs`.
  static final RegExp _legacyBlocklistExpiryPattern =
      RegExp(r'^([0-9a-f]{32}):(\d+)$');

  /// Legacy plain device ids.
  static final RegExp _legacyBlocklistIdPattern = RegExp(r'^[0-9a-f]{32}$');

  // Maximum number of IP addresses to keep in history
  static const int _maxIpHistorySize = 10;
  final int _allowMinHisCount = AppConstants.allowMinHistoryItems;
  final int _allowMaxHisCount = AppConstants.allowMaxHistoryItems;
  final int _maxConcurrentTransfers = AppConstants.maxConcurrentTransfers;

  // Default concurrent transfer count
  static const int _defaultConcurrentTransfers =
      AppConstants.defaultConcurrentTransfers;

  // Default max history items
  static const int _defaultMaxHistoryItems =
      AppConstants.defaultMaxHistoryItems;

  // Default max clipboard size
  static const int _defaultMaxClipboardSize =
      AppConstants.defaultMaxClipboardSize;

  /// Save the last used IP address
  ///
  /// Parameters:
  /// - [ipAddress]: The IP address to save
  Future<bool> saveLastUsedIP(String ipAddress) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save as last used IP
      await prefs.setString(_keyLastUsedIP, ipAddress);

      // Add to history
      await _addToHistory(ipAddress);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the last used IP address
  ///
  /// Returns the last used IP address, or null if none exists
  Future<String?> getLastUsedIP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastUsedIP);
    } catch (e) {
      return null;
    }
  }

  /// Save the last used port
  ///
  /// Parameters:
  /// - [port]: The port number to save (1-65535)
  Future<bool> saveLastUsedPort(int port) async {
    try {
      if (port < 1 || port > 65535) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastUsedPort, port);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the last used port
  ///
  /// Returns the last used port, or default port if none exists
  Future<int> getLastUsedPort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyLastUsedPort) ?? AppConstants.defaultPort;
    } catch (e) {
      return AppConstants.defaultPort;
    }
  }

  /// Add an IP address to history
  ///
  /// Maintains a list of recently used IP addresses
  Future<void> _addToHistory(String ipAddress) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current history
      List<String> history = prefs.getStringList(_keyIPHistory) ?? [];

      // Remove if already exists (to move it to front)
      history.remove(ipAddress);

      // Add to front
      history.insert(0, ipAddress);

      // Limit size
      if (history.length > _maxIpHistorySize) {
        history = history.sublist(0, _maxIpHistorySize);
      }

      // Save back
      await prefs.setStringList(_keyIPHistory, history);
    } catch (e) {
      // Ignore errors in history management
    }
  }

  /// Get IP address history
  ///
  /// Returns a list of recently used IP addresses
  Future<List<String>> getIPHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_keyIPHistory) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Clear the last used IP address
  Future<bool> clearLastUsedIP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastUsedIP);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a specific IP address from history
  ///
  /// Parameters:
  /// - [ipAddress]: The IP address to remove
  Future<bool> removeIPFromHistory(String ipAddress) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current history
      List<String> history = prefs.getStringList(_keyIPHistory) ?? [];

      // Remove the IP address
      history.remove(ipAddress);

      // Save back
      await prefs.setStringList(_keyIPHistory, history);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear IP address history
  Future<bool> clearIPHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIPHistory);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all preferences
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save device name
  ///
  /// Parameters:
  /// - [deviceName]: The device name to save
  Future<bool> saveDeviceName(String deviceName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDeviceName, deviceName);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get device name
  ///
  /// Returns the saved device name, or null if none exists
  Future<String?> getDeviceName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDeviceName);
    } catch (e) {
      return null;
    }
  }

  /// Persistent ID used to filter this device from multicast discovery results.
  ///
  /// Superseded by [IdentityService.getDeviceId], which derives the id from
  /// the Ed25519 public key so it cannot be forged. This remains as the
  /// fallback for the case where the identity key cannot be loaded, since
  /// discovery must keep working even then.
  Future<String> getOrCreateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_keyDeviceId);
      if (existing != null && existing.isNotEmpty) {
        return existing;
      }

      final id =
          '${DateTime.now().microsecondsSinceEpoch}-'
          '${DateTime.now().millisecondsSinceEpoch.hashCode.abs()}';
      await prefs.setString(_keyDeviceId, id);
      return id;
    } catch (_) {
      return '${DateTime.now().microsecondsSinceEpoch}';
    }
  }

  /// Save concurrent transfer count
  ///
  /// Parameters:
  /// - [count]: Number of concurrent transfers (1-10)
  Future<bool> saveConcurrentTransfers(int count) async {
    try {
      // Validate count range
      if (count < 1 || count > _maxConcurrentTransfers) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyConcurrentTransfers, count);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get concurrent transfer count
  ///
  /// Returns the saved concurrent transfer count, or default value (5) if none exists
  Future<int> getConcurrentTransfers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyConcurrentTransfers) ??
          _defaultConcurrentTransfers;
    } catch (e) {
      return _defaultConcurrentTransfers;
    }
  }

  /// Save max history items count
  ///
  /// Parameters:
  /// - [count]: Maximum number of history items to keep
  Future<bool> saveMaxHistoryItems(int count) async {
    try {
      // Validate count (minimum 10, maximum 1000)
      if (count < _allowMinHisCount || count > _allowMaxHisCount) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyMaxHistoryItems, count);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get max history items count
  ///
  /// Returns the saved max history items count, or default value if none exists
  Future<int> getMaxHistoryItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyMaxHistoryItems) ?? _defaultMaxHistoryItems;
    } catch (e) {
      return _defaultMaxHistoryItems;
    }
  }

  /// Save max clipboard size (in MB)
  ///
  /// Parameters:
  /// - [sizeMB]: Maximum clipboard size in MB (1-100)
  Future<bool> saveMaxClipboardSize(int sizeMB) async {
    try {
      // Validate size (minimum 1MB, maximum 100MB)
      if (sizeMB < AppConstants.minClipboardSizeMB ||
          sizeMB > AppConstants.maxClipboardSizeMB) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyMaxClipboardSize, sizeMB);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get max clipboard size (in MB)
  ///
  /// Returns the saved max clipboard size, or default value if none exists
  Future<int> getMaxClipboardSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyMaxClipboardSize) ?? _defaultMaxClipboardSize;
    } catch (e) {
      return _defaultMaxClipboardSize;
    }
  }

  /// Save IP validation enabled state
  ///
  /// Parameters:
  /// - [enabled]: Whether IP validation is enabled
  Future<bool> saveIPValidationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEnableIPValidation, enabled);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get IP validation enabled state
  ///
  /// Returns whether IP validation is enabled, defaults to true
  Future<bool> getIPValidationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Default to true (enabled) for backward compatibility
      return prefs.getBool(_keyEnableIPValidation) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Save device secret key
  ///
  /// Parameters:
  /// - [secretKey]: The secret key to save
  Future<bool> saveDeviceSecretKey(String secretKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDeviceSecretKey, secretKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get device secret key
  ///
  /// Returns the saved secret key, or null if none exists
  Future<String?> getDeviceSecretKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDeviceSecretKey);
    } catch (e) {
      return null;
    }
  }

  /// Save target device secret key
  ///
  /// Parameters:
  /// - [secretKey]: The target device secret key to save
  Future<bool> saveTargetDeviceSecretKey(String secretKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTargetDeviceSecretKey, secretKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get target device secret key
  ///
  /// Returns the saved target device secret key, or null if none exists
  Future<String?> getTargetDeviceSecretKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyTargetDeviceSecretKey);
    } catch (e) {
      return null;
    }
  }

  /// Save custom directory for received files
  Future<bool> saveCustomReceiveSavePath(String directoryPath) async {
    try {
      final trimmed = directoryPath.trim();
      if (trimmed.isEmpty) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCustomReceiveSavePath, trimmed);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get custom receive save path, or null if using system downloads folder
  Future<String?> getCustomReceiveSavePath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_keyCustomReceiveSavePath);
      if (path == null || path.trim().isEmpty) {
        return null;
      }
      return path.trim();
    } catch (e) {
      return null;
    }
  }

  /// Clear custom receive save path (revert to system downloads folder)
  Future<bool> clearCustomReceiveSavePath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCustomReceiveSavePath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear target device secret key
  ///
  /// Returns true if successful, false otherwise
  Future<bool> clearTargetDeviceSecretKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyTargetDeviceSecretKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Whether the Android clipboard floating overlay is enabled (default: false).
  Future<bool> getClipboardOverlayEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyClipboardOverlayEnabled) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Persist clipboard floating overlay preference.
  Future<bool> saveClipboardOverlayEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyClipboardOverlayEnabled, enabled);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Relay server settings, or [RelayConfig.empty] when none are stored.
  ///
  /// Stored as one JSON object rather than separate keys so that supporting
  /// more than one relay later does not require migrating existing users.
  Future<RelayConfig> getRelayConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyRelayConfig);
      if (raw == null || raw.isEmpty) {
        return RelayConfig.empty;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return RelayConfig.empty;
      }
      return RelayConfig.fromJson(decoded);
    } catch (e) {
      return RelayConfig.empty;
    }
  }

  Future<bool> saveRelayConfig(RelayConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRelayConfig, jsonEncode(config.toJson()));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearRelayConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRelayConfig);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Whether this device shows a dialog for pairing requests arriving over the
  /// relay. On by default: without it the only way to pair is to be on the
  /// same network, which is the thing the relay exists to avoid.
  Future<bool> getRelayPairingEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRelayPairingEnabled) ?? true;
    } catch (e) {
      return true;
    }
  }

  Future<bool> saveRelayPairingEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRelayPairingEnabled, enabled);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Peers this device has explicitly blocked from relay pairing.
  ///
  /// Only an intentional "block" action writes here — a normal reject does not.
  Future<List<RelayBlockedPeer>> getRelayPairBlocklistEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_keyRelayPairBlocklist) ?? const <String>[];
      final byId = <String, RelayBlockedPeer>{};
      var changed = false;

      for (final entry in raw) {
        // Current format: one JSON object per list item.
        if (entry.startsWith('{')) {
          try {
            final parsed = RelayBlockedPeer.tryParse(jsonDecode(entry));
            if (parsed != null) {
              byId[parsed.deviceId] = parsed;
              continue;
            }
          } catch (_) {}
          changed = true;
          continue;
        }

        // Migrate legacy permanent id or cooldown `id:expiry` → permanent entry.
        final expiryMatch = _legacyBlocklistExpiryPattern.firstMatch(entry);
        if (expiryMatch != null) {
          final id = expiryMatch.group(1)!;
          byId.putIfAbsent(
            id,
            () => RelayBlockedPeer(
              deviceId: id,
              deviceName: '',
              blockedAt: DateTime.now(),
            ),
          );
          changed = true;
          continue;
        }
        if (_legacyBlocklistIdPattern.hasMatch(entry)) {
          byId.putIfAbsent(
            entry,
            () => RelayBlockedPeer(
              deviceId: entry,
              deviceName: '',
              blockedAt: DateTime.now(),
            ),
          );
          changed = true;
          continue;
        }
        changed = true;
      }

      final list = byId.values.toList()
        ..sort((a, b) => b.blockedAt.compareTo(a.blockedAt));
      if (changed) {
        await _persistBlocklist(prefs, list);
      }
      return list;
    } catch (e) {
      return const <RelayBlockedPeer>[];
    }
  }

  /// Device ids currently on the relay pairing blocklist.
  Future<Set<String>> getRelayPairBlocklist() async {
    return {
      for (final peer in await getRelayPairBlocklistEntries()) peer.deviceId,
    };
  }

  Future<bool> isRelayPairingBlocked(String deviceId) async {
    if (deviceId.isEmpty) {
      return false;
    }
    return (await getRelayPairBlocklist()).contains(deviceId);
  }

  Future<bool> blockRelayPairing(
    String deviceId, {
    String deviceName = '',
  }) async {
    if (deviceId.isEmpty) {
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = await getRelayPairBlocklistEntries();
      final existing = [
        for (final peer in entries)
          if (peer.deviceId != deviceId) peer,
      ];
      existing.insert(
        0,
        RelayBlockedPeer(
          deviceId: deviceId,
          deviceName: deviceName,
          blockedAt: DateTime.now(),
        ),
      );
      final trimmed = existing.length > _maxRelayPairBlocklist
          ? existing.sublist(0, _maxRelayPairBlocklist)
          : existing;
      await _persistBlocklist(prefs, trimmed);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unblockRelayPairing(String deviceId) async {
    if (deviceId.isEmpty) {
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = await getRelayPairBlocklistEntries();
      final next = [
        for (final peer in entries)
          if (peer.deviceId != deviceId) peer,
      ];
      if (next.length == entries.length) {
        return true;
      }
      await _persistBlocklist(prefs, next);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearRelayPairBlocklist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRelayPairBlocklist);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _persistBlocklist(
    SharedPreferences prefs,
    List<RelayBlockedPeer> entries,
  ) {
    return prefs.setStringList(
      _keyRelayPairBlocklist,
      [for (final peer in entries) jsonEncode(peer.toJson())],
    );
  }
}
