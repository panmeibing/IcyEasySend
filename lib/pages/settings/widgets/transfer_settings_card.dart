import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/constants.dart';
import 'settings_section.dart';

/// Transfer settings card widget
class TransferSettingsCard extends StatelessWidget {
  // Receive save path
  final String receiveSavePathDisplay;
  final bool isCustomReceiveSavePath;
  final VoidCallback onSelectSavePath;
  final VoidCallback onResetSavePathToDefault;

  // Concurrent transfers
  final int concurrentTransfers;
  final int tempConcurrentTransfers;
  final int maxConcurrentTransfers;
  final Function(int) onConcurrentTransfersChanged;
  final Function(int) onConcurrentTransfersChangeEnd;

  // Max history items
  final int maxHistoryItems;
  final bool isEditingMaxHistory;
  final int allowMaxHisCount;
  final int allowMinHisCount;
  final TextEditingController maxHistoryController;
  final VoidCallback onEditMaxHistory;
  final VoidCallback onSaveMaxHistory;
  final VoidCallback onCancelMaxHistory;

  // Max clipboard size
  final int maxClipboardSizeMB;
  final bool isEditingMaxClipboardSize;
  final TextEditingController maxClipboardSizeController;
  final VoidCallback onEditMaxClipboardSize;
  final VoidCallback onSaveMaxClipboardSize;
  final VoidCallback onCancelMaxClipboardSize;

  // Android clipboard overlay
  final bool clipboardOverlayEnabled;
  final ValueChanged<bool>? onClipboardOverlayChanged;

  // IP validation
  final bool enableIPValidation;
  final Function(bool) onIPValidationChanged;

  // Secret key
  final String deviceSecretKey;
  final bool isEditingSecretKey;
  final TextEditingController secretKeyController;
  final VoidCallback onEditSecretKey;
  final VoidCallback onSaveSecretKey;
  final VoidCallback onCancelSecretKey;

