import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/transfer_file_item.dart';
import '../home_ui.dart';
import 'expandable_split_control.dart';

/// File / folder pickers and the selected-item list.
class FileSelectionSection extends StatelessWidget {
  final List<TransferFileItem> selectedItems;
  final bool isEnabled;
  final bool isSending;
  final VoidCallback onSelectFiles;
  final VoidCallback onSelectFolder;
  final Function(int) onRemoveFile;
  final bool showTitle;

  const FileSelectionSection({
    super.key,
    required this.selectedItems,
    required this.isEnabled,
    required this.isSending,
    required this.onSelectFiles,
    required this.onSelectFolder,
    required this.onRemoveFile,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(l10n.selectFiles, style: HomeUi.sectionTitleStyle),
          const SizedBox(height: 8),
        ],
        ExpandableSplitControl(
          chevronEnabled: isEnabled,
          primary: ExpandableSplitControl.outlinedAction(
            onPressed: isEnabled ? onSelectFiles : null,
            icon: const Icon(Icons.insert_drive_file_rounded),
            label: l10n.selectFiles,
            enabled: isEnabled,
          ),
          expanded: ExpandableSplitControl.panel(
            reserveChevronSpace: true,
            child: ExpandableSplitControl.outlinedAction(
              onPressed: isEnabled ? onSelectFolder : null,
              icon: const Icon(Icons.folder_rounded),
              label: l10n.selectFolder,
              enabled: isEnabled,
            ),
          ),
        ),
        if (selectedItems.isNotEmpty) ...[
          SizedBox(height: HomeLayoutScope.of(context).itemGap),
          Text(
            l10n.filesSelected(selectedItems.length),
            style: const TextStyle(
              color: HomeUi.runningAccent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: HomeUi.chipFill,
              borderRadius: BorderRadius.circular(HomeUi.radiusSm),
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
                        : Icons.insert_drive_file_outlined,
                    size: 20,
                    color: HomeUi.primary,
                  ),
                  title: Text(
                    item.transferName,
                    style: const TextStyle(fontSize: 13, color: HomeUi.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
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
