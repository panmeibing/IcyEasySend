import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language configuration model
class LanguageConfig {
  final String code;
  final String displayName;
  final Locale locale;

  const LanguageConfig({
    required this.code,
    required this.displayName,
    required this.locale,
  });
}

/// Service for managing app language settings
class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  // Supported languages configuration
  // To add a new language, simply add a new entry here
  static const Map<String, LanguageConfig> _supportedLanguages = {
    'system': LanguageConfig(
      code: 'system',
      displayName: 'System Default / 跟随系统',
      locale: Locale('en', 'US'), // Default fallback
    ),
    'zh': LanguageConfig(
      code: 'zh',
      displayName: '简体中文',
      locale: Locale('zh', 'CN'),
    ),
    'zh_HK': LanguageConfig(
      code: 'zh_HK',
      displayName: '繁體中文',
      locale: Locale('zh', 'HK'),
    ),
    'en': LanguageConfig(
      code: 'en',
      displayName: 'English',
      locale: Locale('en', 'US'),
    ),
    'ko': LanguageConfig(
      code: 'ko',
      displayName: '한국어',
      locale: Locale('ko', 'KR'),
    ),
    'ja': LanguageConfig(
      code: 'ja',
      displayName: '日本語',
      locale: Locale('ja', 'JP'),
    ),
    'fr': LanguageConfig(
      code: 'fr',
      displayName: 'Français',
      locale: Locale('fr', 'FR'),
    ),
    'de': LanguageConfig(
      code: 'de',
      displayName: 'Deutsch',
      locale: Locale('de', 'DE'),
    ),
    'es': LanguageConfig(
      code: 'es',
      displayName: 'Español',
      locale: Locale('es', 'ES'),
    ),
    'pt': LanguageConfig(
      code: 'pt',
      displayName: 'Português',
      locale: Locale('pt', 'PT'),
    ),
    'ru': LanguageConfig(
      code: 'ru',
      displayName: 'Русский',
      locale: Locale('ru', 'RU'),
    ),
    'it': LanguageConfig(
      code: 'it',
      displayName: 'Italiano',
      locale: Locale('it', 'IT'),
    ),
    'nl': LanguageConfig(
      code: 'nl',
      displayName: 'Nederlands',
      locale: Locale('nl', 'NL'),
    ),
  };

  // Singleton instance
  static LanguageService? _instance;

  static LanguageService get instance {
    _instance ??= LanguageService._internal();
    return _instance!;
  }

  // Private constructor for singleton
  LanguageService._internal();

  // Factory constructor that returns the singleton instance
  factory LanguageService() => instance;

  Locale? _locale;

  Locale? get locale => _locale;

  /// Initialize language service and load saved language preference
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);

    if (languageCode != null && languageCode.isNotEmpty) {
      _locale = _parseLocale(languageCode);
    }
    // If null, will use system language
  }

  /// Set app language
  ///
  /// [languageCode] can be:
  /// - 'system' for system default
  /// - 'zh' for Chinese
  /// - 'en' for English
  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();

    if (languageCode == 'system') {
      await prefs.remove(_languageKey);
      _locale = null;
    } else {
      await prefs.setString(_languageKey, languageCode);
      _locale = _parseLocale(languageCode);
    }

    notifyListeners();
  }

  /// Get current language code
  String getCurrentLanguageCode() {
    if (_locale == null) {
      return 'system';
    }
    // For locales with country code (like zh_HK), return the full code
    if (_locale!.countryCode != null && _locale!.countryCode!.isNotEmpty) {
      // Check if we have a matching language config with underscore format
      final fullCode = '${_locale!.languageCode}_${_locale!.countryCode}';
      if (_supportedLanguages.containsKey(fullCode)) {
        return fullCode;
      }
    }
    return _locale!.languageCode;
  }

  /// Parse language code to Locale
  Locale _parseLocale(String languageCode) {
    final config = _supportedLanguages[languageCode];
    return config?.locale ?? const Locale('en', 'US');
  }

  /// Get display name for language code
  static String getLanguageDisplayName(String languageCode) {
    final config = _supportedLanguages[languageCode];
    return config?.displayName ?? 'English';
  }

  /// Get all available languages
  static List<String> getAvailableLanguages() {
    return _supportedLanguages.keys.toList();
  }

  /// Get all language configurations
  static Map<String, LanguageConfig> getSupportedLanguages() {
    return _supportedLanguages;
  }
}
