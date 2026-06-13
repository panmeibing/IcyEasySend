import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/dialog_helper.dart';

/// Secret key input section widget
class SecretKeyInputSection extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isEnabled;
  final VoidCallback onClear;

  const SecretKeyInputSection({
    super.key,
    required this.controller,
    this.focusNode,
    required this.isEnabled,
    required this.onClear,
  });

  @override
  State<SecretKeyInputSection> createState() => _SecretKeyInputSectionState();
}

class _SecretKeyInputSectionState extends State<SecretKeyInputSection> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  /// Show help dialog with secret key information
  void _showHelpDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    DialogHelper.showCustomDialog(
      context,
      title: Row(
        children: [
          const Icon(Icons.help_outline, color: Color(0xFF2196F3)),
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
            Text(
              l10n.secretKeyFeatureDesc,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.secretKeyUsageSteps,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.secretKeyUsageStep1}\n${l10n.secretKeyUsageStep2}\n${l10n.secretKeyUsageStep3}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.security, size: 16, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.secretKeyTip,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.targetDeviceSecretKey,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            hintText: l10n.secretKeyHint,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.vpn_key),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasText)
                  IconButton(
                    onPressed: widget.isEnabled ? widget.onClear : null,
                    icon: const Icon(Icons.clear),
                    tooltip: l10n.clearSecretKey,
                  ),
                IconButton(
                  onPressed: () => _showHelpDialog(context),
                  icon: const Icon(Icons.help_outline),
                  tooltip: l10n.secretKeyDescription,
                  iconSize: 20,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          enabled: widget.isEnabled,
          obscureText: true,
          maxLength: 20,
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) {
                return null;
              },
        ),
      ],
    );
  }
}
