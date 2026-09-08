import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/toast_helper.dart';
import '../home_ui.dart';

/// Compact friendly server status strip.
class ServerStatusCard extends StatelessWidget {
  final bool isServerRunning;
  final String? serverAddress;

  const ServerStatusCard({
    super.key,
    required this.isServerRunning,
    this.serverAddress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? ip;
    String? port;
    if (serverAddress != null) {
      final parts = serverAddress!.split(':');
      if (parts.length == 2) {
        ip = parts[0];
        port = parts[1];
      }
    }

    final fill =
        isServerRunning ? HomeUi.runningFill : HomeUi.stoppedFill;
    final accent =
        isServerRunning ? HomeUi.runningAccent : HomeUi.stoppedAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(HomeUi.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isServerRunning ? l10n.serverRunning : l10n.serverStopped,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          if (isServerRunning && ip != null && port != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AddressChip(
                    label: l10n.localIP,
                    value: ip,
                    onCopy: () {
                      final copyIp = ip;
                      if (copyIp != null) {
                        _copyToClipboard(context, copyIp);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                _AddressChip(
                  label: l10n.port,
                  value: port,
                ),
              ],
            ),
          ],
          if (Platform.isAndroid && isServerRunning) ...[
            const SizedBox(height: 8),
            Text(
              l10n.androidBackgroundReceiveHint,
              style: HomeUi.captionStyle.copyWith(
                color: HomeUi.inkMuted.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ToastHelper.showSuccess(
        context,
        AppLocalizations.of(context).ipCopied(text),
      );
    }
  }
}

class _AddressChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _AddressChip({
    required this.label,
    required this.value,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(HomeUi.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HomeUi.captionStyle),
          const SizedBox(height: 2),
          Row(
            mainAxisSize:
                onCopy == null ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: HomeUi.ink,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  color: HomeUi.primary,
                  tooltip: AppLocalizations.of(context).copy,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
