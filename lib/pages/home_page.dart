import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icy_easy_send/utils/log_util.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../services/file_transfer_service.dart';
import '../services/http_server_manager.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/preferences_service.dart';
import '../services/validation_service.dart';
import '../utils/constants.dart';
import '../utils/error_messages.dart';
import '../utils/network_diagnostics.dart';

/// HomePage is the main UI for the icy-easy-send application
///
/// It provides:
/// - IP address input for target device
/// - File selection functionality
/// - Send button to initiate file transfer
/// - Server status indicator
class HomePage extends StatefulWidget {
  final HTTPServerManager serverManager;

  const HomePage({super.key, required this.serverManager});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variables as defined in the design document
  String targetIP = '';
  List<File> selectedFiles = []; // Changed from single file to list of files
  bool isServerRunning = false;
  String? serverAddress;
  bool isSending = false;

  // Progress tracking
  double _transferProgress = 0.0;
  int _bytesTransferred = 0;
  int _totalBytes = 0;
  DateTime? _transferStartTime;
  double _transferSpeed = 0.0; // bytes per second
  Duration? _estimatedTimeRemaining;
  String _transferStatus = ''; // Transfer status message

  // Multi-file transfer tracking
  int _totalFilesCount = 0;
  int _completedFilesCount = 0;

  // Concurrent transfer tracking
  final Map<int, double> _fileProgress = {}; // fileIndex -> progress
  final Map<int, String> _fileStatus = {}; // fileIndex -> status
  final Set<int> _completedFileIndices =
      {}; // Track completed files to avoid duplicate counting

  // Services
  final ValidationService _validationService = ValidationService();
  final FileTransferService _fileTransferService = FileTransferService();
  final NotificationService _notificationService = NotificationService();
  final PermissionService _permissionService = PermissionService();
  final PreferencesService _preferencesService = PreferencesService();

