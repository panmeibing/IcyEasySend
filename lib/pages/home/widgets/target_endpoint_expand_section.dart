import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/constants.dart';
import '../../../utils/dialog_helper.dart';
import '../home_ui.dart';
import 'expandable_split_control.dart';

/// Default: one-row target IP + chevron. Expand reveals port and secret key.
class TargetEndpointExpandSection extends StatefulWidget {
  final TextEditingController ipController;
  final TextEditingController portController;
  final TextEditingController secretKeyController;
  final FocusNode? ipFocusNode;
  final FocusNode? portFocusNode;
  final FocusNode? secretKeyFocusNode;
  final String? ipErrorMessage;
  final String? portErrorMessage;
  final bool isEnabled;
  final List<String> ipHistory;
  final ValueChanged<String> onIPSelected;
  final ValueChanged<String> onIPDeleted;
  final VoidCallback onPortReset;
  final VoidCallback onSecretKeyClear;

  const TargetEndpointExpandSection({
    super.key,
    required this.ipController,
    required this.portController,
    required this.secretKeyController,
    this.ipFocusNode,
    this.portFocusNode,
    this.secretKeyFocusNode,
    this.ipErrorMessage,
    this.portErrorMessage,
    required this.isEnabled,
    required this.ipHistory,
    required this.onIPSelected,
    required this.onIPDeleted,
    required this.onPortReset,
    required this.onSecretKeyClear,
  });

  @override
  State<TargetEndpointExpandSection> createState() =>
      _TargetEndpointExpandSectionState();
}

class _TargetEndpointExpandSectionState
    extends State<TargetEndpointExpandSection> {
  bool _ipHasText = false;
  bool _secretHasText = false;

  @override
  void initState() {
    super.initState();
    _ipHasText = widget.ipController.text.isNotEmpty;
    _secretHasText = widget.secretKeyController.text.isNotEmpty;
    widget.ipController.addListener(_onIpChanged);
    widget.secretKeyController.addListener(_onSecretChanged);
  }

  @override
  void dispose() {
    widget.ipController.removeListener(_onIpChanged);
    widget.secretKeyController.removeListener(_onSecretChanged);
    super.dispose();
  }

  void _onIpChanged() {
    final hasText = widget.ipController.text.isNotEmpty;
    if (_ipHasText != hasText) {
      setState(() => _ipHasText = hasText);
    }
  }

  void _onSecretChanged() {
    final hasText = widget.secretKeyController.text.isNotEmpty;
    if (_secretHasText != hasText) {
      setState(() => _secretHasText = hasText);
    }
  }

  void _showSecretHelp(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                const Icon(
                  Icons.security_rounded,
                  size: 16,
                  color: HomeUi.primary,
                ),
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
    final metrics = HomeLayoutScope.of(context);
    final enabled = widget.isEnabled;

    return ExpandableSplitControl(
      chevronEnabled: enabled,
      expandedTopGap: metrics.itemGap,
      primary: TextField(
        controller: widget.ipController,
        focusNode: widget.ipFocusNode,
        enabled: enabled,
        keyboardType: TextInputType.number,
        decoration: ExpandableSplitControl.fieldDecoration(
          labelText: l10n.targetDeviceIP,
          hintText: l10n.ipHint,
          errorText: widget.ipErrorMessage,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_ipHasText)
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  tooltip: l10n.clear,
                  onPressed: () => widget.ipController.clear(),
                ),
              if (widget.ipHistory.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.history_rounded),
                  tooltip: l10n.history,
                  onSelected: widget.onIPSelected,
                  itemBuilder: (context) {
                    return widget.ipHistory.map((ip) {
                      return PopupMenuItem<String>(
                        value: ip,
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(ip)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: HomeUi.stoppedAccent,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onIPDeleted(ip);
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
            ],
          ),
        ),
      ),
      expanded: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpandableSplitControl.panel(
            child: TextField(
              controller: widget.portController,
              focusNode: widget.portFocusNode,
              enabled: enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              decoration: ExpandableSplitControl.fieldDecoration(
                labelText: l10n.port,
                hintText: '${AppConstants.defaultPort}',
                errorText: widget.portErrorMessage,
                prefixIcon: const Icon(Icons.settings_ethernet_rounded),
                suffixIcon: IconButton(
                  onPressed: enabled ? widget.onPortReset : null,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: l10n.resetToDefaultPort(AppConstants.defaultPort),
                ),
              ),
            ),
          ),
          SizedBox(height: metrics.itemGap),
          ExpandableSplitControl.panel(
            child: TextField(
              controller: widget.secretKeyController,
              focusNode: widget.secretKeyFocusNode,
              enabled: enabled,
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
              decoration: ExpandableSplitControl.fieldDecoration(
                labelText: l10n.targetDeviceSecretKey,
                hintText: l10n.secretKeyHint,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_secretHasText)
                      IconButton(
                        onPressed:
                            enabled ? widget.onSecretKeyClear : null,
                        icon: const Icon(Icons.clear_rounded),
                        tooltip: l10n.clearSecretKey,
                      ),
                    IconButton(
                      onPressed: () => _showSecretHelp(context),
                      icon: const Icon(Icons.help_outline_rounded),
                      tooltip: l10n.secretKeyDescription,
                      iconSize: 20,
                      color: HomeUi.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
