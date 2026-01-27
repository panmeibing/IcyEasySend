import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/http_server_manager.dart';
import '../services/preferences_service.dart';

/// Settings page for app configuration
class SettingsPage extends StatefulWidget {
  final HTTPServerManager serverManager;

  const SettingsPage({super.key, required this.serverManager});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final PreferencesService _preferencesService = PreferencesService();
  final TextEditingController _deviceNameController = TextEditingController();

  String _deviceName = '';
  String _deviceModel = '';
  String? _serverIP;
  String? _serverPort;
  bool _isLoading = true;
  bool _isEditingName = false;
  int _concurrentTransfers = 5;
  int _tempConcurrentTransfers = 5; // Temporary value for slider

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _loadServerInfo();
    _loadConcurrentTransfers();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
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

  /// Show confirmation dialog for concurrent transfers change
  Future<void> _confirmAndSaveConcurrentTransfers(int newCount) async {
    // If value hasn't changed, no need to confirm
    if (newCount == _concurrentTransfers) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings_suggest, color: Color(0xFF2196F3)),
            SizedBox(width: 12),
            Text('确认修改'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确定要将并发传输数量从 $_concurrentTransfers 修改为 $newCount 吗？',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      newCount > _concurrentTransfers
                          ? '增加并发数可能会提高传输速度，但也会增加设备负载'
                          : '降低并发数可以减少设备负载，但可能会降低传输速度',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: const Text('确认修改'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设备名'),
        content: Text('确定要将设备名重置为 "$_deviceModel" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('重置'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
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
                    icon: Icon(Icons.refresh, size: 20, color: Colors.grey[600]),
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
        border: Border.all(
          color: const Color(0xFFE53935),
          width: 1.5,
        ),
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
            child: const Icon(
              Icons.copy,
              size: 18,
              color: Color(0xFF2196F3),
            ),
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
                            '同时传输的文件数量（1-10）',
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
                    overlayColor: const Color(0xFF2196F3).withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _tempConcurrentTransfers.toDouble(),
                    min: 1,
                    max: 10,
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
          ],
        ),
      ),
    );
  }
}
