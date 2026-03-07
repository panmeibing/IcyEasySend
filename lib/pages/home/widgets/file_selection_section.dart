import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../../l10n/app_localizations.dart';

/// File selection section widget
class FileSelectionSection extends StatelessWidget {
  final List<File> selectedFiles;
  final bool isEnabled;
  final bool isSending;
  final VoidCallback onSelectFiles;
  final Function(int) onRemoveFile;

  const FileSelectionSection({
    super.key,
    required this.selectedFiles,
    required this.isEnabled,
    required this.isSending,
    required this.onSelectFiles,
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
        ElevatedButton.icon(
          onPressed: isEnabled ? onSelectFiles : null,
          icon: const Icon(Icons.folder_open),
          label: Text(l10n.selectFiles),
        ),
        if (selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.filesSelected(selectedFiles.length),
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
              itemCount: selectedFiles.length,
              itemBuilder: (context, index) {
                final file = selectedFiles[index];
                final fileName = path.basename(file.path);
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.insert_drive_file, size: 20),
                  title: Text(
                    fileName,
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