  // Controllers and validation
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: '${AppConstants.defaultPort}',
  );
  String? _ipErrorMessage;
  String? _portErrorMessage;

  // IP history
  List<String> _ipHistory = [];

  @override
  void initState() {
    super.initState();

    // Set context for server manager to show dialogs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.serverManager.setContext(context);
      }
    });

    _updateServerStatus();

    // Add listener for IP address validation
    _ipController.addListener(_validateIPAddress);

    // Add listener for port validation
    _portController.addListener(_validatePort);

    // Load last used IP address
    _loadLastUsedIP();

    // Load last used port
    _loadLastUsedPort();

    // Load IP history
    _loadIPHistory();
  }

  /// Validate the IP address in real-time
  void _validateIPAddress() {
    final ip = _ipController.text.trim();
    
    if (ip.isEmpty) {
      setState(() {
        targetIP = ip;
        _ipErrorMessage = null;
      });
      return;
    }

    // First do basic format validation
    final basicResult = _validationService.validateIPv4(ip);
    if (!basicResult.isValid) {
      setState(() {
        targetIP = ip;
        _ipErrorMessage = basicResult.errorMessage;
      });
      return;
    }

    // Then do subnet validation with server address
    final subnetResult = _validationService.validateIPv4WithSubnet(
      ip,
      serverAddress: serverAddress, // Use server address from HTTPServerManager
    );
    
    setState(() {
      targetIP = ip;
      _ipErrorMessage = subnetResult.isValid ? null : subnetResult.errorMessage;
    });
  }

  /// Validate the port in real-time
  void _validatePort() {
    final portText = _portController.text.trim();
    setState(() {
      if (portText.isEmpty) {
        _portErrorMessage = '端口不能为空';
      } else {
        final port = int.tryParse(portText);
        if (port == null) {
          _portErrorMessage = '端口必须是数字';
        } else if (port < 1 || port > 65535) {
          _portErrorMessage = '端口范围: 1-65535';
        } else {
          _portErrorMessage = null;
          // Auto-save valid port
          _saveCurrentPort();
        }
      }
    });
  }

  /// Load the last used IP address from preferences
  Future<void> _loadLastUsedIP() async {
    final lastIP = await _preferencesService.getLastUsedIP();
    if (lastIP != null && lastIP.isNotEmpty && mounted) {
      _ipController.text = lastIP;
      // Trigger validation
      _validateIPAddress();
    }
  }

  /// Load the last used port from preferences
  Future<void> _loadLastUsedPort() async {
    final lastPort = await _preferencesService.getLastUsedPort();
    if (mounted) {
      _portController.text = lastPort.toString();
      // Trigger validation
      _validatePort();
    }
  }

  /// Load IP address history from preferences
  Future<void> _loadIPHistory() async {
    final history = await _preferencesService.getIPHistory();
    if (mounted) {
      setState(() {
        _ipHistory = history;
      });
    }
  }

  /// Save the current IP address to preferences
  Future<void> _saveCurrentIP() async {
    final ip = _ipController.text.trim();
    if (ip.isNotEmpty) {
      await _preferencesService.saveLastUsedIP(ip);
      // Reload history to update the list
      await _loadIPHistory();
    }
  }

  /// Save the current port to preferences
  Future<void> _saveCurrentPort() async {
    final portText = _portController.text.trim();
    final port = int.tryParse(portText);
    if (port != null && port >= 1 && port <= 65535) {
      await _preferencesService.saveLastUsedPort(port);
    }
  }

  /// Delete an IP address from history
  Future<void> _deleteIPFromHistory(String ip) async {
    final success = await _preferencesService.removeIPFromHistory(ip);
    if (success) {
      // Reload history to update the list
      await _loadIPHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除 IP: $ip'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  /// Format bytes to human-readable format
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Format speed to human-readable format
  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  /// Format duration to human-readable format
  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} 秒';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} 分 ${duration.inSeconds % 60} 秒';
    } else {
      return '${duration.inHours} 小时 ${duration.inMinutes % 60} 分';
    }
  }

  /// Update server status from the server manager
  void _updateServerStatus() {
    setState(() {
      isServerRunning = widget.serverManager.isRunning();
      serverAddress = widget.serverManager.getServerAddress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 点击空白区域时移除焦点
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Icy Easy Send'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Server status indicator will be added in sub-task 11.6
                _buildServerStatusIndicator(),
                const SizedBox(height: 24),

                // IP address input will be added in sub-task 11.2
                const Text(
                  '目标设备 IP 地址',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          hintText: '例如: 192.168.1.100',
                          border: const OutlineInputBorder(),
                          errorText: _ipErrorMessage,
                          errorMaxLines: 10, // Allow multi-line error messages
                          suffixIcon: _ipHistory.isNotEmpty
                              ? PopupMenuButton<String>(
                                  icon: const Icon(Icons.history),
                                  tooltip: '历史记录',
                                  onSelected: (String ip) {
                                    _ipController.text = ip;
                                    _validateIPAddress();
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return _ipHistory.map((String ip) {
                                      return PopupMenuItem<String>(
                                        value: ip,
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(ip)),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () {
                                                Navigator.of(
                                                  context,
                                                ).pop(); // Close the menu
                                                _deleteIPFromHistory(ip);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList();
                                  },
                                )
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        enabled: isServerRunning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 诊断按钮
                    IconButton(
                      onPressed: isServerRunning
                          ? _runNetworkDiagnostics
                          : null,
                      icon: const Icon(Icons.network_check),
                      tooltip: '网络诊断',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quick IP address suggestions
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickIPButton('192.168.1.1'),
                    _buildQuickIPButton('192.168.0.1'),
                    _buildQuickIPButton('10.0.0.1'),
                  ],
                ),
                const SizedBox(height: 16),

                // Port input
                const Text(
                  '目标设备端口',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _portController,
                        decoration: InputDecoration(
                          hintText: '默认: ${AppConstants.defaultPort}',
                          border: const OutlineInputBorder(),
                          errorText: _portErrorMessage,
                          prefixIcon: const Icon(Icons.settings_ethernet),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        enabled: isServerRunning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 重置为默认端口按钮
                    IconButton(
                      onPressed: isServerRunning
                          ? () {
                              _portController.text =
                                  '${AppConstants.defaultPort}';
                              _validatePort();
                            }
                          : null,
                      icon: const Icon(Icons.refresh),
                      tooltip: '重置为默认端口 (${AppConstants.defaultPort})',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade50,
                        foregroundColor: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // File selection will be added in sub-task 11.3
                const Text(
                  '选择文件',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: isServerRunning ? _selectFiles : null,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('选择文件'),
                ),
                if (selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '已选择 ${selectedFiles.length} 个文件',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = selectedFiles[index];
                        final fileName = file.path.split('/').last;
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.insert_drive_file,
                            size: 20,
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: isSending
                                ? null
                                : () {
                                    setState(() {
                                      selectedFiles.removeAt(index);
                                    });
                                  },
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Send button will be added in sub-task 11.5
                ElevatedButton.icon(
                  onPressed: _canSend() ? _sendFiles : null,
                  icon: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    isSending
                        ? '发送中...'
                        : selectedFiles.length > 1
                        ? '发送 ${selectedFiles.length} 个文件'
                        : '发送文件',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                // Progress indicator
                if (isSending) ...[
                  const SizedBox(height: 24),
                  _buildProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build server status indicator widget
  Widget _buildServerStatusIndicator() {
    // Parse IP and port from serverAddress
    String? ip;
    String? port;
    if (serverAddress != null) {
      final parts = serverAddress!.split(':');
      if (parts.length == 2) {
        ip = parts[0];
        port = parts[1];
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isServerRunning ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isServerRunning ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isServerRunning ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isServerRunning ? '服务器运行中' : '服务器已停止',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isServerRunning ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                ),
              ),
            ],
          ),
          if (isServerRunning && ip != null && port != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '本机IP',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            ip,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _copyToClipboard(ip!),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.copy,
                                size: 16,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '端口',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      port,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Copy text to clipboard
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('IP地址已复制: $text'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Build quick IP address button
  Widget _buildQuickIPButton(String ip) {
    return OutlinedButton.icon(
      onPressed: isServerRunning
          ? () {
              _ipController.text = ip;
              // Trigger validation
              _validateIPAddress();
            }
          : null,
      icon: const Icon(Icons.touch_app, size: 16),
      label: Text(ip),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  /// Build progress indicator widget
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2196F3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '传输进度',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (_totalFilesCount > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_completedFilesCount/$_totalFilesCount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _transferProgress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(_transferProgress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1976D2),
            ),
          ),
          // Status message
          if (_transferStatus.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _transferStatus,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_totalBytes > 0) ...[
            const SizedBox(height: 12),
            Text(
              '已传输: ${_formatBytes(_bytesTransferred)} / ${_formatBytes(_totalBytes)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
          if (_transferSpeed > 0) ...[
            const SizedBox(height: 6),
            Text(
              '传输速度: ${_formatSpeed(_transferSpeed)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
          if (_estimatedTimeRemaining != null) ...[
            const SizedBox(height: 6),
            Text(
              '剩余时间: ${_formatDuration(_estimatedTimeRemaining!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  /// Select multiple files using the file picker
  ///
  /// Requests storage permission before opening the file picker.
  /// If permission is denied, shows an error message.
  ///
  Future<void> _selectFiles() async {
    try {
      // Step 1: Check and request storage permission
      final hasPermission = await _permissionService.hasStoragePermission();

      if (!hasPermission) {
        // Request permission
        final permissionResult = await _permissionService
            .requestStoragePermission();

        if (!permissionResult.granted) {
          // Permission denied
          if (mounted) {
            if (permissionResult.permanentlyDenied) {
              // Show dialog with option to open settings
              await _showPermissionDeniedDialog(permissionResult.errorMessage);
            } else {
              // Show error message
              await _notificationService.showError(
                context,
                permissionResult.errorMessage ?? ErrorMessages.permissionDenied,
              );
            }
          }
          return;
        }
      }

      // Step 2: Permission granted, open file picker with multiple selection enabled
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true, // Enable multiple file selection
      );

      if (result != null && result.files.isNotEmpty) {
        final List<File> validFiles = [];
        final List<String> invalidFileNames = [];

        // Validate each selected file
        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            final validationResult = _validationService.validateFile(file);

            if (validationResult.isValid) {
              validFiles.add(file);
            } else {
              invalidFileNames.add(platformFile.name);
            }
          }
        }

        // Update state with valid files
        if (validFiles.isNotEmpty) {
          setState(() {
            selectedFiles = validFiles;
          });
        }

        // Show error for invalid files
        if (invalidFileNames.isNotEmpty && mounted) {
          await _notificationService.showError(
            context,
            '以下文件无效或无法访问:\n${invalidFileNames.join('\n')}',
          );
        }
      }
      // If result is null, user cancelled the picker
    } on FileSystemException {
      // Handle file system errors
      if (mounted) {
        await _notificationService.showError(
          context,
          ErrorMessages.fileAccessError,
        );
      }
    } catch (e) {
      // Handle any other errors during file selection
      if (mounted) {
        await _notificationService.showError(
          context,
          ErrorMessages.fileError(e.toString()),
        );
      }
    }
  }

  /// Show dialog when permission is permanently denied
  ///
  /// Offers the user the option to open app settings to grant permission manually
  Future<void> _showPermissionDeniedDialog(String? message) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要权限'),
        content: Text(message ?? '需要存储权限才能选择文件。请在设置中手动开启权限。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Open app settings
              await ph.openAppSettings();
            },
            child: const Text('打开设置'),
          ),
        ],
      ),
    );
  }

  /// Check if the send button should be enabled
  bool _canSend() {
    // Check if port is valid
    final portText = _portController.text.trim();
    final port = int.tryParse(portText);
    final isPortValid = port != null && port >= 1 && port <= 65535;
    
    return isServerRunning &&
        !isSending &&
        selectedFiles.isNotEmpty &&
        targetIP.isNotEmpty &&
        _ipErrorMessage == null &&
        isPortValid;
  }

  /// Send multiple selected files to the target device with batch confirmation
  Future<void> _sendFiles() async {
    if (selectedFiles.isEmpty || targetIP.isEmpty) {
      return;
    }

    // Validate port
    final portText = _portController.text.trim();
    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      await _notificationService.showError(context, '端口无效\n请输入 1-65535 之间的端口号');
      return;
    }

    // Combine IP and port
    final targetAddress = '$targetIP:$port';
    LogUtil.i(
      "_sendFiles() ready to send files, targetAddress: $targetAddress",
    );

    setState(() {
      isSending = true;
      _completedFilesCount = 0;
      _totalFilesCount = selectedFiles.length;
      _transferProgress = 0.0;
      _bytesTransferred = 0;
      _totalBytes = 0;
      _transferStartTime = DateTime.now();
      _transferSpeed = 0.0;
      _estimatedTimeRemaining = null;
      _transferStatus = '准备发送...';
      _fileProgress.clear();
      _fileStatus.clear();
      _completedFileIndices.clear(); // Clear completed files tracking
    });

    try {
      // Use batch confirmation for better UX
      setState(() {
        _transferStatus = '等待接收方确认...';
      });

      final results = await _fileTransferService.sendFilesWithBatchConfirm(
        targetIP: targetAddress,
        files: selectedFiles,
        onProgress: (progress, bytesTransferred, totalBytes) {
          setState(() {
            _transferProgress = progress;
            _bytesTransferred = bytesTransferred;
            _totalBytes = totalBytes;

            // Calculate transfer speed
            if (_transferStartTime != null) {
              final elapsed = DateTime.now().difference(_transferStartTime!);
              if (elapsed.inMilliseconds > 0) {
                _transferSpeed =
                    bytesTransferred / (elapsed.inMilliseconds / 1000.0);

                // Calculate estimated time remaining
                if (_transferSpeed > 0) {
                  final remainingBytes = totalBytes - bytesTransferred;
                  final remainingSeconds = remainingBytes / _transferSpeed;
                  _estimatedTimeRemaining = Duration(
                    seconds: remainingSeconds.toInt(),
                  );
                }
              }
            }
          });
        },
        onFileProgress: (fileIndex, progress, bytesTransferred, totalBytes) {
          setState(() {
            _fileProgress[fileIndex] = progress;
            final fileName = selectedFiles[fileIndex].path.split('/').last;

            if (progress < 1.0) {
              _fileStatus[fileIndex] =
                  '传输中 ${(progress * 100).toStringAsFixed(1)}%';
              _transferStatus =
                  '[${fileIndex + 1}/${selectedFiles.length}] $fileName: 传输中...';
            } else {
              // Only increment counter if this file hasn't been counted as completed yet
              if (!_completedFileIndices.contains(fileIndex)) {
                _completedFileIndices.add(fileIndex);
                _completedFilesCount++;
              }
              _fileStatus[fileIndex] = '✓ 发送成功';
            }
          });
        },
        onStatusChange: (status) {
          setState(() {
            _transferStatus = status;
          });
        },
      );

      // Count successes and failures
      int successCount = 0;
      int failureCount = 0;
      final List<String> failedFiles = [];

      for (final entry in results.entries) {
        if (entry.value.success) {
          successCount++;
        } else {
          failureCount++;
          failedFiles.add(entry.key);
        }
      }

      // Show summary message
      if (mounted) {
        if (failureCount == 0) {
          // All files sent successfully
          await _notificationService.showSuccess(
            context,
            successCount == 1 ? '文件发送成功！' : '所有 $successCount 个文件发送成功！',
          );

          // Save the IP address and port for next time
          await _saveCurrentIP();
          await _saveCurrentPort();

          // Clear the selected files after successful send
          setState(() {
            selectedFiles.clear();
          });
        } else if (successCount == 0) {
          // All files failed
          await _notificationService.showError(
            context,
            '所有文件发送失败\n失败的文件:\n${failedFiles.join('\n')}',
          );
        } else {
          // Some files succeeded, some failed
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('传输完成'),
              content: Text(
                '成功: $successCount 个文件\n失败: $failureCount 个文件\n\n失败的文件:\n${failedFiles.join('\n')}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('确定'),
                ),
              ],
            ),
          );

          // Save the IP address and port even if some files failed
          await _saveCurrentIP();
          await _saveCurrentPort();

          // Remove successfully sent files from the list
          setState(() {
            selectedFiles.removeWhere((file) {
              final fileName = file.path.split('/').last;
              return !failedFiles.contains(fileName);
            });
          });
        }
      }
    } on SocketException {
      // Handle network errors
      if (mounted) {
        await _notificationService.showError(
          context,
          ErrorMessages.networkConnectionFailed,
        );
      }
    } on FileSystemException {
      // Handle file system errors
      if (mounted) {
        await _notificationService.showError(
          context,
          ErrorMessages.fileAccessError,
        );
      }
    } catch (e) {
      // Handle unexpected errors
      if (mounted) {
        await _notificationService.showError(
          context,
          ErrorMessages.unexpectedError(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
          _completedFilesCount = 0;
          _totalFilesCount = 0;
          _transferProgress = 0.0;
          _bytesTransferred = 0;
          _totalBytes = 0;
          _transferStartTime = null;
          _transferSpeed = 0.0;
          _estimatedTimeRemaining = null;
          _transferStatus = '';
          _fileProgress.clear();
          _fileStatus.clear();
          _completedFileIndices.clear(); // Clear completed files tracking
        });
      }
    }
  }

  /// Run network diagnostics
  Future<void> _runNetworkDiagnostics() async {
    // Show loading dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在运行网络诊断...'),
          ],
        ),
      ),
    );

    try {
      // Parse target IP and port
      String? diagTargetIP;
      int? diagTargetPort;

      if (targetIP.isNotEmpty && _ipErrorMessage == null) {
        diagTargetIP = targetIP;

        // Use user-specified port from port controller
        final portText = _portController.text.trim();
        diagTargetPort = int.tryParse(portText);

        // If port is invalid, use default port
        if (diagTargetPort == null ||
            diagTargetPort < 1 ||
            diagTargetPort > 65535) {
          diagTargetPort = AppConstants.defaultPort;
        }
      }

      // Run diagnostics
      final report = await NetworkDiagnostics.runDiagnostics(
        targetIP: diagTargetIP,
        targetPort: diagTargetPort,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show diagnostics report
      if (mounted) {
        // Build report header with target info
        final reportHeader = StringBuffer();
        reportHeader.writeln('=' * 50);
        reportHeader.writeln('目标设备信息');
        reportHeader.writeln('=' * 50);
        if (diagTargetIP != null) {
          reportHeader.writeln('IP 地址: $diagTargetIP');
          reportHeader.writeln(
            '端口: ${diagTargetPort ?? AppConstants.defaultPort}',
          );
          reportHeader.writeln(
            '完整地址: http://$diagTargetIP:${diagTargetPort ?? AppConstants.defaultPort}',
          );
        } else {
          reportHeader.writeln('未设置目标设备');
        }
        reportHeader.writeln('=' * 50);
        reportHeader.writeln();

        // Combine header with report
        final fullReport = reportHeader.toString() + report.toString();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.network_check, color: Colors.blue),
                SizedBox(width: 8),
                Text('网络诊断报告'),
              ],
            ),
            content: SingleChildScrollView(
              child: SelectableText(
                fullReport,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: fullReport));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('诊断报告已复制到剪贴板'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('复制'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error
      if (mounted) {
        await _notificationService.showError(context, '运行诊断时出错: $e');
      }
    }
  }
}
