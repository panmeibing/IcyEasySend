import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Send and QR web-share action buttons.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: canSend ? onSend : null,
          icon: isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send),
          label: Text(
            isSending
                ? l10n.sending
                : selectedItemsCount > 1
                ? l10n.filesCount(selectedItemsCount)
                : l10n.sendFile,
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: canShareViaQr ? onShareViaQr : null,
          icon: isCreatingWebShare
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.qr_code_2),
          label: Text(l10n.shareViaQr),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            foregroundColor: Colors.blue,
            side: BorderSide(
              color: canShareViaQr ? Colors.blue : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
