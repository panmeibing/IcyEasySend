import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/dialog_helper.dart';
import '../home_ui.dart';

/// Explains what the shared secret key is for and how to set it up.
void showSecretKeyHelpDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  const body = TextStyle(fontSize: 14);
  const heading = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

  DialogHelper.showCustomDialog(
    context,
    title: Row(
      children: [
        const Icon(Icons.help_outline_rounded, color: HomeUi.primary),
        const SizedBox(width: 8),
        Text(l10n.aboutSecretKey),
      ],
    ),
    content: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.secretKeyFeatureTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(l10n.secretKeyFeatureDesc, style: body),
          const SizedBox(height: 16),
          Text(l10n.secretKeyUsageSteps, style: heading),
          const SizedBox(height: 8),
          Text(
            '${l10n.secretKeyUsageStep1}\n'
            '${l10n.secretKeyUsageStep2}\n'
            '${l10n.secretKeyUsageStep3}',
            style: body,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.secretKeyTip,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1976D2)),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.gotIt),
      ),
    ],
  );
}
