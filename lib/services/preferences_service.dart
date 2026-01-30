import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _keyConcurrentTransfers = 'concurrent_transfers';

  // Maximum number of IP addresses to keep in history
  static const int _maxHistorySize = 10;

  // Default concurrent transfer count
  static const int _defaultConcurrentTransfers =
      AppConstants.defaultConcurrentTransfers;

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
      if (history.length > _maxHistorySize) {
        history = history.sublist(0, _maxHistorySize);
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

  /// Save concurrent transfer count
  ///
  /// Parameters:
  /// - [count]: Number of concurrent transfers (1-10)
  Future<bool> saveConcurrentTransfers(int count) async {
    try {
      // Validate count range
      if (count < 1 || count > 10) {
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
}
