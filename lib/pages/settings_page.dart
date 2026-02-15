import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/http_server_manager.dart';
import '../services/preferences_service.dart';
import '../services/transfer_history_service.dart';
import '../utils/constants.dart';
import '../utils/dialog_helper.dart';
import '../utils/toast_helper.dart';

/// Settings page for app configuration
class SettingsPage extends StatefulWidget {
  final HTTPServerManager serverManager;

  const SettingsPage({super.key, required this.serverManager});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final PreferencesService _preferencesService;
  late final TransferHistoryService _historyService;
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _maxHistoryController = TextEditingController();
  final TextEditingController _maxClipboardSizeController =
      TextEditingController();

  String _deviceName = '';
  String _deviceModel = '';
  String? _serverIP;
  String? _serverPort;
  bool _isLoading = true;
  bool _isEditingName = false;
  int _concurrentTransfers = 5;
  int _tempConcurrentTransfers = 5; // Temporary value for slider
  int _maxHistoryItems = AppConstants.defaultMaxHistoryItems;
  bool _isEditingMaxHistory = false;
  int _maxClipboardSizeMB = AppConstants.defaultMaxClipboardSize;
  bool _isEditingMaxClipboardSize = false;

  final int _allowMaxHisCount = AppConstants.allowMaxHistoryItems;
  final int _allowMinHisCount = AppConstants.allowMinHistoryItems;
  final int _maxConcurrentTransfers = AppConstants.maxConcurrentTransfers;

  @override
  void initState() {
    super.initState();

    // Initialize services (can be overridden for testing)
    _preferencesService = PreferencesService();
    _historyService = TransferHistoryService();

    _loadDeviceInfo();
    _loadServerInfo();
    _loadConcurrentTransfers();
    _loadMaxHistoryItems();
    _loadMaxClipboardSize();

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
    super.dispose();
  }

  /// Handle network change event
  void _onNetworkChanged() {
    if (mounted) {
      _loadServerInfo();
    }
  }

