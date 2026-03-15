import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icy_easy_send/utils/log_util.dart';
import 'package:path/path.dart' as path;

import '../l10n/app_localizations.dart';
import '../services/http_server_manager.dart';
import '../services/preferences_service.dart';
import '../services/sharing_intent_service.dart';
import '../services/validation_service.dart';
import '../utils/constants.dart';
import '../utils/dialog_helper.dart';
import '../utils/network_diagnostics.dart';
import '../utils/network_util.dart';
import '../utils/toast_helper.dart';
import 'home/controllers/clipboard_controller.dart';
import 'home/controllers/file_transfer_controller.dart';
import 'home/widgets/file_selection_section.dart';
import 'home/widgets/ip_input_section.dart';
import 'home/widgets/port_input_section.dart';
import 'home/widgets/secret_key_input_section.dart';
import 'home/widgets/server_status_card.dart';
import 'home/widgets/transfer_progress_card.dart';

/// HomePage is the main UI for the icy-easy-send application
class HomePage extends StatefulWidget {
  final HTTPServerManager serverManager;
  final SharingIntentService sharingIntentService;

  const HomePage({
    super.key,
    required this.serverManager,
    required this.sharingIntentService,
  });

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final String logTag = LogTags.ui;

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
  late final ClipboardController _clipboardController;

