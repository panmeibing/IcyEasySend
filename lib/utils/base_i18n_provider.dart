/// Base class for internationalization providers that support message retrieval
/// without requiring BuildContext.
///
/// This base class provides common functionality for language code extraction
/// and message retrieval, allowing subclasses to focus on defining their
/// specific message maps.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/language_service.dart';

/// Abstract base class for i18n message providers
abstract class BaseI18nProvider {
  /// Get current language code, defaults to 'en' if not set
  String get currentLanguage {
    try {
      final locale = LanguageService.instance.locale;
      if (locale != null) {
        return _getLanguageCode(locale);
      }
      // When locale is null, it means user is following system language
      // We need to get the actual system language
      return _getSystemLanguage();
    } catch (e) {
      return 'en';
    }
  }

  /// Get language code from locale, handling country codes like zh_HK
  String _getLanguageCode(Locale locale) {
    // For locales with country code, check if we need the full code
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      final fullCode = '${locale.languageCode}_${locale.countryCode}';
      // Only zh_HK needs the full code to distinguish from zh (Simplified Chinese)
      // All other languages use the short language code
      if (fullCode == 'zh_HK') {
        return 'zh_HK';
      }
      // For all other cases, return just the language code
      return locale.languageCode;
    }
    return locale.languageCode;
  }

  /// Get system language code
  String _getSystemLanguage() {
    try {
      // Get system locale from platform
      final systemLocale = ui.PlatformDispatcher.instance.locale;
      return _getLanguageCode(systemLocale);
    } catch (e) {
      return 'en';
    }
  }

  /// Get message by language code, fallback to English if not found
  String getMessage(Map<String, String> messages) {
    return messages[currentLanguage] ?? messages['en'] ?? '';
  }

  /// Get message with single parameter
  String getMessageWith1Param<T>(
    Map<String, String Function(T)> messages,
    T param,
  ) {
    final messageFunc = messages[currentLanguage] ?? messages['en'];
    return messageFunc?.call(param) ?? '';
  }

  /// Get message with multiple parameters (3 params)
  String getMessageWith3Params<T1, T2, T3>(
    Map<String, String Function(T1, T2, T3)> messages,
    T1 param1,
    T2 param2,
    T3 param3,
  ) {
    final messageFunc = messages[currentLanguage] ?? messages['en'];
    return messageFunc?.call(param1, param2, param3) ?? '';
  }

  /// Get message with map parameter
  String getMessageWithMapParam(
    Map<String, String Function(Map<String, String>)> messages,
    Map<String, String> param,
  ) {
    final messageFunc = messages[currentLanguage] ?? messages['en'];
    return messageFunc?.call(param) ?? '';
  }
}
