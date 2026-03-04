import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/http_server_manager.dart';
import '../services/preferences_service.dart';
import '../services/transfer_history_service.dart';
import '../utils/constants.dart';
import '../utils/dialog_helper.dart';
import '../utils/platform_util.dart';
import '../utils/toast_helper.dart';
import 'settings/controllers/developer_controller.dart';
import 'settings/controllers/device_controller.dart';
import 'settings/controllers/transfer_controller.dart';
import 'settings/models/settings_state.dart';
import 'settings/widgets/about_card.dart';
import 'settings/widgets/device_info_card.dart';
import 'settings/widgets/server_info_card.dart';
import 'settings/widgets/transfer_settings_card.dart';

/// Settings page for app configuration
class SettingsPage extends StatefulWidget {
  final HTTPServerManager serverManager;

  const SettingsPage({super.key, required this.serverManager});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Services
  late final PreferencesService _preferencesService;
  late final TransferHistoryService _historyService;

  // Controllers
  late final DeviceController _deviceController;
  late final TransferController _transferController;
  late final DeveloperController _developerController;

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
    _transferController = TransferController(
      _preferencesService,
      _historyService,
    );
    _developerController = DeveloperController();

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
      _loadDeviceSecretKey(),
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

  // ========== Device Info Actions ==========

  /// Save device name
  Future<void> _saveDeviceName() async {
    final newName = _deviceNameController.text.trim();
    if (newName.isEmpty) {
      _showErrorSnackBar('设备名不能为空');
      return;
    }

    final success = await _deviceController.saveDeviceName(newName);
    if (success) {
      setState(() {
        _state = _state.copyWith(deviceName: newName, isEditingName: false);
      });
      _showSuccessSnackBar('设备名已保存');
    } else {
      _showErrorSnackBar('保存失败');
    }
  }

  /// Reset device name to model
  Future<void> _resetDeviceName() async {
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: '重置设备名',
      message: '确定要将设备名重置为 "${_state.deviceModel}" 吗？',
      confirmText: '重置',
      icon: Icons.refresh,
      iconColor: Colors.orange,
    );

