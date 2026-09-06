import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/http_server_manager.dart';
import '../services/language_service.dart';
import '../services/preferences_service.dart';
import '../services/transfer_history_service.dart';
import '../services/validation_service.dart';
import '../utils/constants.dart';
import '../utils/dialog_helper.dart';
import '../utils/toast_helper.dart';
import 'settings/controllers/developer_controller.dart';
import 'settings/controllers/device_controller.dart';
import 'settings/controllers/general_controller.dart';
import 'settings/controllers/transfer_controller.dart';
import 'settings/controllers/transfer_settings_actions.dart';
import 'settings/models/settings_state.dart';
import 'settings/widgets/about_card.dart';
import 'settings/widgets/developer_info_dialog.dart';
import 'settings/widgets/device_info_card.dart';
import 'settings/widgets/general_settings_card.dart';
import 'settings/widgets/language_dialog.dart';
import 'settings/widgets/paired_devices_card.dart';
import 'settings/widgets/relay_server_card.dart';
import 'settings/widgets/server_info_card.dart';
import 'settings/widgets/transfer_settings_card.dart';

/// Settings page for app configuration
class SettingsPage extends StatefulWidget {
  final HTTPServerManager serverManager;
  final LanguageService languageService;

  const SettingsPage({
    super.key,
    required this.serverManager,
    required this.languageService,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Services
  late final PreferencesService _preferencesService;
  late final TransferHistoryService _historyService;

  // Controllers
  late final DeviceController _deviceController;
  late final GeneralController _generalController;
  late final TransferController _transferController;
  late final DeveloperController _developerController;
  late final ValidationService _validationService;
  late final TransferSettingsActions _transferActions;

  // Text controllers
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _maxHistoryController = TextEditingController();
  final TextEditingController _maxClipboardSizeController =
      TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();

  // State
  late SettingsState _state;

  // Constants
  final int _allowMaxHisCount = AppConstants.allowMaxHistoryItems;
  final int _allowMinHisCount = AppConstants.allowMinHistoryItems;
  final int _maxConcurrentTransfers = AppConstants.maxConcurrentTransfers;

  @override
  void initState() {
    super.initState();

    // Initialize services
    _preferencesService = PreferencesService();
    _historyService = TransferHistoryService();

    // Initialize controllers
    _deviceController = DeviceController(_preferencesService);
    _generalController = GeneralController(
      languageService: widget.languageService,
    );
    _transferController = TransferController(
      _preferencesService,
      _historyService,
    );
    _developerController = DeveloperController();
    _validationService = ValidationService();
    _transferActions = TransferSettingsActions(
      transferController: _transferController,
      preferencesService: _preferencesService,
      validationService: _validationService,
      allowMinHisCount: _allowMinHisCount,
      allowMaxHisCount: _allowMaxHisCount,
      isMounted: () => mounted,
      getState: () => _state,
      updateState: (updater) {
        if (!mounted) return;
        setState(() {
          _state = updater(_state);
        });
      },
      onSuccess: _showSuccessSnackBar,
      onError: _showErrorSnackBar,
      onWarning: _showWarningSnackBar,
      onHistoryRefresh: () => widget.serverManager.refreshHistory(),
      reloadReceiveSavePath: _loadReceiveSavePath,
    );

    // Initialize state with default values
    _state = SettingsState(
      deviceName: '',
      deviceModel: '',
      concurrentTransfers: 5,
      tempConcurrentTransfers: 5,
      maxHistoryItems: AppConstants.defaultMaxHistoryItems,
      maxClipboardSizeMB: AppConstants.defaultMaxClipboardSize,
      enableIPValidation: true,
    );

    // Load all settings
    _loadAllSettings();

    // Register network change callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.serverManager.addNetworkChangeCallback(_onNetworkChanged);
      }
    });
  }

  @override
  void dispose() {
    widget.serverManager.removeNetworkChangeCallback(_onNetworkChanged);
    _deviceNameController.dispose();
    _maxHistoryController.dispose();
    _maxClipboardSizeController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  /// Handle network change event
  void _onNetworkChanged() {
    if (mounted) {
      _loadServerInfo();
    }
  }

  /// Load all settings
  Future<void> _loadAllSettings() async {
    await Future.wait<void>([
      _loadDeviceInfo(),
      _loadConcurrentTransfers(),
      _loadMaxHistoryItems(),
      _loadMaxClipboardSize(),
      _loadIPValidationEnabled(),
      _loadReceiveSavePath(),
      _loadDeviceSecretKey(),
      _loadClipboardOverlayEnabled(),
    ]);
    _loadServerInfo(); // This is synchronous
  }

  /// Load device information
  Future<void> _loadDeviceInfo() async {
    setState(() {
      _state = _state.copyWith(isLoading: true);
    });

    final deviceInfo = await _deviceController.loadDeviceInfo();
    final deviceModel = deviceInfo['model']!;
    final deviceName = deviceInfo['name']!;

    _deviceNameController.text = deviceName;

    if (mounted) {
      setState(() {
        _state = _state.copyWith(
          deviceModel: deviceModel,
          deviceName: deviceName,
          isLoading: false,
        );
      });
    }
  }

  /// Load server information
  void _loadServerInfo() {
    final serverAddress = widget.serverManager.getServerAddress();
    if (serverAddress != null) {
      final parts = serverAddress.split(':');
      if (parts.length == 2) {
        setState(() {
          _state = _state.copyWith(serverIP: parts[0], serverPort: parts[1]);
        });
      }
    }
  }

  /// Load concurrent transfers setting
  Future<void> _loadConcurrentTransfers() async {
    final count = await _transferController.loadConcurrentTransfers();
    if (mounted) {
      setState(() {
        _state = _state.copyWith(
          concurrentTransfers: count,
          tempConcurrentTransfers: count,
        );
      });
    }
  }

  /// Load max history items setting
  Future<void> _loadMaxHistoryItems() async {
    final count = await _transferController.loadMaxHistoryItems();
    if (mounted) {
      setState(() {
        _state = _state.copyWith(maxHistoryItems: count);
        _maxHistoryController.text = count.toString();
      });
    }
  }

  /// Load max clipboard size setting
  Future<void> _loadMaxClipboardSize() async {
    final sizeMB = await _transferController.loadMaxClipboardSize();
    if (mounted) {
      setState(() {
        _state = _state.copyWith(maxClipboardSizeMB: sizeMB);
        _maxClipboardSizeController.text = sizeMB.toString();
      });
    }
  }

  /// Load IP validation enabled state
  Future<void> _loadIPValidationEnabled() async {
    final enabled = await _transferController.loadIPValidationEnabled();
    if (mounted) {
      setState(() {
        _state = _state.copyWith(enableIPValidation: enabled);
      });
    }
  }

  /// Load receive save path display
  Future<void> _loadReceiveSavePath() async {
    final displayPath = await _transferController.getReceiveSavePathDisplay();
    final isCustom = await _transferController.hasCustomReceiveSavePath();
    if (mounted) {
      setState(() {
        _state = _state.copyWith(
          receiveSavePathDisplay: displayPath,
          isCustomReceiveSavePath: isCustom,
        );
      });
    }
  }

  /// Load device secret key
  Future<void> _loadDeviceSecretKey() async {
    final secretKey = await _preferencesService.getDeviceSecretKey();
    if (mounted) {
      setState(() {
        _state = _state.copyWith(deviceSecretKey: secretKey ?? '');
        _secretKeyController.text = secretKey ?? '';
      });
    }
  }

  Future<void> _loadClipboardOverlayEnabled() async {
    if (!Platform.isAndroid) return;
    final enabled = await _preferencesService.getClipboardOverlayEnabled();
    if (mounted) {
      setState(() {
        _state = _state.copyWith(clipboardOverlayEnabled: enabled);
      });
    }
  }

  // ========== Device Info Actions ==========

  /// Save device name
  Future<void> _saveDeviceName() async {
    final l10n = AppLocalizations.of(context);
    final newName = _deviceNameController.text.trim();
    if (newName.isEmpty) {
      _showErrorSnackBar(l10n.deviceNameCannotBeEmpty);
      return;
    }

    final success = await _deviceController.saveDeviceName(newName);
    if (success) {
      setState(() {
        _state = _state.copyWith(deviceName: newName, isEditingName: false);
      });
      _showSuccessSnackBar(l10n.deviceNameSaved);
    } else {
      _showErrorSnackBar(l10n.saveFailed);
    }
  }

  /// Reset device name to model
  Future<void> _resetDeviceName() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: l10n.resetDeviceName,
      message: l10n.resetDeviceNameConfirm(_state.deviceModel),
      confirmText: l10n.reset,
      cancelText: l10n.cancel,
      icon: Icons.refresh,
      iconColor: Colors.orange,
    );

    if (confirmed) {
      _deviceNameController.text = _state.deviceModel;
      await _saveDeviceName();
    }
  }

  // ========== Developer Mode Actions ==========

  /// Handle version tap for developer mode
  void _handleVersionTap() {
    final now = DateTime.now();

    // Reset counter if more than 2 seconds since last tap
    if (_state.lastVersionTapTime != null &&
        now.difference(_state.lastVersionTapTime!).inSeconds > 2) {
      setState(() {
        _state = _state.copyWith(versionTapCount: 0);
      });
    }

    setState(() {
      _state = _state.copyWith(
        lastVersionTapTime: now,
        versionTapCount: _state.versionTapCount + 1,
      );
    });

    if (_state.versionTapCount >= 5) {
      setState(() {
        _state = _state.copyWith(versionTapCount: 0);
      });
      DeveloperInfoDialog.show(
        context,
        developerController: _developerController,
      );
    }
  }

  // ========== Helper Methods ==========

  /// Copy text to clipboard
  Future<void> _copyToClipboard(String text, String label) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    _showSuccessSnackBar(l10n.labelCopied(label, text));
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ToastHelper.showSuccess(context, message);
    }
  }

  void _showWarningSnackBar(String message) {
    if (mounted) {
      ToastHelper.showWarning(context, message);
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ToastHelper.showError(context, message);
    }
  }

  // ========== Build Methods ==========

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: _state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DeviceInfoCard(
                      deviceName: _state.deviceName,
                      deviceModel: _state.deviceModel,
                      isEditingName: _state.isEditingName,
                      deviceNameController: _deviceNameController,
                      onEditPressed: () {
                        setState(() {
                          _state = _state.copyWith(isEditingName: true);
                        });
                      },
                      onSavePressed: _saveDeviceName,
                      onCancelPressed: () {
                        setState(() {
                          _deviceNameController.text = _state.deviceName;
                          _state = _state.copyWith(isEditingName: false);
                        });
                      },
                      onResetPressed: _resetDeviceName,
                    ),
                    const SizedBox(height: 16),
                    GeneralSettingsCard(
                      currentLanguage: _generalController
                          .getCurrentLanguageCode(),
                      onLanguageTap: () => LanguageDialog.show(
                        context,
                        generalController: _generalController,
                        onSuccess: _showSuccessSnackBar,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Relay first: users configure the server, then pair over it.
                    const RelayServerCard(),
                    const SizedBox(height: 16),
                    const PairedDevicesCard(),
                    const SizedBox(height: 16),
                    ServerInfoCard(
                      isServerRunning: widget.serverManager.isRunning(),
                      serverIP: _state.serverIP,
                      serverPort: _state.serverPort,
                      onCopy: _copyToClipboard,
                    ),
                    const SizedBox(height: 16),
                    TransferSettingsCard(
                      receiveSavePathDisplay: _state.receiveSavePathDisplay,
                      isCustomReceiveSavePath: _state.isCustomReceiveSavePath,
                      onSelectSavePath: () =>
                          _transferActions.pickReceiveSavePath(context),
                      onResetSavePathToDefault: () => _transferActions
                          .resetReceiveSavePathToDefault(context),
                      concurrentTransfers: _state.concurrentTransfers,
                      tempConcurrentTransfers: _state.tempConcurrentTransfers,
                      maxConcurrentTransfers: _maxConcurrentTransfers,
                      onConcurrentTransfersChanged: (value) {
                        setState(() {
                          _state = _state.copyWith(
                            tempConcurrentTransfers: value,
                          );
                        });
                      },
                      onConcurrentTransfersChangeEnd: (value) =>
                          _transferActions.confirmAndSaveConcurrentTransfers(
                            context,
                            value,
                          ),
                      maxHistoryItems: _state.maxHistoryItems,
                      isEditingMaxHistory: _state.isEditingMaxHistory,
                      allowMaxHisCount: _allowMaxHisCount,
                      allowMinHisCount: _allowMinHisCount,
                      maxHistoryController: _maxHistoryController,
                      onEditMaxHistory: () {
                        setState(() {
                          _state = _state.copyWith(isEditingMaxHistory: true);
                        });
                      },
                      onSaveMaxHistory: () =>
                          _transferActions.confirmAndSaveMaxHistoryItems(
                            context,
                            maxHistoryController: _maxHistoryController,
                          ),
                      onCancelMaxHistory: () {
                        setState(() {
                          _maxHistoryController.text = _state.maxHistoryItems
                              .toString();
                          _state = _state.copyWith(isEditingMaxHistory: false);
                        });
                      },
                      maxClipboardSizeMB: _state.maxClipboardSizeMB,
                      isEditingMaxClipboardSize:
                          _state.isEditingMaxClipboardSize,
                      maxClipboardSizeController: _maxClipboardSizeController,
                      onEditMaxClipboardSize: () {
                        setState(() {
                          _state = _state.copyWith(
                            isEditingMaxClipboardSize: true,
                          );
                        });
                      },
                      onSaveMaxClipboardSize: () =>
                          _transferActions.confirmAndSaveMaxClipboardSize(
                            context,
                            maxClipboardSizeController:
                                _maxClipboardSizeController,
                          ),
                      onCancelMaxClipboardSize: () {
                        setState(() {
                          _maxClipboardSizeController.text = _state
                              .maxClipboardSizeMB
                              .toString();
                          _state = _state.copyWith(
                            isEditingMaxClipboardSize: false,
                          );
                        });
                      },
                      clipboardOverlayEnabled: _state.clipboardOverlayEnabled,
                      onClipboardOverlayChanged: Platform.isAndroid
                          ? (enabled) => _transferActions
                              .onClipboardOverlayChanged(context, enabled)
                          : null,
                      enableIPValidation: _state.enableIPValidation,
                      onIPValidationChanged: (enabled) => _transferActions
                          .saveIPValidationEnabled(context, enabled),
                      deviceSecretKey: _state.deviceSecretKey,
                      isEditingSecretKey: _state.isEditingSecretKey,
                      secretKeyController: _secretKeyController,
                      onEditSecretKey: () {
                        setState(() {
                          _state = _state.copyWith(isEditingSecretKey: true);
                        });
                      },
                      onSaveSecretKey: () =>
                          _transferActions.saveDeviceSecretKey(
                            context,
                            secretKeyController: _secretKeyController,
                          ),
                      onCancelSecretKey: () {
                        setState(() {
                          _secretKeyController.text = _state.deviceSecretKey;
                          _state = _state.copyWith(isEditingSecretKey: false);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    AboutCard(onVersionTap: _handleVersionTap),
                  ],
                ),
              ),
            ),
    );
  }
}
