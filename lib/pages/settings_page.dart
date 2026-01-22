import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
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
      });
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
        centerTitle: true,
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  '设备信息',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

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
                      const SizedBox(height: 4),
                      if (_isEditingName)
                        TextField(
                          controller: _deviceNameController,
                          decoration: const InputDecoration(
                            hintText: '输入设备名',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
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
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_isEditingName) ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: _saveDeviceName,
                    tooltip: '保存',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
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
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      setState(() {
                        _isEditingName = true;
                      });
                    },
                    tooltip: '编辑',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _resetDeviceName,
                    tooltip: '重置为设备型号',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

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
                const SizedBox(height: 4),
                Text(
                  _deviceModel,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
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

    return Card(
      elevation: 2,
      color: isServerRunning ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isServerRunning ? Icons.wifi : Icons.wifi_off,
                  color: isServerRunning ? Colors.green[700] : Colors.red[700],
                ),
                const SizedBox(width: 8),
                Text(
                  '服务器信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isServerRunning
                        ? Colors.green[900]
                        : Colors.red[900],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (isServerRunning &&
                _serverIP != null &&
                _serverPort != null) ...[
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
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 8),
                    Text(
                      '服务器未运行',
                      style: TextStyle(fontSize: 16, color: Colors.red[700]),
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
        const SizedBox(width: 8),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: onCopy,
          tooltip: '复制',
          color: Colors.blue,
        ),
      ],
    );
  }

  /// Build transfer settings card
  Widget _buildTransferSettingsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_suggest, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  '传输设置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

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
                          Text(
                            '并发传输数量',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
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
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Text(
                        '$_concurrentTransfers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _concurrentTransfers.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$_concurrentTransfers',
                        onChanged: (value) {
                          setState(() {
                            _concurrentTransfers = value.toInt();
                          });
                        },
                        onChangeEnd: (value) {
                          _saveConcurrentTransfers(value.toInt());
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '较高的并发数可以更好地利用带宽，但可能增加设备负载',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[900],
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