    if (confirmed) {
      _deviceNameController.text = _state.deviceModel;
      await _saveDeviceName();
    }
  }

  // ========== Transfer Settings Actions ==========

  /// Show confirmation dialog for concurrent transfers change
  Future<void> _confirmAndSaveConcurrentTransfers(int newCount) async {
    // If value hasn't changed, no need to confirm
    if (newCount == _state.concurrentTransfers) {
      return;
    }

    final additionalInfo = newCount > _state.concurrentTransfers
        ? '增加并发数可能会提高传输速度，但也会增加设备负载'
        : '降低并发数可以减少设备负载，但可能会降低传输速度';

    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: '确认修改',
      message:
          '确定要将并发传输数量从 ${_state.concurrentTransfers} 修改为 $newCount 吗？\n\n提示：$additionalInfo',
      confirmText: '确认修改',
      icon: Icons.settings_suggest,
      iconColor: const Color(0xFF2196F3),
    );

    if (confirmed) {
      await _saveConcurrentTransfers(newCount);
    } else {
      // User cancelled, revert to previous value
      if (mounted) {
        setState(() {
          _state = _state.copyWith(
            tempConcurrentTransfers: _state.concurrentTransfers,
          );
        });
      }
    }
  }

  /// Save concurrent transfers setting
  Future<void> _saveConcurrentTransfers(int count) async {
    final success = await _transferController.saveConcurrentTransfers(count);
    if (success) {
      setState(() {
        _state = _state.copyWith(concurrentTransfers: count);
      });
      _showSuccessSnackBar('并发传输数量已保存');
    } else {
      _showErrorSnackBar('保存失败');
    }
  }

  /// Confirm and save max history items
  Future<void> _confirmAndSaveMaxHistoryItems() async {
    final newCountText = _maxHistoryController.text.trim();
    if (newCountText.isEmpty) {
      _showErrorSnackBar('请输入有效的数字');
      return;
    }

    final newCount = int.tryParse(newCountText);
    if (newCount == null) {
      _showErrorSnackBar('请输入有效的数字');
      return;
    }

    if (newCount < _allowMinHisCount || newCount > _allowMaxHisCount) {
      _showErrorSnackBar('历史记录数量范围: $_allowMinHisCount-$_allowMaxHisCount');
      return;
    }

    // If value hasn't changed, no need to confirm
    if (newCount == _state.maxHistoryItems) {
      setState(() {
        _state = _state.copyWith(isEditingMaxHistory: false);
      });
      return;
    }

    // Get current history count
    final currentCount = await _transferController.getCurrentHistoryCount();

    // Build confirmation message
    String message =
        '确定要将最大历史记录数从 ${_state.maxHistoryItems} 修改为 $newCount 吗？\n\n';
    message += '当前历史记录数: $currentCount 条\n\n';

    if (currentCount > newCount) {
      final deleteCount = currentCount - newCount;
      message += '⚠️ 警告：当前保存的历史记录数 ($currentCount) 大于设置的数量 ($newCount)。\n\n';
      message += '只会保留最新的 $newCount 条记录，超过的 $deleteCount 条旧记录将被删除。';
    } else {
      message += '提示：新的设置将在下次保存历史记录时生效。';
    }

    if (!mounted) return;

    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: '确认修改',
      message: message,
      confirmText: '确认修改',
      icon: Icons.history,
      iconColor: const Color(0xFF2196F3),
    );

    if (confirmed) {
      await _saveMaxHistoryItems(newCount, currentCount);
    } else {
      // User cancelled, revert to previous value
      if (mounted) {
        setState(() {
          _maxHistoryController.text = _state.maxHistoryItems.toString();
          _state = _state.copyWith(isEditingMaxHistory: false);
        });
      }
    }
  }

  /// Save max history items setting
  Future<void> _saveMaxHistoryItems(int newCount, int currentCount) async {
    final result = await _transferController.saveMaxHistoryItems(
      newCount,
      currentCount,
    );

    if (result['success']) {
      setState(() {
        _state = _state.copyWith(
          maxHistoryItems: newCount,
          isEditingMaxHistory: false,
        );
      });

      final deletedCount = result['deletedCount'] as int;
      if (deletedCount > 0) {
        _showSuccessSnackBar('设置已保存，已删除 $deletedCount 条旧记录');
        // Trigger history refresh
        widget.serverManager.refreshHistory();
      } else {
        _showSuccessSnackBar('最大历史记录数已保存');
      }
    } else {
      _showErrorSnackBar('保存失败');
    }
  }

  /// Confirm and save max clipboard size
  Future<void> _confirmAndSaveMaxClipboardSize() async {
    final newSizeText = _maxClipboardSizeController.text.trim();
    if (newSizeText.isEmpty) {
      _showErrorSnackBar('请输入有效的数字');
      return;
    }

    final newSize = int.tryParse(newSizeText);
    if (newSize == null) {
      _showErrorSnackBar('请输入有效的数字');
      return;
    }

    if (newSize < AppConstants.minClipboardSizeMB ||
        newSize > AppConstants.maxClipboardSizeMB) {
      _showErrorSnackBar(
        '剪切板大小范围: ${AppConstants.minClipboardSizeMB}-${AppConstants.maxClipboardSizeMB} MB',
      );
      return;
    }

    // If value hasn't changed, no need to confirm
    if (newSize == _state.maxClipboardSizeMB) {
      setState(() {
        _state = _state.copyWith(isEditingMaxClipboardSize: false);
      });
      return;
    }

    // Build confirmation message
    String message =
        '确定要将最大剪切板大小从 ${_state.maxClipboardSizeMB} MB 修改为 $newSize MB 吗？\n\n';

    if (newSize < _state.maxClipboardSizeMB) {
      message += '⚠️ 提示：降低限制后，超过 $newSize MB 的剪切板内容将无法同步，建议使用文件传输功能。';
    } else {
      message += '提示：增加限制后，可以同步更大的剪切板内容，但可能会影响传输速度。';
    }

    if (!mounted) return;

    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: '确认修改',
      message: message,
      confirmText: '确认修改',
      icon: Icons.content_paste,
      iconColor: const Color(0xFF2196F3),
    );

    if (confirmed) {
      await _saveMaxClipboardSize(newSize);
    } else {
      // User cancelled, revert to previous value
      if (mounted) {
        setState(() {
          _maxClipboardSizeController.text = _state.maxClipboardSizeMB
              .toString();
          _state = _state.copyWith(isEditingMaxClipboardSize: false);
        });
      }
    }
  }

  /// Save max clipboard size setting
  Future<void> _saveMaxClipboardSize(int newSize) async {
    final success = await _transferController.saveMaxClipboardSize(newSize);
    if (success) {
      setState(() {
        _state = _state.copyWith(
          maxClipboardSizeMB: newSize,
          isEditingMaxClipboardSize: false,
        );
      });
      _showSuccessSnackBar('最大剪切板大小已保存');
    } else {
      _showErrorSnackBar('保存失败');
    }
  }

  /// Save IP validation enabled state
  Future<void> _saveIPValidationEnabled(bool enabled) async {
    final success = await _transferController.saveIPValidationEnabled(enabled);
    if (success) {
      setState(() {
        _state = _state.copyWith(enableIPValidation: enabled);
      });
      _showSuccessSnackBar(enabled ? 'IP地址校验已启用' : 'IP地址校验已禁用');
    } else {
      _showErrorSnackBar('保存失败');
    }
  }

  /// Save device secret key
  Future<void> _saveDeviceSecretKey() async {
    final newKey = _secretKeyController.text.trim();

    final success = await _preferencesService.saveDeviceSecretKey(newKey);
    if (success) {
      setState(() {
        _state = _state.copyWith(
          deviceSecretKey: newKey,
          isEditingSecretKey: false,
        );
      });
      if (newKey.isEmpty) {
        _showSuccessSnackBar('设备秘钥已清空');
      } else {
        _showSuccessSnackBar('设备秘钥已保存');
      }
    } else {
      _showErrorSnackBar('保存失败');
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
      _showDeveloperInfo();
    }
  }

  /// Show developer information dialog
  Future<void> _showDeveloperInfo() async {
    // Show loading dialog
    if (!mounted) return;
    DialogHelper.showLoadingDialog(context, message: '正在加载开发信息...');

    try {
      // Get developer info
      final devInfo = await _developerController.getDeveloperInfo();
      final logPath = await PlatformUtil.getLoggerFilePath();

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show developer info dialog
      await DialogHelper.showCustomDialog(
        context,
        title: const Row(
          children: [
            Icon(Icons.developer_mode, color: Colors.orange),
            SizedBox(width: 8),
            Text('开发信息'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                devInfo,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _copyLogContent(logPath),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('复制日志'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: devInfo));
              ToastHelper.showSuccess(context, '开发信息已复制到剪贴板');
            },
            child: const Text('复制'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('关闭'),
          ),
        ],
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ToastHelper.showError(context, '加载开发信息时出错: $e');
      }
    }
  }

  /// Copy log content
  Future<void> _copyLogContent(String logPath) async {
    final result = await _developerController.copyLogContent(logPath);

    if (!mounted) return;

    if (result['success']) {
      await Clipboard.setData(ClipboardData(text: result['content']));
      if (!mounted) return;
      ToastHelper.showSuccess(context, '已复制最后${result['lineCount']}行日志到剪贴板');
    } else {
      final message = result['message'] as String;
      if (message == '日志文件为空') {
        ToastHelper.showWarning(context, message);
      } else {
        ToastHelper.showError(context, message);
      }
    }
  }

  // ========== Helper Methods ==========

  /// Copy text to clipboard
  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSuccessSnackBar('$label已复制: $text');
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ToastHelper.showSuccess(context, message);
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
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
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
                    ServerInfoCard(
                      isServerRunning: widget.serverManager.isRunning(),
                      serverIP: _state.serverIP,
                      serverPort: _state.serverPort,
                      onCopy: _copyToClipboard,
                    ),
                    const SizedBox(height: 16),
                    TransferSettingsCard(
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
                      onConcurrentTransfersChangeEnd:
                          _confirmAndSaveConcurrentTransfers,
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
                      onSaveMaxHistory: _confirmAndSaveMaxHistoryItems,
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
                      onSaveMaxClipboardSize: _confirmAndSaveMaxClipboardSize,
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
                      enableIPValidation: _state.enableIPValidation,
                      onIPValidationChanged: _saveIPValidationEnabled,
                      deviceSecretKey: _state.deviceSecretKey,
                      isEditingSecretKey: _state.isEditingSecretKey,
                      secretKeyController: _secretKeyController,
                      onEditSecretKey: () {
                        setState(() {
                          _state = _state.copyWith(isEditingSecretKey: true);
                        });
                      },
                      onSaveSecretKey: _saveDeviceSecretKey,
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
