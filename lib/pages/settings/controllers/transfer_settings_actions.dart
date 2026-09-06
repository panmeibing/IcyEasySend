import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/clipboard_overlay_service.dart';
import '../../../services/preferences_service.dart';
import '../../../services/validation_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/dialog_helper.dart';
import '../models/settings_state.dart';
import 'transfer_controller.dart';

/// Transfer/settings save+confirm flows owned by [SettingsPage].
///
/// Keeps ScaffoldMessenger / [SettingsState] mutation on the page via
/// callbacks — this class only orchestrates prefs, validation, and dialogs.
class TransferSettingsActions {
  final TransferController transferController;
  final PreferencesService preferencesService;
  final ValidationService validationService;
  final int allowMinHisCount;
  final int allowMaxHisCount;

  final bool Function() isMounted;
  final SettingsState Function() getState;
  final void Function(SettingsState Function(SettingsState)) updateState;
  final void Function(String message) onSuccess;
  final void Function(String message) onError;
  final void Function(String message) onWarning;
  final VoidCallback onHistoryRefresh;
  final Future<void> Function() reloadReceiveSavePath;

  TransferSettingsActions({
    required this.transferController,
    required this.preferencesService,
    required this.validationService,
    required this.allowMinHisCount,
    required this.allowMaxHisCount,
    required this.isMounted,
    required this.getState,
    required this.updateState,
    required this.onSuccess,
    required this.onError,
    required this.onWarning,
    required this.onHistoryRefresh,
    required this.reloadReceiveSavePath,
  });

  /// Show confirmation dialog for concurrent transfers change
  Future<void> confirmAndSaveConcurrentTransfers(
    BuildContext context,
    int newCount,
  ) async {
    final l10n = AppLocalizations.of(context);
    final state = getState();
    // If value hasn't changed, no need to confirm
    if (newCount == state.concurrentTransfers) {
      return;
    }

    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: l10n.confirmChange,
      // Raising and lowering the limit carry opposite advice, so they are two
      // messages rather than one with a comparison buried inside the string.
      message: newCount > state.concurrentTransfers
          ? l10n.concurrentTransfersIncrease(
              state.concurrentTransfers,
              newCount,
            )
          : l10n.concurrentTransfersDecrease(
              state.concurrentTransfers,
              newCount,
            ),
      confirmText: l10n.confirmChange,
      cancelText: l10n.cancel,
      icon: Icons.settings_suggest,
      iconColor: const Color(0xFF2196F3),
    );