  /// Load device information
  Future<void> _loadDeviceInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get device model
      final deviceInfo = DeviceInfoPlugin();
      String model = 'Unknown Device';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        model = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        model = iosInfo.model;
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        model = macInfo.model;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        model = windowsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        model = linuxInfo.name;
      }

      _deviceModel = model;

      // Load saved device name or use model as default
      final savedName = await _preferencesService.getDeviceName();
      _deviceName = savedName ?? model;
      _deviceNameController.text = _deviceName;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _deviceModel = 'Unknown Device';
        _deviceName = 'Unknown Device';
        _deviceNameController.text = _deviceName;
        _isLoading = false;
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
          _serverIP = parts[0];
          _serverPort = parts[1];
        });
      }
    }
  }

  /// Load concurrent transfers setting
  Future<void> _loadConcurrentTransfers() async {
    final count = await _preferencesService.getConcurrentTransfers();
    if (mounted) {
      setState(() {
        _concurrentTransfers = count;
        _tempConcurrentTransfers = count; // Initialize temp value
      });
    }
  }

  /// Load max history items setting
  Future<void> _loadMaxHistoryItems() async {
    final count = await _preferencesService.getMaxHistoryItems();
    if (mounted) {
      setState(() {
        _maxHistoryItems = count;
        _maxHistoryController.text = count.toString();
      });
    }
  }

  /// Load max clipboard size setting
  Future<void> _loadMaxClipboardSize() async {
    final sizeMB = await _preferencesService.getMaxClipboardSize();
    if (mounted) {
      setState(() {
        _maxClipboardSizeMB = sizeMB;
        _maxClipboardSizeController.text = sizeMB.toString();
      });
    }
  }

  /// Show confirmation dialog for concurrent transfers change
  Future<void> _confirmAndSaveConcurrentTransfers(int newCount) async {
    // If value hasn't changed, no need to confirm
    if (newCount == _concurrentTransfers) {
      return;
    }

    final additionalInfo = newCount > _concurrentTransfers
        ? '增加并发数可能会提高传输速度，但也会增加设备负载'
        : '降低并发数可以减少设备负载，但可能会降低传输速度';

    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: '确认修改',
      message:
          '确定要将并发传输数量从 $_concurrentTransfers 修改为 $newCount 吗？\n\n提示：$additionalInfo',
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
          _tempConcurrentTransfers = _concurrentTransfers;
        });
      }
    }
  }

  /// Save concurrent transfers setting
  Future<void> _saveConcurrentTransfers(int count) async {
    final success = await _preferencesService.saveConcurrentTransfers(count);
    if (success) {
      setState(() {
        _concurrentTransfers = count;
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
    if (newCount == _maxHistoryItems) {
      setState(() {
        _isEditingMaxHistory = false;
      });
      return;
    }

    // Get current history count
    final history = await _historyService.loadHistory();
    final currentCount = history.length;

    // Build confirmation message
    String message = '确定要将最大历史记录数从 $_maxHistoryItems 修改为 $newCount 吗？\n\n';
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
          _maxHistoryController.text = _maxHistoryItems.toString();
          _isEditingMaxHistory = false;
        });
      }
    }
  }

  /// Save max history items setting
  Future<void> _saveMaxHistoryItems(int newCount, int currentCount) async {
    final success = await _preferencesService.saveMaxHistoryItems(newCount);
    if (success) {
      setState(() {
        _maxHistoryItems = newCount;
        _isEditingMaxHistory = false;
      });

      // If current count exceeds new limit, trim the history
      if (currentCount > newCount) {
        final deletedCount = await _historyService.trimHistory(newCount);
        if (deletedCount > 0) {
          _showSuccessSnackBar('设置已保存，已删除 $deletedCount 条旧记录');
          // Trigger history refresh
          widget.serverManager.refreshHistory();
        } else {
          _showSuccessSnackBar('最大历史记录数已保存');
        }
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
    if (newSize == _maxClipboardSizeMB) {
      setState(() {
        _isEditingMaxClipboardSize = false;
      });
      return;
    }

    // Build confirmation message
    String message =
        '确定要将最大剪切板大小从 $_maxClipboardSizeMB MB 修改为 $newSize MB 吗？\n\n';

    if (newSize < _maxClipboardSizeMB) {
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
          _maxClipboardSizeController.text = _maxClipboardSizeMB.toString();
          _isEditingMaxClipboardSize = false;
        });
      }
    }
  }

  /// Save max clipboard size setting
  Future<void> _saveMaxClipboardSize(int newSize) async {
    final success = await _preferencesService.saveMaxClipboardSize(newSize);
    if (success) {
      setState(() {
        _maxClipboardSizeMB = newSize;
        _isEditingMaxClipboardSize = false;
      });
      _showSuccessSnackBar('最大剪切板大小已保存');
    } else {
      _showErrorSnackBar('保存失败');
    }
  }

  /// Save device name
  Future<void> _saveDeviceName() async {
    final newName = _deviceNameController.text.trim();
    if (newName.isEmpty) {
      _showErrorSnackBar('设备名不能为空');
      return;
    }

    final success = await _preferencesService.saveDeviceName(newName);
    if (success) {
      setState(() {
        _deviceName = newName;
        _isEditingName = false;
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
      message: '确定要将设备名重置为 "$_deviceModel" 吗？',
      confirmText: '重置',
      icon: Icons.refresh,
      iconColor: Colors.orange,
    );

    if (confirmed) {
      _deviceNameController.text = _deviceModel;
      await _saveDeviceName();
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDeviceInfoCard(),
                    const SizedBox(height: 16),
                    _buildServerInfoCard(),
                    const SizedBox(height: 16),
                    _buildTransferSettingsCard(),
                    const SizedBox(height: 16),
                    _buildAboutCard(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build device information card
  Widget _buildDeviceInfoCard() {
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
                    Icons.phone_android,
                    color: Color(0xFF2196F3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '设备信息',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Device Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '设备名',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isEditingName)
                        TextField(
                          controller: _deviceNameController,
                          decoration: const InputDecoration(
                            hintText: '输入设备名',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          autofocus: true,
                        )
                      else
                        Text(
                          _deviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_isEditingName) ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                    onPressed: _saveDeviceName,
                    tooltip: '保存',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                    onPressed: () {
                      setState(() {
                        _deviceNameController.text = _deviceName;
                        _isEditingName = false;
                      });
                    },
                    tooltip: '取消',
                  ),
                ] else ...[
                  IconButton(
                    icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                    onPressed: () {
                      setState(() {
                        _isEditingName = true;
                      });
                    },
                    tooltip: '编辑',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    onPressed: _resetDeviceName,
                    tooltip: '重置为设备型号',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Device Model
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '设备型号',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _deviceModel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF616161),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build server information card
  Widget _buildServerInfoCard() {
    final isServerRunning = widget.serverManager.isRunning();

    // When server is running, use Card with white background (consistent with other cards)
    if (isServerRunning) {
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
                      Icons.wifi,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '服务器信息',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_serverIP != null && _serverPort != null) ...[
                // Server IP
                _buildInfoRow(
                  label: '服务器 IP',
                  value: _serverIP!,
                  icon: Icons.computer,
                  onCopy: () => _copyToClipboard(_serverIP!, 'IP地址'),
                ),
                const SizedBox(height: 16),

                // Server Port
                _buildInfoRow(
                  label: '端口',
                  value: _serverPort!,
                  icon: Icons.settings_ethernet,
                  onCopy: () => _copyToClipboard(_serverPort!, '端口'),
                ),
                const SizedBox(height: 16),

                // Server status indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '服务器运行正常',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // When server is not running, use red background Container
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE53935), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.wifi_off,
                  color: Color(0xFFC62828),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '服务器信息',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC62828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: const Color(0xFFE53935).withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  '服务器未运行',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFC62828),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build information row with copy button
  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onCopy,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.copy, size: 18, color: Color(0xFF2196F3)),
          ),
        ),
      ],
    );
  }

  /// Build transfer settings card
  Widget _buildTransferSettingsCard() {
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
                const Text(
                  '传输设置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Concurrent transfers setting
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '并发传输数量',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF212121),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '同时传输的文件数量（1-$_maxConcurrentTransfers）',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
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
                        '$_tempConcurrentTransfers',
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
                    overlayColor: const Color(
                      0xFF2196F3,
                    ).withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _tempConcurrentTransfers.toDouble(),
                    min: 1,
                    max: _maxConcurrentTransfers.toDouble(),
                    divisions: 9,
                    label: '$_tempConcurrentTransfers',
                    onChanged: (value) {
                      setState(() {
                        _tempConcurrentTransfers = value.toInt();
                      });
                    },
                    onChangeEnd: (value) {
                      _confirmAndSaveConcurrentTransfers(value.toInt());
                    },
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
                          '较高的并发数可以更好地利用带宽，但可能增加设备负载',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 24),

            // Max history items setting
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '最大历史记录数',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF212121),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '保存的最大传输记录数量（$_allowMinHisCount-$_allowMaxHisCount}）',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isEditingMaxHistory)
                            TextField(
                              controller: _maxHistoryController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                hintText:
                                    '输入数量 ($_allowMinHisCount-$_allowMaxHisCount)',
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
                                    '$_maxHistoryItems 条',
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
                    if (_isEditingMaxHistory) ...[
                      IconButton(
                        icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                        onPressed: _confirmAndSaveMaxHistoryItems,
                        tooltip: '保存',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                        onPressed: () {
                          setState(() {
                            _maxHistoryController.text = _maxHistoryItems
                                .toString();
                            _isEditingMaxHistory = false;
                          });
                        },
                        tooltip: '取消',
                      ),
                    ] else ...[
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _isEditingMaxHistory = true;
                          });
                        },
                        tooltip: '编辑',
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
                          '超过设置数量的旧记录将被自动删除，只保留最新的记录',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 24),

            // Max clipboard size setting
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '最大剪切板大小',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF212121),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '允许同步的最大剪切板大小（${AppConstants.minClipboardSizeMB}-${AppConstants.maxClipboardSizeMB} MB）',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isEditingMaxClipboardSize)
                            TextField(
                              controller: _maxClipboardSizeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                hintText:
                                    '输入大小 (${AppConstants.minClipboardSizeMB}-${AppConstants.maxClipboardSizeMB} MB)',
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
                                    '$_maxClipboardSizeMB MB',
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
                    if (_isEditingMaxClipboardSize) ...[
                      IconButton(
                        icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                        onPressed: _confirmAndSaveMaxClipboardSize,
                        tooltip: '保存',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                        onPressed: () {
                          setState(() {
                            _maxClipboardSizeController.text =
                                _maxClipboardSizeMB.toString();
                            _isEditingMaxClipboardSize = false;
                          });
                        },
                        tooltip: '取消',
                      ),
                    ] else ...[
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _isEditingMaxClipboardSize = true;
                          });
                        },
                        tooltip: '编辑',
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
                          '超过此大小的剪切板内容将无法同步，建议使用文件传输功能',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build about card
  Widget _buildAboutCard() {
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
                    Icons.info_outline,
                    color: Color(0xFF2196F3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '关于',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // App icon and info
            Row(
              children: [
                // App icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'lib/images/icon.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // App info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.projectName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.update, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            "版本: ",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            AppConstants.version,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "作者: ",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            AppConstants.author,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '一个简单易用的局域网文件传输工具',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
