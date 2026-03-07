import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/transfer_history.dart';

/// History list item widget
class HistoryListItem extends StatelessWidget {
  final TransferHistory item;
  final VoidCallback onTap;
  final Function(String) onMenuAction;

  const HistoryListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final icon = item.isReceived ? Icons.download : Icons.upload;
    final iconColor = item.isReceived
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2196F3);
    final statusIcon = item.success ? Icons.check_circle : Icons.error;
    final statusColor = item.success
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE53935);

    // Display device name if available, otherwise show IP
    final peerDisplay = item.peerDeviceName ?? item.peerIP;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          item.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${item.isReceived ? l10n.from : l10n.sentTo}: $peerDisplay',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              tooltip: l10n.moreActions,
              onSelected: onMenuAction,
              itemBuilder: (context) => [
                // Only show "Open File" and "Open Folder" for received files with saved path
                if (item.isReceived &&
                    item.savedPath != null &&
                    item.success) ...[
                  PopupMenuItem(
                    value: 'open_file',
                    child: Row(
                      children: [
                        const Icon(Icons.open_in_new, size: 18),
                        const SizedBox(width: 12),
                        Text(l10n.openFile),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'open_folder',
                    child: Row(
                      children: [
                        const Icon(Icons.folder_open, size: 18),
                        const SizedBox(width: 12),
                        Text(l10n.openFolder),
                      ],
                    ),
                  ),
                ],
                PopupMenuItem(
                  value: 'view_details',
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18),
                      const SizedBox(width: 12),
                      Text(l10n.viewDetails),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.deleteRecord,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