    if (confirmed) {
      await _saveConcurrentTransfers(l10n, newCount);
    } else {
      // User cancelled, revert to previous value
      if (isMounted()) {
        updateState(
          (s) => s.copyWith(tempConcurrentTransfers: s.concurrentTransfers),
        );
      }
    }
  }

  Future<void> _saveConcurrentTransfers(
    AppLocalizations l10n,
    int count,
  ) async {
    final success = await transferController.saveConcurrentTransfers(count);
    if (success) {
      updateState((s) => s.copyWith(concurrentTransfers: count));
      onSuccess(l10n.concurrentTransfersSaved);
    } else {
      onError(l10n.saveFailed);
    }
  }

  /// Confirm and save max history items
  Future<void> confirmAndSaveMaxHistoryItems(
    BuildContext context, {
    required TextEditingController maxHistoryController,
  }) async {
    final l10n = AppLocalizations.of(context);
    final newCountText = maxHistoryController.text.trim();
    if (newCountText.isEmpty) {
      onError(l10n.enterValidNumber);
      return;
    }

    final newCount = int.tryParse(newCountText);
    if (newCount == null) {
      onError(l10n.enterValidNumber);
      return;
    }

    if (newCount < allowMinHisCount || newCount > allowMaxHisCount) {
      onError(l10n.historyCountRange(allowMinHisCount, allowMaxHisCount));
      return;
    }

    final state = getState();
    // If value hasn't changed, no need to confirm
    if (newCount == state.maxHistoryItems) {
      updateState((s) => s.copyWith(isEditingMaxHistory: false));
      return;
    }

    final currentCount = await transferController.getCurrentHistoryCount();

    String message = l10n.maxHistoryChange(state.maxHistoryItems, newCount);
    message += l10n.currentHistoryCount(currentCount);

    if (currentCount > newCount) {
      final deleteCount = currentCount - newCount;
      message += l10n.historyWarning;
      message += l10n.historyDeleteWarning(currentCount, newCount, deleteCount);
    } else {
      message += l10n.historyHint;
    }

    if (!context.mounted) return;

    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: l10n.confirmChange,
      message: message,
      confirmText: l10n.confirmChange,
      cancelText: l10n.cancel,
      icon: Icons.history,
      iconColor: const Color(0xFF2196F3),
    );

    if (confirmed) {
      await _saveMaxHistoryItems(l10n, newCount, currentCount);
    } else {
      // Revert text outside setState — TextEditingController notifies on its own.
      if (isMounted()) {
        maxHistoryController.text = getState().maxHistoryItems.toString();
        updateState((s) => s.copyWith(isEditingMaxHistory: false));
      }
    }
  }

  Future<void> _saveMaxHistoryItems(
    AppLocalizations l10n,
    int newCount,
    int currentCount,
  ) async {
    final result = await transferController.saveMaxHistoryItems(
      newCount,
      currentCount,
    );

    if (result['success']) {
      updateState(
        (s) => s.copyWith(
          maxHistoryItems: newCount,
          isEditingMaxHistory: false,
        ),
      );

      final deletedCount = result['deletedCount'] as int;
      if (deletedCount > 0) {
        onSuccess(l10n.historyDeleted(deletedCount));
        onHistoryRefresh();
      } else {
        onSuccess(l10n.maxHistorySaved);
      }
    } else {
      onError(l10n.saveFailed);
    }
  }

  /// Confirm and save max clipboard size
  Future<void> confirmAndSaveMaxClipboardSize(
    BuildContext context, {
    required TextEditingController maxClipboardSizeController,
  }) async {
    final l10n = AppLocalizations.of(context);
    final newSizeText = maxClipboardSizeController.text.trim();
    if (newSizeText.isEmpty) {
      onError(l10n.enterValidNumber);
      return;
    }

    final newSize = int.tryParse(newSizeText);
    if (newSize == null) {
      onError(l10n.enterValidNumber);
      return;
    }

    if (newSize < AppConstants.minClipboardSizeMB ||
        newSize > AppConstants.maxClipboardSizeMB) {
      onError(
        l10n.clipboardSizeRange(
          AppConstants.minClipboardSizeMB,
          AppConstants.maxClipboardSizeMB,
        ),
      );
      return;
    }

    final state = getState();
    // If value hasn't changed, no need to confirm
    if (newSize == state.maxClipboardSizeMB) {
      updateState((s) => s.copyWith(isEditingMaxClipboardSize: false));
      return;
    }

    String message = l10n.maxClipboardSizeChange(
      state.maxClipboardSizeMB,
      newSize,
    );

    if (newSize < state.maxClipboardSizeMB) {
      message += l10n.clipboardSizeDecreaseHint;
    } else {
      message += l10n.clipboardSizeIncreaseHint;
    }

    if (!context.mounted) return;

    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: l10n.confirmChange,
      message: message,
      confirmText: l10n.confirmChange,
      cancelText: l10n.cancel,
      icon: Icons.content_paste,
      iconColor: const Color(0xFF2196F3),
    );

    if (confirmed) {
      await _saveMaxClipboardSize(l10n, newSize);
    } else {
      if (isMounted()) {
        maxClipboardSizeController.text =
            getState().maxClipboardSizeMB.toString();
        updateState((s) => s.copyWith(isEditingMaxClipboardSize: false));
      }
    }
  }

  Future<void> _saveMaxClipboardSize(
    AppLocalizations l10n,
    int newSize,
  ) async {
    final success = await transferController.saveMaxClipboardSize(newSize);
    if (success) {
      updateState(
        (s) => s.copyWith(
          maxClipboardSizeMB: newSize,
          isEditingMaxClipboardSize: false,
        ),
      );
      onSuccess(l10n.maxClipboardSizeSaved);
    } else {
      onError(l10n.saveFailed);
    }
  }

  /// Pick a custom directory for received files
  Future<void> pickReceiveSavePath(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.selectSavePath,
    );

    if (selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }

    final validationResult = await validationService.validateDirectoryWritable(
      selectedPath,
    );

    if (!validationResult.isSuccess) {
      if (isMounted()) {
        onError(l10n.savePathNotWritable);
      }
      return;
    }

    final saved = await transferController.saveCustomReceiveSavePath(
      selectedPath,
    );

    if (!isMounted()) return;

    if (saved) {
      updateState(
        (s) => s.copyWith(
          receiveSavePathDisplay: selectedPath,
          isCustomReceiveSavePath: true,
        ),
      );
      onSuccess(l10n.savePathSavedSuccess);
    } else {
      onError(l10n.saveFailed);
    }
  }

  /// Reset receive save path to system downloads folder
  Future<void> resetReceiveSavePathToDefault(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final success = await transferController.clearCustomReceiveSavePath();
    if (!isMounted()) return;

    if (success) {
      await reloadReceiveSavePath();
      onSuccess(l10n.savePathResetSuccess);
    } else {
      onError(l10n.saveFailed);
    }
  }

  /// Save IP validation enabled state
  Future<void> saveIPValidationEnabled(
    BuildContext context,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context);
    final success = await transferController.saveIPValidationEnabled(enabled);
    if (success) {
      updateState((s) => s.copyWith(enableIPValidation: enabled));
      onSuccess(
        enabled ? l10n.ipValidationEnabled : l10n.ipValidationDisabled,
      );
    } else {
      onError(l10n.saveFailed);
    }
  }

  /// Save device secret key
  Future<void> saveDeviceSecretKey(
    BuildContext context, {
    required TextEditingController secretKeyController,
  }) async {
    final l10n = AppLocalizations.of(context);
    final newKey = secretKeyController.text.trim();

    final success = await preferencesService.saveDeviceSecretKey(newKey);
    if (success) {
      updateState(
        (s) => s.copyWith(
          deviceSecretKey: newKey,
          isEditingSecretKey: false,
        ),
      );
      if (newKey.isEmpty) {
        onSuccess(l10n.deviceSecretKeyCleared);
      } else {
        onSuccess(l10n.deviceSecretKeySaved);
      }
    } else {
      onError(l10n.saveFailed);
    }
  }

  Future<void> onClipboardOverlayChanged(
    BuildContext context,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context);
    final shown = await ClipboardOverlayService.instance.applyOverlayPreference(
      enabled,
    );

    if (!isMounted()) return;

    updateState((s) => s.copyWith(clipboardOverlayEnabled: enabled));

    if (enabled && !shown) {
      onWarning(l10n.clipboardOverlayPermissionNeeded);
    } else if (enabled && shown) {
      onSuccess(l10n.clipboardOverlayEnabledToast);
    }
  }
}
