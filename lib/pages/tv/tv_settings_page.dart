import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/paired_device.dart';
import '../../models/relay_config.dart';
import '../../services/identity_service.dart';
import '../../services/language_service.dart';
import '../../services/paired_device_store.dart';
import '../../services/preferences_service.dart';
import '../../services/relay/relay_service.dart';
import '../../services/transfer_history_service.dart';
import '../../ui/form_factor.dart';
import '../../utils/constants.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/toast_helper.dart';
import '../home/home_ui.dart';
import '../pairing/pairing_confirm_dialog.dart';
import '../settings/controllers/device_controller.dart';
import '../settings/controllers/transfer_controller.dart';
import 'tv_file_browser.dart';
import 'tv_widgets.dart';

class TvSettingsPage extends StatefulWidget {
  final LanguageService languageService;

  const TvSettingsPage({super.key, required this.languageService});

  @override
  State<TvSettingsPage> createState() => _TvSettingsPageState();
}

class _TvSettingsPageState extends State<TvSettingsPage> {
  final PreferencesService _preferences = PreferencesService();
  late final DeviceController _devices = DeviceController(_preferences);
  late final TransferController _transfer = TransferController(
    _preferences,
    TransferHistoryService(),
  );

  String _name = '';
  String? _savePath;
  String _language = '';
  int _concurrent = AppConstants.defaultConcurrentTransfers;
  int _historyLimit = AppConstants.defaultMaxHistoryItems;
  int _clipboardMb = AppConstants.defaultMaxClipboardSize;
  int _pairedCount = 0;
  String _relayLabel = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await _devices.loadDeviceInfo();
    final path = await _transfer.loadCustomReceiveSavePath();
    final concurrent = await _transfer.loadConcurrentTransfers();
    final history = await _transfer.loadMaxHistoryItems();
    final clipboard = await _transfer.loadMaxClipboardSize();
    final paired = await PairedDeviceStore.instance.loadAll();
    final relay = await _preferences.getRelayConfig();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _name = info['name'] ?? '';
      _savePath = path;
      _language = LanguageService.getLanguageDisplayName(
        widget.languageService.getCurrentLanguageCode(),
      );
      _concurrent = concurrent;
      _historyLimit = history;
      _clipboardMb = clipboard;
      _pairedCount = paired.length;
      _relayLabel = relay.isActive ? relay.displayHost : l10n.statusDisabled;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final rows = <_Setting>[
      _Setting(l10n.deviceName, _name, _editName),
      _Setting(l10n.savePath, _savePath ?? l10n.tvDownloadsFolder, _editPath),
      _Setting(l10n.pairedDevicesTitle, '$_pairedCount', _editPaired),
      _Setting(l10n.title, _relayLabel, _editRelay),
      _Setting(l10n.language, _language, _editLanguage),
      _Setting(
        l10n.concurrentTransfers,
        '$_concurrent',
        () => _editInt(
          title: l10n.concurrentTransfers,
          value: _concurrent,
          min: 1,
          max: AppConstants.maxConcurrentTransfers,
          onSave: _transfer.saveConcurrentTransfers,
        ),
      ),
      _Setting(
        l10n.maxHistory,
        '$_historyLimit',
        () => _editInt(
          title: l10n.maxHistory,
          value: _historyLimit,
          min: AppConstants.allowMinHistoryItems,
          max: AppConstants.allowMaxHistoryItems,
          onSave: _saveHistoryLimit,
        ),
      ),
      _Setting(
        l10n.maxClipboard,
        '$_clipboardMb MB',
        () => _editInt(
          title: l10n.maxClipboard,
          value: _clipboardMb,
          min: AppConstants.minClipboardSizeMB,
          max: AppConstants.maxClipboardSizeMB,
          onSave: _transfer.saveMaxClipboardSize,
        ),
      ),
      _Setting(
        l10n.about,
        '${AppConstants.projectName} ${AppConstants.version}',
        _showAbout,
      ),
    ];

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = rows[index];
        return TvRow(
          title: row.title,
          subtitle: row.value,
          onPressed: row.onPressed,
        );
      },
    );
  }

  Future<void> _editName() async {
    final next = await showTvTextPrompt(
      context,
      title: AppLocalizations.of(context).deviceName,
      label: AppLocalizations.of(context).deviceName,
      initial: _name,
    );
    if (next == null || next.isEmpty) return;
    final saved = await _devices.saveDeviceName(next);
    if (!mounted) return;
    if (saved) await _load();
  }

  Future<void> _editPath() async {
    final l10n = AppLocalizations.of(context);
    try {
      // This TV has no system folder picker. The same browser used for sending
      // returns the folder that is open when the user confirms.
      final String? selected;
      if (Platform.isAndroid && AppFormFactor.isTv) {
        final picked = await showTvFileBrowser(context, selectDirectory: true);
        selected = picked == null || picked.isEmpty ? null : picked.first;
      } else {
        selected = await FilePicker.platform.getDirectoryPath();
      }
      if (selected == null || selected.isEmpty || !mounted) return;
      final change = await _transfer.setCustomReceiveSavePath(selected);
      if (!mounted) return;
      switch (change) {
        case ReceivePathChange.notWritable:
          ToastHelper.showError(context, l10n.savePathNotWritable);
        case ReceivePathChange.saveFailed:
          ToastHelper.showError(context, l10n.tvPathUnchanged);
        case ReceivePathChange.saved:
          await _load();
      }
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, l10n.tvPathUnchanged);
    }
  }

  Future<void> _editPaired() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _PairedDialog(
        onChanged: () {
          if (mounted) unawaited(_load());
        },
      ),
    );
    await _load();
  }

  Future<void> _editRelay() async {
    final l10n = AppLocalizations.of(context);
    final current = await _preferences.getRelayConfig();
    if (!mounted) return;
    final url = await showTvTextPrompt(
      context,
      title: l10n.serverUrlLabel,
      label: l10n.serverUrlLabel,
      initial: current.serverUrl,
    );
    if (!mounted || url == null) return;
    final token = await showTvTextPrompt(
      context,
      title: l10n.tokenLabel,
      label: l10n.tokenLabel,
      initial: current.token,
      obscure: true,
    );
    if (!mounted || token == null) return;
    final enable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return TvChoiceDialog(
          title: l10n.enableLabel,
          message: url.isEmpty ? l10n.statusDisabled : url,
          primaryLabel: l10n.statusDisabled,
          secondaryLabel: l10n.enableLabel,
          onPrimary: () => Navigator.of(dialogContext).pop(false),
          onSecondary: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
    if (!mounted || enable == null) return;
    final config = RelayConfig(
      serverUrl: url,
      token: token,
      enabled: enable && url.isNotEmpty && token.isNotEmpty,
    );
    final saved = await RelayService.instance.updateConfig(config);
    if (!mounted) return;
    if (!saved) {
      ToastHelper.showError(context, l10n.saveFailed);
    }
    await _load();
  }

  Future<void> _editLanguage() async {
    final languages = LanguageService.getSupportedLanguages();
    final codes = languages.keys.toList();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: codes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final code = codes[index];
                  final config = languages[code]!;
                  return TvRow(
                    title: config.displayName,
                    autofocus: index == 0,
                    onPressed: () async {
                      await widget.languageService.setLanguage(code);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    if (mounted) await _load();
  }

  /// Lowering the limit deletes history at once, so it is confirmed first,
  /// the same as on the phone settings page.
  Future<bool> _saveHistoryLimit(int newCount) async {
    final l10n = AppLocalizations.of(context);
    final currentCount = await _transfer.getCurrentHistoryCount();
    if (!mounted) return false;
    if (currentCount > newCount) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => TvChoiceDialog(
          title: l10n.confirmChange,
          message: l10n.historyDeleteWarning(
            currentCount,
            newCount,
            currentCount - newCount,
          ),
          primaryLabel: l10n.cancel,
          secondaryLabel: l10n.confirmChange,
          onPrimary: () => Navigator.of(dialogContext).pop(false),
          onSecondary: () => Navigator.of(dialogContext).pop(true),
        ),
      );
      if (confirmed != true) return false;
    }
    final result = await _transfer.saveMaxHistoryItems(newCount);
    return result.success;
  }

  Future<void> _editInt({
    required String title,
    required int value,
    required int min,
    required int max,
    required Future<bool> Function(int value) onSave,
  }) async {
    var current = value.clamp(min, max);
    final saved = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 16),
                    Text(
                      '$current',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TvButton(
                          label: '−',
                          onPressed: current <= min
                              ? null
                              : () => setDialog(() => current -= 1),
                        ),
                        const SizedBox(width: 12),
                        TvButton(
                          label: '+',
                          onPressed: current >= max
                              ? null
                              : () => setDialog(() => current += 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TvButton(
                      label: AppLocalizations.of(context).save,
                      primary: true,
                      autofocus: true,
                      onPressed: () => Navigator.of(dialogContext).pop(current),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (saved == null) return;
    await onSave(saved);
    if (mounted) await _load();
  }

  Future<void> _showAbout() async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.projectName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${l10n.appVersion} ${AppConstants.version}'),
                const SizedBox(height: 8),
                Text(AppConstants.author),
                const SizedBox(height: 20),
                TvButton(
                  label: l10n.close,
                  primary: true,
                  autofocus: true,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Setting {
  final String title;
  final String value;
  final VoidCallback onPressed;

  const _Setting(this.title, this.value, this.onPressed);
}

class _PairedDialog extends StatefulWidget {
  final VoidCallback onChanged;

  const _PairedDialog({required this.onChanged});

  @override
  State<_PairedDialog> createState() => _PairedDialogState();
}

class _PairedDialogState extends State<_PairedDialog> {
  List<PairedDevice> _devices = [];
  String _localId = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final devices = await PairedDeviceStore.instance.loadAll();
    final id = await IdentityService.instance.getDeviceId();
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _localId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.deviceCodeLabel,
                style: const TextStyle(fontSize: 14, color: HomeUi.inkMuted),
              ),
              const SizedBox(height: 4),
              ExcludeFocus(
                child: Text(_localId, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 12),
              TvButton(
                label: l10n.tvPairByCode,
                autofocus: true,
                onPressed: _busy ? null : _pair,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _devices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return TvRow(
                      title: device.deviceName,
                      subtitle: l10n.unpair,
                      onPressed: () => _unpair(device.deviceId),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TvButton(
                  label: l10n.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unpair(String deviceId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return TvChoiceDialog(
          title: l10n.unpair,
          message: deviceId,
          primaryLabel: l10n.cancel,
          secondaryLabel: l10n.confirm,
          onPrimary: () => Navigator.of(dialogContext).pop(false),
          onSecondary: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
    if (confirmed != true) return;
    await PairedDeviceStore.instance.remove(deviceId);
    widget.onChanged();
    await _load();
  }

  Future<void> _pair() async {
    final l10n = AppLocalizations.of(context);
    final code = await showTvTextPrompt(
      context,
      title: l10n.tvPairByCode,
      label: l10n.tvEnterDeviceCode,
    );
    if (code == null || code.isEmpty || !mounted) return;
    setState(() => _busy = true);
    final proposed = await RelayService.instance.pairing.request(code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!proposed.isSuccess) {
      await DialogHelper.showErrorDialog(
        context,
        title: l10n.pairingFailed,
        message: proposed.errorMessage ?? l10n.pairingFailed,
        confirmText: l10n.confirm,
      );
      return;
    }
    final proposal = proposed.data!;
    final agreed = await PairingConfirmDialog.showRelayOutgoing(
      context,
      peerDeviceName: proposal.peerDeviceName.isEmpty
          ? proposal.peerDeviceId
          : proposal.peerDeviceName,
      sas: proposal.sas,
      peerDecision: proposal.peerDecision,
    );
    if (!mounted || !agreed) return;
    widget.onChanged();
    await _load();
  }
}
