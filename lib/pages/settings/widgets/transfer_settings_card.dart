import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/constants.dart';

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings_suggest,
                    color: Color(0xFF2196F3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.transferSettings,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Receive save path
            _buildSavePathSection(),

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 24),

            // Concurrent transfers setting
            _buildConcurrentTransfersSection(),

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 24),

            // Max history items setting
            _buildMaxHistorySection(),

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 24),

            // Max clipboard size setting
            _buildMaxClipboardSizeSection(),

            if (Platform.isAndroid && onClipboardOverlayChanged != null) ...[
              const SizedBox(height: 24),
              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 24),
              _buildClipboardOverlaySection(),
            ],

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 24),

            // IP validation toggle
            _buildIPValidationSection(),

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 24),

            // Secret key setting
            _buildSecretKeySection(),
          ],
        ),
      ),
    );
  }

  /// Build receive save path section
  Widget _buildSavePathSection() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.savePath,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF212121),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.savePathDesc,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
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
      },
    );
  }

  /// Build concurrent transfers section
  Widget _buildConcurrentTransfersSection() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.concurrentTransfers,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.concurrentTransfersDesc(maxConcurrentTransfers),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                onChanged: (value) =>
                    onConcurrentTransfersChanged(value.toInt()),
                onChangeEnd: (value) =>
                    onConcurrentTransfersChangeEnd(value.toInt()),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.concurrentTransfersHintText,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build max history section
  Widget _buildMaxHistorySection() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.maxHistory,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.maxHistoryDesc(allowMinHisCount, allowMaxHisCount),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      if (isEditingMaxHistory)
                        TextField(
                          controller: maxHistoryController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: l10n.maxHistoryHintText(
                              allowMinHisCount,
                              allowMaxHisCount,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          autofocus: true,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2196F3,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2196F3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.history,
                                size: 20,
                                color: Color(0xFF2196F3),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$maxHistoryItems 条',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isEditingMaxHistory) ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                    onPressed: onSaveMaxHistory,
                    tooltip: l10n.saved,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                    onPressed: onCancelMaxHistory,
                    tooltip: l10n.cancel,
                  ),
                ] else ...[
                  IconButton(
                    icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                    onPressed: onEditMaxHistory,
                    tooltip: l10n.editDeviceName,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.oldRecordsAutoDelete,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build max clipboard size section
  Widget _buildMaxClipboardSizeSection() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.maxClipboard,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.maxClipboardDesc(
                          AppConstants.minClipboardSizeMB,
                          AppConstants.maxClipboardSizeMB,
                        ),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      if (isEditingMaxClipboardSize)
                        TextField(
                          controller: maxClipboardSizeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: l10n.maxClipboardHintText(
                              AppConstants.minClipboardSizeMB,
                              AppConstants.maxClipboardSizeMB,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          autofocus: true,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2196F3,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2196F3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.content_paste,
                                size: 20,
                                color: Color(0xFF2196F3),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$maxClipboardSizeMB MB',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isEditingMaxClipboardSize) ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                    onPressed: onSaveMaxClipboardSize,
                    tooltip: l10n.saved,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                    onPressed: onCancelMaxClipboardSize,
                    tooltip: l10n.cancel,
                  ),
                ] else ...[
                  IconButton(
                    icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                    onPressed: onEditMaxClipboardSize,
                    tooltip: l10n.editDeviceName,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.clipboardSyncLimit,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Android-only: floating bubble to refresh clipboard cache.
  Widget _buildClipboardOverlaySection() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.clipboardOverlay,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.clipboardOverlayDesc,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: clipboardOverlayEnabled,
                  onChanged: onClipboardOverlayChanged,
                  activeTrackColor: const Color(0xFF2196F3),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.clipboardOverlayHint,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build IP validation section
  Widget _buildIPValidationSection() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.ipValidation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.ipValidationDesc,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enableIPValidation,
                  onChanged: onIPValidationChanged,
                  activeTrackColor: const Color(0xFF2196F3),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: enableIPValidation
                    ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                    : const Color(0xFFFFA726).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    enableIPValidation
                        ? Icons.info_outline
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: enableIPValidation
                        ? const Color(0xFF1976D2)
                        : const Color(0xFFF57C00),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      enableIPValidation
                          ? l10n.ipValidationEnabledHint
                          : l10n.ipValidationDisabledHint,
                      style: TextStyle(
                        fontSize: 11,
                        color: enableIPValidation
                            ? Colors.grey[700]
                            : const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build secret key section
  Widget _buildSecretKeySection() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.deviceSecretKey,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.deviceSecretKeyDesc,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      if (isEditingSecretKey)
                        TextField(
                          controller: secretKeyController,
                          decoration: InputDecoration(
                            hintText: l10n.deviceSecretKeyHint,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          autofocus: true,
                          obscureText: false,
                          maxLength: 20,
                          buildCounter:
                              (
                                context, {
                                required currentLength,
                                required isFocused,
                                maxLength,
                              }) {
                                return Text(
                                  '$currentLength/20',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: deviceSecretKey.isEmpty
                                ? Colors.grey.withValues(alpha: 0.1)
                                : const Color(
                                    0xFF2196F3,
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: deviceSecretKey.isEmpty
                                  ? Colors.grey
                                  : const Color(0xFF2196F3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                deviceSecretKey.isEmpty
                                    ? Icons.lock_open
                                    : Icons.lock,
                                size: 20,
                                color: deviceSecretKey.isEmpty
                                    ? Colors.grey
                                    : const Color(0xFF2196F3),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  deviceSecretKey.isEmpty
                                      ? l10n.notSet
                                      : '●' * deviceSecretKey.length,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: deviceSecretKey.isEmpty
                                        ? Colors.grey
                                        : const Color(0xFF2196F3),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isEditingSecretKey) ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                    onPressed: onSaveSecretKey,
                    tooltip: l10n.saved,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                    onPressed: onCancelSecretKey,
                    tooltip: l10n.cancel,
                  ),
                ] else ...[
                  IconButton(
                    icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                    onPressed: onEditSecretKey,
                    tooltip: l10n.editDeviceName,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.deviceSecretKeyDesc,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
