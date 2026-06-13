import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/constants.dart';

/// Port input section widget
class PortInputSection extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? errorMessage;
  final bool isEnabled;
  final VoidCallback onReset;

  const PortInputSection({
    super.key,
    required this.controller,
    this.focusNode,
    this.errorMessage,
    required this.isEnabled,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.targetDevicePort,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: '${l10n.portHint}: ${AppConstants.defaultPort}',
            border: const OutlineInputBorder(),
            errorText: errorMessage,
            prefixIcon: const Icon(Icons.settings_ethernet),
            suffixIcon: IconButton(
              onPressed: isEnabled ? onReset : null,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.resetToDefaultPort(AppConstants.defaultPort),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          enabled: isEnabled,
        ),
      ],
    );
  }
}