  // Controllers and validation
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: '${AppConstants.defaultPort}',
  );
  final TextEditingController _secretKeyController = TextEditingController();
  final FocusNode _ipFocusNode = FocusNode();
  final FocusNode _portFocusNode = FocusNode();
  final FocusNode _secretKeyFocusNode = FocusNode();
  String? _ipErrorMessage;

  // True if the IP error message is a warning, not a hard error
  bool _ipIsWarning = false;
  String? _portErrorMessage;
  bool _enableIPValidation = true; // Whether IP validation is enabled

  // IP history
  List<String> _ipHistory = [];

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  // Drag and drop state
  bool _isDragging = false;

  // Sharing intent subscription
  StreamSubscription? _sharingIntentSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize services
    _validationService = ValidationService();
    _preferencesService = PreferencesService();
    _fileTransferController = FileTransferController();
    _clipboardController = ClipboardController();

    // Set context for server manager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.serverManager.setContext(context);
        // Register network change callback
        widget.serverManager.addNetworkChangeCallback(_onNetworkChanged);
      }
    });

    _updateServerStatus();

    // Add listeners
    _ipController.addListener(_validateIPAddress);
    _portController.addListener(_validatePort);
    _secretKeyController.addListener(_saveTargetSecretKey);

    // Load preferences
    _loadLastUsedIP();
    _loadLastUsedPort();
    _loadLastUsedTargetSecretKey();
    _loadIPHistory();
    _loadIPValidationEnabled();

    // Listen for shared files from other apps
    _sharingIntentSubscription = widget.sharingIntentService.sharedFilesStream
        .listen((files) {
          LogUtil.iTag(
            logTag,
            "Monitored the files from sharing intent, files: ${files.toString()}",
          );
          if (files.isNotEmpty && mounted) {
            _handleSharedFiles(files);
          } else if (files.isNotEmpty) {
            LogUtil.wTag(logTag, 'Sharing intent received empty files');
          } else if (!mounted) {
            LogUtil.wTag(
              logTag,
              'Sharing intent received files but page do not mounted',
            );
          }
        });
  }

  @override
  void dispose() {
    widget.serverManager.removeNetworkChangeCallback(_onNetworkChanged);
    _sharingIntentSubscription?.cancel();
    _ipController.dispose();
    _portController.dispose();
    _secretKeyController.dispose();
    _ipFocusNode.dispose();
    _portFocusNode.dispose();
    _secretKeyFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle network change event
  void _onNetworkChanged() {
    if (mounted) {
      _updateServerStatus();
      ToastHelper.showSuccess(
        context,
        AppLocalizations.of(context).networkChanged,
      );
    }
  }

  /// Validate the IP address in real-time
  Future<void> _validateIPAddress() async {
    final ip = _ipController.text.trim();

    if (ip.isEmpty) {
      setState(() {
        targetIP = ip;
        _ipErrorMessage = null;
        _ipIsWarning = false;
      });
      return;
    }

    final result = await _validationService.validateIPv4WithSubnet(
      ip,
      serverAddress: serverAddress,
      enableValidation: _enableIPValidation,
    );

    setState(() {
      targetIP = ip;
      _ipErrorMessage = result.isValid ? null : result.errorMessage;
      _ipIsWarning = result.isWarning;
    });
  }

  /// Validate the port in real-time
  void _validatePort() {
    final portText = _portController.text.trim();
    setState(() {
      if (portText.isEmpty) {
        _portErrorMessage = AppLocalizations.of(context).portCannotBeEmpty;
      } else {
        final port = int.tryParse(portText);
        if (port == null) {
          _portErrorMessage = AppLocalizations.of(context).portMustBeNumber;
        } else if (port < 1 || port > 65535) {
          _portErrorMessage = AppLocalizations.of(context).portRange;
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

  /// Load the last used target device secret key from preferences
  Future<void> _loadLastUsedTargetSecretKey() async {
    final lastSecretKey = await _preferencesService.getTargetDeviceSecretKey();
    if (lastSecretKey != null && lastSecretKey.isNotEmpty && mounted) {
      _secretKeyController.text = lastSecretKey;
    }
  }

  /// Save the current target device secret key to preferences
  Future<void> _saveTargetSecretKey() async {
    final secretKey = _secretKeyController.text.trim();
    if (secretKey.isNotEmpty) {
      await _preferencesService.saveTargetDeviceSecretKey(secretKey);
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

  /// Load IP validation enabled state from preferences
  Future<void> _loadIPValidationEnabled() async {
    final enabled = await _preferencesService.getIPValidationEnabled();
    if (mounted) {
      setState(() {
        _enableIPValidation = enabled;
      });
      // Re-validate IP address with new setting
      _validateIPAddress();
    }
  }

  /// Public method to reload IP validation setting (called when returning from settings)
  void reloadIPValidationSetting() {
    _loadIPValidationEnabled();
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
        ToastHelper.showSuccess(
          context,
          AppLocalizations.of(context).ipDeleted(ip),
        );
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
    return DropTarget(
      onDragEntered: (details) {
        if (isServerRunning && !isSending) {
          setState(() {
            _isDragging = true;
          });
        }
      },
      onDragExited: (details) {
        setState(() {
          _isDragging = false;
        });
      },
      onDragDone: (details) async {
        setState(() {
          _isDragging = false;
        });

        if (!isServerRunning || isSending) {
          return;
        }

        // Convert XFile to File
        final files = details.files.map((xFile) => File(xFile.path)).toList();

        if (files.isNotEmpty) {
          await _handleDroppedFiles(files);
        }
      },
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Scaffold(
              appBar: AppBar(title: const Text(AppConstants.projectName)),
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
                        focusNode: _ipFocusNode,
                        errorMessage: _ipErrorMessage,
                        isEnabled: isServerRunning,
                        ipHistory: _ipHistory,
                        serverAddress: serverAddress,
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
                        focusNode: _portFocusNode,
                        errorMessage: _portErrorMessage,
                        isEnabled: isServerRunning,
                        onReset: () {
                          _portController.text = '${AppConstants.defaultPort}';
                          _validatePort();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Secret key input
                      SecretKeyInputSection(
                        controller: _secretKeyController,
                        focusNode: _secretKeyFocusNode,
                        isEnabled: isServerRunning,
                        onClear: () async {
                          _secretKeyController.clear();
                          // Clear the cached secret key
                          await _preferencesService
                              .clearTargetDeviceSecretKey();
                        },
                      ),
                      const SizedBox(height: 24),

                      // Clipboard sync button
                      OutlinedButton.icon(
                        onPressed: _canRequestClipboard()
                            ? _requestClipboard
                            : null,
                        icon: const Icon(Icons.content_paste),
                        label: Text(AppLocalizations.of(context).syncClipboard),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.blue,
                          side: BorderSide(
                            color: _canRequestClipboard()
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
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
                              ? AppLocalizations.of(context).sending
                              : selectedFiles.length > 1
                              ? AppLocalizations.of(
                                  context,
                                ).filesCount(selectedFiles.length)
                              : AppLocalizations.of(context).sendFile,
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
          ),

          // Drag overlay
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: Colors.blue.withValues(alpha: 0.1),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_download, size: 64, color: Colors.blue),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).releaseToAdd,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Check if the send button should be enabled
  bool _canSend() {
    final portText = _portController.text.trim();
    final port = int.tryParse(portText);
    final isPortValid = port != null && port >= 1 && port <= 65535;

    // Allow sending if IP error is just a warning (not a hard error)
    final isIPValid =
        targetIP.isNotEmpty && (_ipErrorMessage == null || _ipIsWarning);

    return isServerRunning &&
        !isSending &&
        selectedFiles.isNotEmpty &&
        isIPValid &&
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

  /// Handle dropped files from drag and drop
  Future<void> _handleDroppedFiles(List<File> droppedFiles) async {
    final validFiles = await _fileTransferController.validateDroppedFiles(
      context,
      droppedFiles,
    );

    if (validFiles.isNotEmpty) {
      setState(() {
        // Add to existing files instead of replacing
        selectedFiles.addAll(validFiles);
      });
      _scrollToBottom();
    }
  }

  /// Handle shared files from other apps
  Future<void> _handleSharedFiles(List<File> sharedFiles) async {
    LogUtil.wTag(LogTags.ui, 'Start processing the shared file');

    // Clear the shared files from the service
    widget.sharingIntentService.clearSharedFiles();

    if (!isServerRunning) {
      ToastHelper.showWarning(
        context,
        AppLocalizations.of(context).serverNotRunning,
      );
      return;
    }

    if (isSending) {
      ToastHelper.showWarning(
        context,
        AppLocalizations.of(context).sendingInProgress,
      );
      return;
    }

    final validFiles = await _fileTransferController.validateDroppedFiles(
      context,
      sharedFiles,
    );

    if (!mounted) {
      LogUtil.wTag(LogTags.ui, 'The current page is not mounted.');
      return;
    }

    if (validFiles.isNotEmpty) {
      setState(() {
        // Add shared files to the selection
        selectedFiles.addAll(validFiles);
      });

      ToastHelper.showSuccess(
        context,
        AppLocalizations.of(context).filesAdded(validFiles.length),
      );

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

    _disableFocusNodes();

    try {
      await _fileTransferController.sendFiles(
        context: context,
        files: selectedFiles,
        targetIP: targetIP,
        targetPort: port,
        secretKey: _secretKeyController.text.trim(),
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
            final fileName = path.basename(selectedFiles[fileIndex].path);
            final l10n = AppLocalizations.of(context);

            if (progress < 1.0) {
              _fileStatus[fileIndex] = l10n.transferringProgress(
                progress * 100,
              );
              _transferStatus =
                  '[${fileIndex + 1}/${selectedFiles.length}] $fileName: ${l10n.transferring}...';
            } else {
              if (!_completedFileIndices.contains(fileIndex)) {
                _completedFileIndices.add(fileIndex);
                _completedFilesCount++;
              }
              _fileStatus[fileIndex] = l10n.sendSuccess;
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
            _transferStatus = AppLocalizations.of(context).preparingSend;
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
    } finally {
      // Always re-enable focus nodes after transfer completes or fails
      if (mounted) {
        _enableFocusNodes();
      }
    }
  }

  /// Disable all focus nodes and unfocus current scope
  void _disableFocusNodes() {
    _ipFocusNode.unfocus();
    _portFocusNode.unfocus();
    _secretKeyFocusNode.unfocus();
    _ipFocusNode.canRequestFocus = false;
    _portFocusNode.canRequestFocus = false;
    _secretKeyFocusNode.canRequestFocus = false;
    FocusScope.of(context).unfocus();
  }

  /// Enable all focus nodes
  void _enableFocusNodes() {
    _ipFocusNode.canRequestFocus = true;
    _portFocusNode.canRequestFocus = true;
    _secretKeyFocusNode.canRequestFocus = true;
  }

  /// Run network diagnostics
  Future<void> _runNetworkDiagnostics() async {
    if (!mounted) return;

    _disableFocusNodes();

    // Wait a frame to ensure focus changes are applied
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Show loading dialog (don't await it)
    DialogHelper.showLoadingDialog(
      context,
      message: AppLocalizations.of(context).runningDiagnostics,
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
        _enableFocusNodes();
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        String separator = AppConstants.diagInfoSeparator;
        final reportHeader = StringBuffer();
        reportHeader.writeln(separator * 3);
        reportHeader.writeln(l10n.targetDeviceInfo);
        reportHeader.writeln(separator * 3);
        if (diagTargetIP != null) {
          reportHeader.writeln('${l10n.ipAddress}: $diagTargetIP');
          reportHeader.writeln(
            '${l10n.port}: ${diagTargetPort ?? AppConstants.defaultPort}',
          );
          reportHeader.writeln(
            '${l10n.fullAddress}: ${NetworkUtil.buildHttpUrl(diagTargetIP, "", targetPort: diagTargetPort ?? AppConstants.defaultPort)}',
          );
        } else {
          reportHeader.writeln(l10n.targetNotSet);
        }
        reportHeader.writeln(separator * 3);
        reportHeader.writeln();

        final fullReport = reportHeader.toString() + report.toString();

        await DialogHelper.showCustomDialog(
          context,
          title: Row(
            children: [
              const Icon(Icons.network_check, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.diagnosticsReport)),
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
                ToastHelper.showSuccess(context, l10n.reportCopied);
              },
              child: Text(l10n.copy),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _enableFocusNodes();
              },
              child: Text(l10n.close),
            ),
          ],
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _enableFocusNodes();
        ToastHelper.showError(
          context,
          '${AppLocalizations.of(context).error}: $e',
        );
      }
    }
  }

  /// Check if the clipboard request button should be enabled
  bool _canRequestClipboard() {
    final portText = _portController.text.trim();
    final port = int.tryParse(portText);
    final isPortValid = port != null && port >= 1 && port <= 65535;

    // Allow requesting clipboard if IP error is just a warning (not a hard error)
    final isIPValid =
        targetIP.isNotEmpty && (_ipErrorMessage == null || _ipIsWarning);

    return isServerRunning && !isSending && isIPValid && isPortValid;
  }

  /// Request clipboard content from target device
  Future<void> _requestClipboard() async {
    if (targetIP.isEmpty) {
      return;
    }

    final portText = _portController.text.trim();
    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      return;
    }

    _disableFocusNodes();

    try {
      await _clipboardController.syncClipboard(
        context: context,
        targetIP: targetIP,
        targetPort: port,
        secretKey: _secretKeyController.text.trim(),
        onSuccess: () async {
          if (mounted) {
            await _loadIPHistory();
          }
        },
        onError: () {
          // Error already handled by controller
        },
      );
    } finally {
      // Always re-enable focus nodes
      if (mounted) {
        _enableFocusNodes();
      }
    }
  }
}
