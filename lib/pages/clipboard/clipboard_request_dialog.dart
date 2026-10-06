import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/clipboard_request_prompter.dart';
import '../../ui/form_factor.dart';
import '../../utils/constants.dart';
import '../tv/tv_widgets.dart';

/// Asks the user, with a countdown, whether a peer may read the clipboard.
class DialogClipboardRequestPrompter extends ClipboardRequestPrompter {
  const DialogClipboardRequestPrompter();

  @override
  Future<bool> confirm(
    BuildContext context, {
    required String requesterDeviceName,
  }) async {
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ClipboardRequestDialog(requesterDeviceName: requesterDeviceName),
    );
    return result == true;
  }
}

class ClipboardRequestDialog extends StatefulWidget {
  const ClipboardRequestDialog({super.key, required this.requesterDeviceName});

  final String requesterDeviceName;

  @override
  State<ClipboardRequestDialog> createState() => _ClipboardRequestDialogState();
}

class _ClipboardRequestDialogState extends State<ClipboardRequestDialog> {
  int _countdown = AppConstants.receiveConfirmationCountdown;
  Timer? _countdownTimer;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(AppConstants.countdownInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        _close(false);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Closes this dialog's own route, even if something else has since been
  /// pushed over it, so a late answer can never take down the wrong screen.
  void _close(bool allowed) {
    if (_closed || !mounted) return;
    _closed = true;
    _countdownTimer?.cancel();

    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);
    if (route == null || route.isCurrent) {
      navigator.pop(allowed);
    } else {
      navigator.removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (AppFormFactor.isTv) {
      return TvChoiceDialog(
        title: l10n.clipboardRequest,
        message:
            '${l10n.clipboardRequestFrom(widget.requesterDeviceName)}\n'
            '${l10n.autoRejectIn(_countdown)}',
        primaryLabel: l10n.reject,
        secondaryLabel: l10n.allowClipboardRequest,
        onPrimary: () => _close(false),
        onSecondary: () => _close(true),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.content_paste, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.clipboardRequest)),
        ],
      ),
      content: SizedBox(
        width: screenWidth * AppConstants.dialogWidthPercent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.clipboardRequestFrom(widget.requesterDeviceName),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.allowClipboardRequest,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _countdown / AppConstants.receiveConfirmationCountdown,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _countdown > 10 ? Colors.blue : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.autoRejectIn(_countdown),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => _close(false), child: Text(l10n.reject)),
        ElevatedButton(
          onPressed: () => _close(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.allow),
        ),
      ],
    );
  }
}
