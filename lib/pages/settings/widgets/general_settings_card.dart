import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/language_service.dart';
import 'settings_section.dart';

/// General settings card widget
class GeneralSettingsCard extends StatelessWidget {
  final String currentLanguage;
  final VoidCallback onLanguageTap;

  const GeneralSettingsCard({
    super.key,
    required this.currentLanguage,
    required this.onLanguageTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsCardHeader(icon: Icons.language, title: l10n.general),
            const SizedBox(height: 20),
            InkWell(
              onTap: onLanguageTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.language,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LanguageService.getLanguageDisplayName(
                              currentLanguage,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
