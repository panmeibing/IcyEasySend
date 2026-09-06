import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/l10n/app_localizations.dart';
import 'package:icy_easy_send/l10n/current_localizations.dart';
import 'package:icy_easy_send/services/language_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `appText` is what lets the service layer drop its parallel message tables,
/// so it has to land on the same locale the widget tree would have. These
/// tests pin the resolution rules rather than any particular translation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LanguageService.instance.setLanguage('system');
  });

  test('an explicitly chosen language wins', () async {
    await LanguageService.instance.setLanguage('ja');

    expect(currentAppLocale(), const Locale('ja'));
    expect(appText.localeName, 'ja');
  });

  test('zh_HK stays Traditional instead of collapsing into zh', () async {
    await LanguageService.instance.setLanguage('zh_HK');

    expect(currentAppLocale(), const Locale('zh', 'HK'));
    expect(
      appText.diskFullTitle,
      isNot(lookupAppLocalizations(const Locale('zh')).diskFullTitle),
    );
  });

  test('a country the app has no translation for falls back to the bare '
      'language rather than to English', () async {
    // LanguageService stores English as en_US, which is not one of the
    // supported locales (they are bare language codes); the resolver has to
    // widen to Locale('en') instead of failing.
    await LanguageService.instance.setLanguage('en');

    expect(currentAppLocale(), const Locale('en'));
    expect(appText.localeName, 'en');
  });

  test('following the system language still lands on a supported locale',
      () async {
    await LanguageService.instance.setLanguage('system');

    expect(AppLocalizations.supportedLocales, contains(currentAppLocale()));
  });

  test('appText agrees with what a widget would have been handed', () async {
    await LanguageService.instance.setLanguage('fr');

    expect(
      appText.diskFullTitle,
      lookupAppLocalizations(const Locale('fr')).diskFullTitle,
    );
  });
}
