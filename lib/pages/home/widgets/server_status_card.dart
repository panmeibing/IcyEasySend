import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/toast_helper.dart';

/// Server status indicator widget
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
    // Parse IP and port from serverAddress
    String? ip;
    String? port;
    if (serverAddress != null) {
      final parts = serverAddress!.split(':');
      if (parts.length == 2) {
        ip = parts[0];
        port = parts[1];
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isServerRunning
            ? const Color(0xFFE3F2FD)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isServerRunning
              ? const Color(0xFF2196F3)
              : const Color(0xFFE53935),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isServerRunning
                      ? const Color(0xFF2196F3)
                      : const Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isServerRunning ? l10n.serverRunning : l10n.serverStopped,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isServerRunning
                      ? const Color(0xFF1976D2)
                      : const Color(0xFFC62828),
                ),
              ),
            ],
          ),
          if (isServerRunning && ip != null && port != null) ...[
            const SizedBox(height: 16),
            Text(
              l10n.localIP,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) {
                final copyButton = _buildCopyButton(context, ip!);
                final ipText = Text(
                  ip,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212121),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );

                // Stack vertically when horizontal space is too tight for IP + copy.
                if (constraints.maxWidth < 80) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ipText,
                      const SizedBox(height: 4),
                      copyButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: ipText),
                    const SizedBox(width: 4),
                    copyButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              l10n.port,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              port,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context, String ip) {
    return IconButton(
      onPressed: () => _copyToClipboard(context, ip),
      icon: const Icon(Icons.copy, size: 16, color: Color(0xFF2196F3)),
      tooltip: AppLocalizations.of(context).copy,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  /// Copy text to clipboard
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
