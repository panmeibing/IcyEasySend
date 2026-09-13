import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/toast_helper.dart';
import '../home_ui.dart';

/// Running/stopped + copyable `ip:port` status pill for the orbit home top bar.
class OrbitStatusPill extends StatelessWidget {
  final bool isServerRunning;
  final String? serverAddress;

  const OrbitStatusPill({
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

    final running = isServerRunning;
    final accent = running ? HomeUi.runningAccent : HomeUi.stoppedAccent;
    final fill = running ? HomeUi.runningFill : HomeUi.stoppedFill;
    final showAddress = running && ip != null && port != null;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: showAddress ? () => _copyIp(context, ip!) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                running ? l10n.serverRunning : l10n.serverStopped,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              if (showAddress) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$ip:$port',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: HomeUi.inkMuted,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.copy_rounded,
                  size: 13,
                  color: HomeUi.inkMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyIp(BuildContext context, String ip) async {
    await Clipboard.setData(ClipboardData(text: ip));
    if (context.mounted) {
      ToastHelper.showSuccess(
        context,
        AppLocalizations.of(context).ipCopied(ip),
      );
    }
  }
}
