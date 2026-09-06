import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/language_service.dart';
import '../controllers/general_controller.dart';

/// Language selection dialog for settings.
class LanguageDialog {
  LanguageDialog._();

  /// Shows the language picker and applies the selection via [generalController].
  static Future<void> show(
    BuildContext context, {
    required GeneralController generalController,
    required void Function(String message) onSuccess,
  }) async {
    final l10n = AppLocalizations.of(context);
    final currentLanguage = generalController.getCurrentLanguageCode();
    String? selectedLanguage = currentLanguage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final supportedLanguages = LanguageService.getSupportedLanguages();

            return AlertDialog(
              title: Text(l10n.language),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: supportedLanguages.entries.map((entry) {
                      final languageCode = entry.key;
                      final languageConfig = entry.value;

                      return RadioListTile<String>(
                        title: Text(languageConfig.displayName),
                        value: languageCode,
                        // ignore: deprecated_member_use
                        groupValue: selectedLanguage,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          setState(() {
                            selectedLanguage = value;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedLanguage != null &&
                        selectedLanguage != currentLanguage) {
                      generalController.setLanguage(selectedLanguage!);
                      onSuccess(l10n.saved);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
