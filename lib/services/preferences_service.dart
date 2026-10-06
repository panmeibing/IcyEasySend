import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/relay_blocked_peer.dart';
import '../models/relay_config.dart';
import '../utils/constants.dart';
import '../utils/network_util.dart';

/// App settings stored in [SharedPreferences].
///
/// Reads never throw: a storage failure yields the setting's default. Writes
/// report success as a bool and reject out-of-range values without storing
/// them.
class PreferencesService {
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

  static const int _maxIpHistorySize = 10;

  /// Upper bound on remembered blocks.
  static const int _maxRelayPairBlocklist = 200;

  /// Legacy cooldown entries: `deviceId:expiryEpochMs`.
  static final RegExp _legacyBlocklistExpiryPattern = RegExp(
    r'^([0-9a-f]{32}):(\d+)$',
  );

  /// Legacy plain device ids.
  static final RegExp _legacyBlocklistIdPattern = RegExp(r'^[0-9a-f]{32}$');

  Future<T> _read<T>(
    T Function(SharedPreferences prefs) read,
    T fallback,
  ) async {
    try {
      return read(await SharedPreferences.getInstance());
    } catch (_) {
      return fallback;
    }
  }

  Future<bool> _write(
    Future<void> Function(SharedPreferences prefs) write,
  ) async {
    try {
      await write(await SharedPreferences.getInstance());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _setString(String key, String value) =>
      _write((prefs) => prefs.setString(key, value));

  Future<bool> _setInt(String key, int value) =>
      _write((prefs) => prefs.setInt(key, value));

  Future<bool> _setBool(String key, bool value) =>
      _write((prefs) => prefs.setBool(key, value));

  Future<bool> _remove(String key) => _write((prefs) => prefs.remove(key));

  Future<bool> _setIntInRange(String key, int value, int min, int max) async {
    if (value < min || value > max) return false;
    return _setInt(key, value);
  }

  // Connection target

  /// Remembers [ipAddress] as the last target and moves it to the front of
  /// the history.
  Future<bool> saveLastUsedIP(String ipAddress) => _write((prefs) async {
    await prefs.setString(_keyLastUsedIP, ipAddress);
    final history = prefs.getStringList(_keyIPHistory) ?? <String>[];
    history
      ..remove(ipAddress)
      ..insert(0, ipAddress);
    await prefs.setStringList(
      _keyIPHistory,
      history.take(_maxIpHistorySize).toList(),
    );
  });

  Future<String?> getLastUsedIP() =>
      _read((prefs) => prefs.getString(_keyLastUsedIP), null);

  Future<bool> saveLastUsedPort(int port) async {
    if (!NetworkUtil.isValidPort(port)) return false;
    return _setInt(_keyLastUsedPort, port);
  }

  Future<int> getLastUsedPort() => _read(
    (prefs) => prefs.getInt(_keyLastUsedPort) ?? AppConstants.defaultPort,
    AppConstants.defaultPort,
  );

  /// Recently used IP addresses, most recent first.
  Future<List<String>> getIPHistory() =>
      _read((prefs) => prefs.getStringList(_keyIPHistory) ?? [], []);

  Future<bool> removeIPFromHistory(String ipAddress) => _write((prefs) {
    final history = prefs.getStringList(_keyIPHistory) ?? <String>[];
    history.remove(ipAddress);
    return prefs.setStringList(_keyIPHistory, history);
  });

  /// Whether a typed target IP is checked against the local subnet. On by
  /// default.
  Future<bool> saveIPValidationEnabled(bool enabled) =>
      _setBool(_keyEnableIPValidation, enabled);

  Future<bool> getIPValidationEnabled() =>
      _read((prefs) => prefs.getBool(_keyEnableIPValidation) ?? true, true);

  Future<bool> saveTargetDeviceSecretKey(String secretKey) =>
      _setString(_keyTargetDeviceSecretKey, secretKey);

  Future<String?> getTargetDeviceSecretKey() =>
      _read((prefs) => prefs.getString(_keyTargetDeviceSecretKey), null);

  Future<bool> clearTargetDeviceSecretKey() =>
      _remove(_keyTargetDeviceSecretKey);

  // This device

  Future<bool> saveDeviceName(String deviceName) =>
      _setString(_keyDeviceName, deviceName);

  Future<String?> getDeviceName() =>
      _read((prefs) => prefs.getString(_keyDeviceName), null);

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

  Future<bool> saveDeviceSecretKey(String secretKey) =>
      _setString(_keyDeviceSecretKey, secretKey);

  Future<String?> getDeviceSecretKey() =>
      _read((prefs) => prefs.getString(_keyDeviceSecretKey), null);

  // Transfer and history limits

  Future<bool> saveConcurrentTransfers(int count) => _setIntInRange(
    _keyConcurrentTransfers,
    count,
    1,
    AppConstants.maxConcurrentTransfers,
  );

  Future<int> getConcurrentTransfers() => _read(
    (prefs) =>
        prefs.getInt(_keyConcurrentTransfers) ??
        AppConstants.defaultConcurrentTransfers,
    AppConstants.defaultConcurrentTransfers,
  );

  Future<bool> saveMaxHistoryItems(int count) => _setIntInRange(
    _keyMaxHistoryItems,
    count,
    AppConstants.allowMinHistoryItems,
    AppConstants.allowMaxHistoryItems,
  );

  Future<int> getMaxHistoryItems() => _read(
    (prefs) =>
        prefs.getInt(_keyMaxHistoryItems) ??
        AppConstants.defaultMaxHistoryItems,
    AppConstants.defaultMaxHistoryItems,
  );

  /// Largest clipboard payload accepted, in MB.
  Future<bool> saveMaxClipboardSize(int sizeMB) => _setIntInRange(
    _keyMaxClipboardSize,
    sizeMB,
    AppConstants.minClipboardSizeMB,
    AppConstants.maxClipboardSizeMB,
  );

  Future<int> getMaxClipboardSize() => _read(
    (prefs) =>
        prefs.getInt(_keyMaxClipboardSize) ??
        AppConstants.defaultMaxClipboardSize,
    AppConstants.defaultMaxClipboardSize,
  );

  // Receiving

  Future<bool> saveCustomReceiveSavePath(String directoryPath) async {
    final trimmed = directoryPath.trim();
    if (trimmed.isEmpty) return false;
    return _setString(_keyCustomReceiveSavePath, trimmed);
  }

  /// Custom directory for received files, or null for the system downloads
  /// folder.
  Future<String?> getCustomReceiveSavePath() => _read((prefs) {
    final path = prefs.getString(_keyCustomReceiveSavePath)?.trim();
    return path == null || path.isEmpty ? null : path;
  }, null);

  Future<bool> clearCustomReceiveSavePath() =>
      _remove(_keyCustomReceiveSavePath);

  /// Whether the Android clipboard floating overlay is enabled (default: off).
  Future<bool> getClipboardOverlayEnabled() => _read(
    (prefs) => prefs.getBool(_keyClipboardOverlayEnabled) ?? false,
    false,
  );

  Future<bool> saveClipboardOverlayEnabled(bool enabled) =>
      _setBool(_keyClipboardOverlayEnabled, enabled);

  // Relay

  /// Relay server settings, or [RelayConfig.empty] when none are stored.
  ///
  /// Stored as one JSON object rather than separate keys so that supporting
  /// more than one relay later does not require migrating existing users.
  Future<RelayConfig> getRelayConfig() => _read((prefs) {
    final raw = prefs.getString(_keyRelayConfig);
    if (raw == null || raw.isEmpty) return RelayConfig.empty;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic>
        ? RelayConfig.fromJson(decoded)
        : RelayConfig.empty;
  }, RelayConfig.empty);

  Future<bool> saveRelayConfig(RelayConfig config) =>
      _setString(_keyRelayConfig, jsonEncode(config.toJson()));

  /// Whether this device shows a dialog for pairing requests arriving over the
  /// relay. On by default: without it the only way to pair is to be on the
  /// same network, which is the thing the relay exists to avoid.
  Future<bool> getRelayPairingEnabled() =>
      _read((prefs) => prefs.getBool(_keyRelayPairingEnabled) ?? true, true);

  Future<bool> saveRelayPairingEnabled(bool enabled) =>
      _setBool(_keyRelayPairingEnabled, enabled);

  /// Peers this device has explicitly blocked from relay pairing, most
  /// recently blocked first.
  ///
  /// Only an intentional "block" action writes here — a normal reject does not.
  Future<List<RelayBlockedPeer>> getRelayPairBlocklistEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw =
          prefs.getStringList(_keyRelayPairBlocklist) ?? const <String>[];
      final byId = <String, RelayBlockedPeer>{};
      var changed = false;

      for (final entry in raw) {
        final parsed = _parseBlocklistEntry(entry);
        if (parsed == null) {
          changed = true;
          continue;
        }
        if (parsed.migrated) {
          changed = true;
          byId.putIfAbsent(parsed.peer.deviceId, () => parsed.peer);
        } else {
          byId[parsed.peer.deviceId] = parsed.peer;
        }
      }

      final list = byId.values.toList()
        ..sort((a, b) => b.blockedAt.compareTo(a.blockedAt));
      if (changed) {
        await _persistBlocklist(prefs, list);
      }
      return list;
    } catch (_) {
      return const <RelayBlockedPeer>[];
    }
  }

