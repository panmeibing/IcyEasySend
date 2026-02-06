import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/http_server_manager.dart';
import '../services/preferences_service.dart';
import '../services/validation_service.dart';
import '../utils/constants.dart';
import '../utils/network_diagnostics.dart';
import '../utils/network_util.dart';
import '../utils/toast_helper.dart';
import 'controllers/file_transfer_controller.dart';
import 'widgets/file_selection_section.dart';
import 'widgets/ip_input_section.dart';
import 'widgets/port_input_section.dart';
import 'widgets/server_status_card.dart';
import 'widgets/transfer_progress_card.dart';

/// HomePage is the main UI for the icy-easy-send application
class HomePage extends StatefulWidget {
  final HTTPServerManager serverManager;

  const HomePage({super.key, required this.serverManager});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variables
  String targetIP = '';
  List<File> selectedFiles = [];
  bool isServerRunning = false;
  String? serverAddress;
  bool isSending = false;

  // Progress tracking
  double _transferProgress = 0.0;
  int _bytesTransferred = 0;
  int _totalBytes = 0;
  DateTime? _transferStartTime;
  double _transferSpeed = 0.0;
  Duration? _estimatedTimeRemaining;
  String _transferStatus = '';

  // Multi-file transfer tracking
  int _totalFilesCount = 0;
  int _completedFilesCount = 0;
  final Map<int, double> _fileProgress = {};
  final Map<int, String> _fileStatus = {};
  final Set<int> _completedFileIndices = {};

  // Services
  late final ValidationService _validationService;
  late final PreferencesService _preferencesService;
  late final FileTransferController _fileTransferController;

  // Controllers and validation
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: '${AppConstants.defaultPort}',
  );
  String? _ipErrorMessage;
  String? _portErrorMessage;

  // IP history
  List<String> _ipHistory = [];

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Initialize services
    _validationService = ValidationService();
    _preferencesService = PreferencesService();
    _fileTransferController = FileTransferController();

    // Set context for server manager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.serverManager.setContext(context);
      }
    });

    _updateServerStatus();

    // Add listeners
    _ipController.addListener(_validateIPAddress);
    _portController.addListener(_validatePort);

    // Load preferences
    _loadLastUsedIP();
    _loadLastUsedPort();
    _loadIPHistory();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    final result = _validationService.validateIPv4WithSubnet(
      ip,
      serverAddress: serverAddress,
    );

    setState(() {
      targetIP = ip;
      _ipErrorMessage = result.isValid ? null : result.errorMessage;
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
      _validateIPAddress();
    }
  }

  /// Load the last used port from preferences
  Future<void> _loadLastUsedPort() async {
    final lastPort = await _preferencesService.getLastUsedPort();
    if (mounted) {
      _portController.text = lastPort.toString();
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
      await _loadIPHistory();

      if (mounted) {
        ToastHelper.showSuccess(context, '已删除 IP: $ip');
      }
    }
  }

  /// Scroll to bottom of the page with animation
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Icy Easy Send')),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Server status indicator
                ServerStatusCard(
                  isServerRunning: isServerRunning,
                  serverAddress: serverAddress,
                ),
                const SizedBox(height: 24),

                // IP address input
                IPInputSection(
                  controller: _ipController,
                  errorMessage: _ipErrorMessage,
                  isEnabled: isServerRunning,
                  ipHistory: _ipHistory,
                  onDiagnostics: _runNetworkDiagnostics,
                  onIPSelected: (ip) {
                    _ipController.text = ip;
                    _validateIPAddress();
                  },
                  onIPDeleted: _deleteIPFromHistory,
                ),
                const SizedBox(height: 16),

                // Port input
                PortInputSection(
                  controller: _portController,
                  errorMessage: _portErrorMessage,
                  isEnabled: isServerRunning,
                  onReset: () {
                    _portController.text = '${AppConstants.defaultPort}';
                    _validatePort();
                  },
                ),
                const SizedBox(height: 24),

                // File selection
                FileSelectionSection(
                  selectedFiles: selectedFiles,
                  isEnabled: isServerRunning,
                  isSending: isSending,
                  onSelectFiles: _selectFiles,
                  onRemoveFile: (index) {
                    setState(() {
                      selectedFiles.removeAt(index);
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Send button
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
                  TransferProgressCard(
                    progress: _transferProgress,
                    bytesTransferred: _bytesTransferred,
                    totalBytes: _totalBytes,
                    transferSpeed: _transferSpeed,
                    estimatedTimeRemaining: _estimatedTimeRemaining,
                    status: _transferStatus,
                    completedFilesCount: _completedFilesCount,
                    totalFilesCount: _totalFilesCount,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Check if the send button should be enabled
  bool _canSend() {
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

  /// Select multiple files
  Future<void> _selectFiles() async {
    final files = await _fileTransferController.selectFiles(context);

    if (files.isNotEmpty) {
      setState(() {
        selectedFiles = files;
      });
      _scrollToBottom();
    }
  }

  /// Send multiple selected files to the target device
  Future<void> _sendFiles() async {
    if (selectedFiles.isEmpty || targetIP.isEmpty) {
      return;
    }

    final portText = _portController.text.trim();
    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      return;
    }

    await _fileTransferController.sendFiles(
      context: context,
      files: selectedFiles,
      targetIP: targetIP,
      targetPort: port,
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
      onTransferStart: () {
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
          _completedFileIndices.clear();
        });
        _scrollToBottom();
      },
      onTransferEnd: () {
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
            _completedFileIndices.clear();

            // Clear selected files on successful transfer
            selectedFiles.clear();
          });
        }
      },
      onHistoryUpdated: () {
        // Trigger history refresh after file transfer completes
        widget.serverManager.refreshHistory();
      },
    );
  }

  /// Run network diagnostics
  Future<void> _runNetworkDiagnostics() async {
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
      String? diagTargetIP;
      int? diagTargetPort;

      if (targetIP.isNotEmpty && _ipErrorMessage == null) {
        diagTargetIP = targetIP;

        final portText = _portController.text.trim();
        diagTargetPort = int.tryParse(portText);

        if (diagTargetPort == null ||
            diagTargetPort < 1 ||
            diagTargetPort > 65535) {
          diagTargetPort = AppConstants.defaultPort;
        }
      }

      final report = await NetworkDiagnostics.runDiagnostics(
        targetIP: diagTargetIP,
        targetPort: diagTargetPort,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        String separator = AppConstants.diagInfoSeparator;
        final reportHeader = StringBuffer();
        reportHeader.writeln(separator * 3);
        reportHeader.writeln('目标设备信息');
        reportHeader.writeln(separator * 3);
        if (diagTargetIP != null) {
          reportHeader.writeln('IP 地址: $diagTargetIP');
          reportHeader.writeln(
            '端口: ${diagTargetPort ?? AppConstants.defaultPort}',
          );
          reportHeader.writeln(
            '完整地址: ${NetworkUtil.buildHttpUrl(diagTargetIP, "", targetPort: diagTargetPort ?? AppConstants.defaultPort)}',
          );
        } else {
          reportHeader.writeln('未设置目标设备');
        }
        reportHeader.writeln(separator * 3);
        reportHeader.writeln();

        final fullReport = reportHeader.toString() + report.toString();

        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
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
                  ToastHelper.showSuccess(context, '诊断报告已复制到剪贴板');
                },
                child: const Text('复制'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ToastHelper.showError(context, '运行诊断时出错: $e');
      }
    }
  }
}
