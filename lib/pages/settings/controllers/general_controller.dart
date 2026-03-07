import '../../../services/language_service.dart';

/// Controller for general settings
class GeneralController {
  final LanguageService _languageService;

  GeneralController({LanguageService? languageService})
    : _languageService = languageService ?? LanguageService();

  /// Get current language code
  String getCurrentLanguageCode() {
    return _languageService.getCurrentLanguageCode();
  }

  /// Set language
  Future<void> setLanguage(String languageCode) async {
    await _languageService.setLanguage(languageCode);
  }

  /// Get language display name
  String getLanguageDisplayName(String languageCode) {
    return LanguageService.getLanguageDisplayName(languageCode);
  }
}
