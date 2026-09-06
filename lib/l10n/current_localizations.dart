import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../services/language_service.dart';
import 'app_localizations.dart';

/// [AppLocalizations] for the language currently in effect, without a context.
///
/// `AppLocalizations.of(context)` is the right call inside a widget, but a lot
/// of user-visible text in this app is produced where no widget tree is in
/// reach: shelf handlers building JSON error bodies, Android foreground
/// notifications, and transfer status callbacks. That gap is the whole reason
/// a second, parallel set of message tables grew up in `lib/utils/*_provider`.
///
/// Prefer `AppLocalizations.of(context)` when a context is genuinely available
/// — it follows the widget tree, so it stays correct under `Localizations`
/// overrides. This is for the code that has no such option.
AppLocalizations get appText => lookupAppLocalizations(currentAppLocale());

/// Resolves the locale the same way `MaterialApp.localeResolutionCallback` in
/// `main.dart` does, so context-free lookups cannot drift from the UI.
Locale currentAppLocale() {
  final chosen = LanguageService.instance.locale;
  if (chosen != null) {
    return _nearestSupported(chosen) ?? chosen;
  }
  // Following the system language.
  final system = ui.PlatformDispatcher.instance.locale;
  return _nearestSupported(system) ?? const Locale('en');
}

/// Picks the supported locale that best matches [locale].
///
/// An exact match wins so zh_HK is not quietly served Simplified Chinese;
/// otherwise the bare language is good enough.
Locale? _nearestSupported(Locale locale) {
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == locale.languageCode &&
        supported.countryCode == locale.countryCode) {
      return supported;
    }
  }
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == locale.languageCode &&
        (supported.countryCode == null || supported.countryCode!.isEmpty)) {
      return supported;
    }
  }
  return null;
}
