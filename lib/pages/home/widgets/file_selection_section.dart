import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/transfer_file_item.dart';

/// File selection section widget
class FileSelectionSection extends StatelessWidget {
  final List<TransferFileItem> selectedItems;
  final bool isEnabled;
  final bool isSending;
  final VoidCallback onSelectFiles;
  final VoidCallback onSelectFolder;
  final Function(int) onRemoveFile;

  const FileSelectionSection({
    super.key,
    required this.selectedItems,
    required this.isEnabled,
    required this.isSending,
    required this.onSelectFiles,
    required this.onSelectFolder,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.selectFiles,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isEnabled ? onSelectFiles : null,
                icon: const Icon(Icons.insert_drive_file),
                label: Text(l10n.selectFiles),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isEnabled ? onSelectFolder : null,
                icon: const Icon(Icons.folder),
                label: Text(l10n.selectFolder),
              ),
            ),
          ],
        ),
        if (selectedItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.filesSelected(selectedItems.length),
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: selectedItems.length,
              itemBuilder: (context, index) {
                final item = selectedItems[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    item.transferName.contains('/')
                        ? Icons.folder_outlined
                        : Icons.insert_drive_file,
                    size: 20,
                  ),
                  title: Text(
                    item.transferName,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: isSending ? null : () => onRemoveFile(index),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