  const TransferSettingsCard({
    super.key,
    required this.receiveSavePathDisplay,
    required this.isCustomReceiveSavePath,
    required this.onSelectSavePath,
    required this.onResetSavePathToDefault,
    required this.concurrentTransfers,
    required this.tempConcurrentTransfers,
    required this.maxConcurrentTransfers,
    required this.onConcurrentTransfersChanged,
    required this.onConcurrentTransfersChangeEnd,
    required this.maxHistoryItems,
    required this.isEditingMaxHistory,
    required this.allowMaxHisCount,
    required this.allowMinHisCount,
    required this.maxHistoryController,
    required this.onEditMaxHistory,
    required this.onSaveMaxHistory,
    required this.onCancelMaxHistory,
    required this.maxClipboardSizeMB,
    required this.isEditingMaxClipboardSize,
    required this.maxClipboardSizeController,
    required this.onEditMaxClipboardSize,
    required this.onSaveMaxClipboardSize,
    required this.onCancelMaxClipboardSize,
    this.clipboardOverlayEnabled = false,
    this.onClipboardOverlayChanged,
    required this.enableIPValidation,
    required this.onIPValidationChanged,
    required this.deviceSecretKey,
    required this.isEditingSecretKey,
    required this.secretKeyController,
    required this.onEditSecretKey,
    required this.onSaveSecretKey,
    required this.onCancelSecretKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = <Widget>[
      _buildSavePathSection(l10n),
      _buildConcurrentTransfersSection(l10n),
      _buildMaxHistorySection(l10n),
      _buildMaxClipboardSizeSection(l10n),
      if (Platform.isAndroid && onClipboardOverlayChanged != null)
        _buildClipboardOverlaySection(l10n),
      _buildIPValidationSection(l10n),
      _buildSecretKeySection(l10n),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsCardHeader(
              icon: Icons.settings_suggest,
              title: l10n.transferSettings,
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: 24),
                Divider(height: 1, color: Colors.grey[300]),
                const SizedBox(height: 24),
              ],
              sections[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSavePathSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingTitle(title: l10n.savePath, description: l10n.savePathDesc),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF2196F3).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isCustomReceiveSavePath
                    ? Icons.folder_special
                    : Icons.folder_outlined,
                size: 20,
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCustomReceiveSavePath)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.savePathDefaultBadge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      receiveSavePathDisplay.isEmpty
                          ? l10n.savePathUnavailable
                          : receiveSavePathDisplay,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onSelectSavePath,
              icon: const Icon(Icons.folder_open, size: 18),
              label: Text(l10n.selectSavePath),
            ),
            if (isCustomReceiveSavePath)
              OutlinedButton.icon(
                onPressed: onResetSavePathToDefault,
                icon: const Icon(Icons.restore, size: 18),
                label: Text(l10n.resetSavePathToDefault),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildConcurrentTransfersSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SettingTitle(
                title: l10n.concurrentTransfers,
                description: l10n.concurrentTransfersDesc(
                  maxConcurrentTransfers,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$tempConcurrentTransfers',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF2196F3),
            inactiveTrackColor: Colors.grey[300],
            thumbColor: const Color(0xFF2196F3),
            overlayColor: const Color(0xFF2196F3).withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: tempConcurrentTransfers.toDouble(),
            min: 1,
            max: maxConcurrentTransfers.toDouble(),
            divisions: 9,
            label: '$tempConcurrentTransfers',
            onChanged: (value) => onConcurrentTransfersChanged(value.toInt()),
            onChangeEnd: (value) =>
                onConcurrentTransfersChangeEnd(value.toInt()),
          ),
        ),
        const SizedBox(height: 12),
        SettingHint(l10n.concurrentTransfersHintText),
      ],
    );
  }

  Widget _buildMaxHistorySection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditableSetting(
          title: l10n.maxHistory,
          description: l10n.maxHistoryDesc(allowMinHisCount, allowMaxHisCount),
          isEditing: isEditingMaxHistory,
          editor: _numberField(
            maxHistoryController,
            l10n.maxHistoryHintText(allowMinHisCount, allowMaxHisCount),
          ),
          display: SettingValueChip(
            icon: Icons.history,
            label: l10n.historyItemsCount(maxHistoryItems),
          ),
          onEdit: onEditMaxHistory,
          onSave: onSaveMaxHistory,
          onCancel: onCancelMaxHistory,
        ),
        const SizedBox(height: 12),
        SettingHint(l10n.oldRecordsAutoDelete),
      ],
    );
  }

  Widget _buildMaxClipboardSizeSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditableSetting(
          title: l10n.maxClipboard,
          description: l10n.maxClipboardDesc(
            AppConstants.minClipboardSizeMB,
            AppConstants.maxClipboardSizeMB,
          ),
          isEditing: isEditingMaxClipboardSize,
          editor: _numberField(
            maxClipboardSizeController,
            l10n.maxClipboardHintText(
              AppConstants.minClipboardSizeMB,
              AppConstants.maxClipboardSizeMB,
            ),
          ),
          display: SettingValueChip(
            icon: Icons.content_paste,
            label: '$maxClipboardSizeMB MB',
          ),
          onEdit: onEditMaxClipboardSize,
          onSave: onSaveMaxClipboardSize,
          onCancel: onCancelMaxClipboardSize,
        ),
        const SizedBox(height: 12),
        SettingHint(l10n.clipboardSyncLimit),
      ],
    );
  }

  /// Android-only: floating bubble to refresh clipboard cache.
  Widget _buildClipboardOverlaySection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingSwitchRow(
          title: l10n.clipboardOverlay,
          description: l10n.clipboardOverlayDesc,
          value: clipboardOverlayEnabled,
          onChanged: onClipboardOverlayChanged,
        ),
        const SizedBox(height: 12),
        SettingHint(l10n.clipboardOverlayHint),
      ],
    );
  }

  Widget _buildIPValidationSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingSwitchRow(
          title: l10n.ipValidation,
          description: l10n.ipValidationDesc,
          value: enableIPValidation,
          onChanged: onIPValidationChanged,
        ),
        const SizedBox(height: 12),
        SettingHint(
          enableIPValidation
              ? l10n.ipValidationEnabledHint
              : l10n.ipValidationDisabledHint,
          warning: !enableIPValidation,
        ),
      ],
    );
  }

  Widget _buildSecretKeySection(AppLocalizations l10n) {
    final hasKey = deviceSecretKey.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditableSetting(
          title: l10n.deviceSecretKey,
          description: l10n.deviceSecretKeyDesc,
          isEditing: isEditingSecretKey,
          editor: TextField(
            controller: secretKeyController,
            decoration: settingInputDecoration(l10n.deviceSecretKeyHint),
            autofocus: true,
            maxLength: _secretKeyMaxLength,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) {
                  return Text(
                    '$currentLength/$_secretKeyMaxLength',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  );
                },
          ),
          display: SettingValueChip(
            icon: hasKey ? Icons.lock : Icons.lock_open,
            label: hasKey ? '●' * deviceSecretKey.length : l10n.notSet,
            active: hasKey,
          ),
          onEdit: onEditSecretKey,
          onSave: onSaveSecretKey,
          onCancel: onCancelSecretKey,
        ),
        const SizedBox(height: 12),
        SettingHint(l10n.deviceSecretKeyDesc),
      ],
    );
  }

  static const int _secretKeyMaxLength = 20;

  Widget _numberField(TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: settingInputDecoration(hintText),
      autofocus: true,
    );
  }
}
