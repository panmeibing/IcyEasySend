import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../home_ui.dart';
import 'expandable_split_control.dart';

/// Primary send action with QR share behind the expand chevron.
class SendActionsSection extends StatelessWidget {
  final bool canSend;
  final bool canShareViaQr;
  final bool isSending;
  final bool isCreatingWebShare;
  final int selectedItemsCount;
  final VoidCallback onSend;
  final VoidCallback onShareViaQr;

  const SendActionsSection({
    super.key,
    required this.canSend,
    required this.canShareViaQr,
    required this.isSending,
    required this.isCreatingWebShare,
    required this.selectedItemsCount,
    required this.onSend,
    required this.onShareViaQr,
  });

  String _sendLabel(AppLocalizations l10n) {
    if (isSending) return l10n.sending;
    if (selectedItemsCount > 1) {
      return l10n.filesCount(selectedItemsCount);
    }
    return l10n.sendFile;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sendEnabled = canSend;
    final labelColor = sendEnabled
        ? Colors.white
        : Colors.white.withValues(alpha: 0.75);

    return ExpandableSplitControl(
      style: ExpandableSplitStyle.filled,
      filledActive: sendEnabled,
      chevronEnabled: !isSending,
      radius: HomeUi.radiusLg,
      primaryMinHeight: 52,
      primary: TextButton.icon(
        onPressed: sendEnabled ? onSend : null,
        icon: isSending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.send_rounded, color: labelColor),
        label: Text(
          _sendLabel(l10n),
          style: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: const RoundedRectangleBorder(),
          foregroundColor: Colors.white,
        ),
      ),
      expanded: ExpandableSplitControl.panel(
        reserveChevronSpace: true,
        child: ExpandableSplitControl.outlinedAction(
          onPressed: canShareViaQr ? onShareViaQr : null,
          enabled: canShareViaQr,
          label: l10n.shareViaQr,
          icon: isCreatingWebShare
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.qr_code_2_rounded),
        ),
      ),
    );
  }
}