  /// One stored blocklist item. Legacy permanent ids and `id:expiry`
  /// cooldowns become permanent blocks and are flagged for rewriting.
  ({RelayBlockedPeer peer, bool migrated})? _parseBlocklistEntry(String entry) {
    if (entry.startsWith('{')) {
      try {
        final peer = RelayBlockedPeer.tryParse(jsonDecode(entry));
        return peer == null ? null : (peer: peer, migrated: false);
      } catch (_) {
        return null;
      }
    }

    final legacyId =
        _legacyBlocklistExpiryPattern.firstMatch(entry)?.group(1) ??
        (_legacyBlocklistIdPattern.hasMatch(entry) ? entry : null);
    if (legacyId == null) return null;
    return (
      peer: RelayBlockedPeer(
        deviceId: legacyId,
        deviceName: '',
        blockedAt: DateTime.now(),
      ),
      migrated: true,
    );
  }

  /// Device ids currently on the relay pairing blocklist.
  Future<Set<String>> getRelayPairBlocklist() async {
    return {
      for (final peer in await getRelayPairBlocklistEntries()) peer.deviceId,
    };
  }

  Future<bool> isRelayPairingBlocked(String deviceId) async {
    if (deviceId.isEmpty) return false;
    return (await getRelayPairBlocklist()).contains(deviceId);
  }

  Future<bool> blockRelayPairing(
    String deviceId, {
    String deviceName = '',
  }) async {
    if (deviceId.isEmpty) return false;
    final entries = await getRelayPairBlocklistEntries();
    final next = [
      RelayBlockedPeer(
        deviceId: deviceId,
        deviceName: deviceName,
        blockedAt: DateTime.now(),
      ),
      for (final peer in entries)
        if (peer.deviceId != deviceId) peer,
    ];
    return _write(
      (prefs) =>
          _persistBlocklist(prefs, next.take(_maxRelayPairBlocklist).toList()),
    );
  }

  Future<bool> unblockRelayPairing(String deviceId) async {
    if (deviceId.isEmpty) return false;
    final entries = await getRelayPairBlocklistEntries();
    final next = [
      for (final peer in entries)
        if (peer.deviceId != deviceId) peer,
    ];
    if (next.length == entries.length) return true;
    return _write((prefs) => _persistBlocklist(prefs, next));
  }

  Future<void> _persistBlocklist(
    SharedPreferences prefs,
    List<RelayBlockedPeer> entries,
  ) {
    return prefs.setStringList(_keyRelayPairBlocklist, [
      for (final peer in entries) jsonEncode(peer.toJson()),
    ]);
  }
}
