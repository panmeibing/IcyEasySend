import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../services/validation_service.dart';
import '../services/file_transfer_service.dart';
import '../services/notification_service.dart';
import '../services/http_server_manager.dart';
import '../services/permission_service.dart';
import '../utils/error_messages.dart';

/// HomePage is the main UI for the icy-easy-send application
/// 
/// It provides:
/// - IP address input for target device
/// - File selection functionality
/// - Send button to initiate file transfer
/// - Server status indicator
class HomePage extends StatefulWidget {
  final HTTPServerManager serverManager;

  const HomePage({
    super.key,
    required this.serverManager,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variables as defined in the design document
  String targetIP = '';
  File? selectedFile;
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

  // Services
  final ValidationService _validationService = ValidationService();
  final FileTransferService _fileTransferService = FileTransferService();
  final NotificationService _notificationService = NotificationService();
  final PermissionService _permissionService = PermissionService();

  // Controllers and validation
  final TextEditingController _ipController = TextEditingController();
  String? _ipErrorMessage;

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
  }
  
  /// Validate the IP address in real-time
  void _validateIPAddress() {
    final ip = _ipController.text.trim();
    setState(() {
      targetIP = ip;
      if (ip.isEmpty) {
        _ipErrorMessage = null;
      } else {
        final result = _validationService.validateIPv4(ip);
        _ipErrorMessage = result.isValid ? null : result.errorMessage;
      }
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Icy Easy Send'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
              TextField(
                controller: _ipController,
                decoration: InputDecoration(
                  hintText: '例如: 192.168.1.100',
                  border: const OutlineInputBorder(),
                  errorText: _ipErrorMessage,
                ),
                keyboardType: TextInputType.number,
                enabled: isServerRunning,
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
              const SizedBox(height: 24),
              
              // File selection will be added in sub-task 11.3
              const Text(
                '选择文件',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: isServerRunning ? _selectFile : null,
                icon: const Icon(Icons.folder_open),
                label: const Text('选择文件'),
              ),
              if (selectedFile != null) ...[
                const SizedBox(height: 8),
                Text(
                  '已选择: ${selectedFile!.path.split('/').last}',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
              const SizedBox(height: 24),
              
              // Send button will be added in sub-task 11.5
              ElevatedButton.icon(
                onPressed: _canSend() ? _sendFile : null,
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
                label: Text(isSending ? '发送中...' : '发送文件'),
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

    return Card(
      color: isServerRunning ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isServerRunning ? Icons.check_circle : Icons.error,
                  color: isServerRunning ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isServerRunning ? '服务器运行中' : '服务器已停止',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isServerRunning ? Colors.green[900] : Colors.red[900],
                  ),
                ),
              ],
            ),
            if (isServerRunning && ip != null && port != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '本机IP: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    ip,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _copyToClipboard(ip!),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '端口: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    port,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '传输进度',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _transferProgress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${(_transferProgress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Status message
            if (_transferStatus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _transferStatus,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (_totalBytes > 0) ...[
              Text(
                '已传输: ${_formatBytes(_bytesTransferred)} / ${_formatBytes(_totalBytes)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
            if (_transferSpeed > 0) ...[
              const SizedBox(height: 4),
              Text(
                '传输速度: ${_formatSpeed(_transferSpeed)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
            if (_estimatedTimeRemaining != null) ...[
              const SizedBox(height: 4),
              Text(
                '剩余时间: ${_formatDuration(_estimatedTimeRemaining!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Select a file using the file picker
  /// 
  /// Requests storage permission before opening the file picker.
  /// If permission is denied, shows an error message.
  /// 
  /// Requirements: 9.4, 10.4
  Future<void> _selectFile() async {
    try {
      // Step 1: Check and request storage permission
      final hasPermission = await _permissionService.hasStoragePermission();
      
      if (!hasPermission) {
        // Request permission
        final permissionResult = await _permissionService.requestStoragePermission();
        
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
      
      // Step 2: Permission granted, open file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Validate the file
        final validationResult = _validationService.validateFile(file);
        
        if (validationResult.isValid) {
          setState(() {
            selectedFile = file;
          });
        } else {
          // Show error if file is not valid
          if (mounted) {
            await _notificationService.showError(
              context,
              validationResult.errorMessage ?? ErrorMessages.fileAccessError,
            );
          }
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
        content: Text(
          message ?? '需要存储权限才能选择文件。请在设置中手动开启权限。',
        ),
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
    return isServerRunning &&
        !isSending &&
        selectedFile != null &&
        targetIP.isNotEmpty &&
        _ipErrorMessage == null;
  }

  /// Send the selected file to the target device
  Future<void> _sendFile() async {
    if (selectedFile == null || targetIP.isEmpty) {
      return;
    }

    setState(() {
      isSending = true;
      _transferProgress = 0.0;
      _bytesTransferred = 0;
      _totalBytes = 0;
      _transferStartTime = DateTime.now();
      _transferSpeed = 0.0;
      _estimatedTimeRemaining = null;
      _transferStatus = '准备发送...';
    });

    try {
      // Call FileTransferService to send the file with progress callback
      final result = await _fileTransferService.sendFile(
        targetIP: targetIP,
        file: selectedFile!,
        onProgress: (progress, bytesTransferred, totalBytes) {
          setState(() {
            _transferProgress = progress;
            _bytesTransferred = bytesTransferred;
            _totalBytes = totalBytes;
            
            // Calculate transfer speed
            if (_transferStartTime != null) {
              final elapsed = DateTime.now().difference(_transferStartTime!);
              if (elapsed.inMilliseconds > 0) {
                _transferSpeed = bytesTransferred / (elapsed.inMilliseconds / 1000.0);
                
                // Calculate estimated time remaining
                if (_transferSpeed > 0) {
                  final remainingBytes = totalBytes - bytesTransferred;
                  final remainingSeconds = remainingBytes / _transferSpeed;
                  _estimatedTimeRemaining = Duration(seconds: remainingSeconds.toInt());
                }
              }
            }
          });
        },
        onStatusChange: (status) {
          setState(() {
            _transferStatus = status;
          });
        },
      );

      if (mounted) {
        if (result.success) {
          // Show success message
          await _notificationService.showSuccess(
            context,
            '文件发送成功！',
          );
          
          // Clear the selected file after successful send
          setState(() {
            selectedFile = null;
          });
        } else {
          // Show error message with user-friendly error from ErrorMessages
          await _notificationService.showError(
            context,
            result.errorMessage ?? ErrorMessages.genericError('文件发送'),
          );
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
          _transferProgress = 0.0;
          _bytesTransferred = 0;
          _totalBytes = 0;
          _transferStartTime = null;
          _transferSpeed = 0.0;
          _estimatedTimeRemaining = null;
          _transferStatus = '';
        });
      }
    }
  }
}
