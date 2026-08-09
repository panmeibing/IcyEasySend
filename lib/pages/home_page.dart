import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icy_easy_send/utils/log_util.dart';
import '../l10n/app_localizations.dart';
import '../models/discovered_device.dart';
import '../models/transfer_file_item.dart';
import '../models/transfer_history.dart';
import '../services/cache_cleanup_service.dart';
import '../services/http_server_manager.dart';
import '../services/preferences_service.dart';
import '../services/screen_wake_lock_service.dart';
import '../services/sharing_intent_service.dart';
import '../services/transfer/transfer_history_manager.dart';
import '../services/validation_service.dart';
import '../services/web_share_service.dart';
import '../utils/constants.dart';
import '../utils/dialog_helper.dart';
import '../utils/network_diagnostics.dart';
import '../utils/network_util.dart';
import '../utils/toast_helper.dart';
import '../utils/transfer_progress_throttle.dart';
import 'home/controllers/clipboard_controller.dart';
import 'home/controllers/file_transfer_controller.dart';
import 'home/widgets/device_scan_dialog.dart';
import 'home/widgets/file_selection_section.dart';
import 'home/widgets/ip_input_section.dart';
import 'home/widgets/port_input_section.dart';
import 'home/widgets/secret_key_input_section.dart';
import 'home/widgets/server_status_card.dart';
import 'home/widgets/transfer_progress_card.dart';
import 'home/widgets/web_share_qr_dialog.dart';

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
  List<TransferFileItem> selectedItems = [];
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
  final TransferProgressThrottle _overallProgressThrottle =
      TransferProgressThrottle();
  final TransferProgressThrottle _fileProgressThrottle =
      TransferProgressThrottle();

  // Services
  late final ValidationService _validationService;
  late final PreferencesService _preferencesService;
  late final FileTransferController _fileTransferController;
  late final ClipboardController _clipboardController;
  late final CacheCleanupService _cacheCleanupService;
  late final TransferHistoryManager _historyManager;
  bool _isCreatingWebShare = false;

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
    _cacheCleanupService = CacheCleanupService();
    _historyManager = TransferHistoryManager();

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

    // Listen for shared files while the app is already running
    _sharingIntentSubscription = widget.sharingIntentService.sharedFilesStream
        .listen((files) {
          LogUtil.iTag(
            logTag,
            '收到运行中分享: ${files.length} 个文件',
          );
          if (files.isNotEmpty && mounted) {
            _handleSharedFiles(files);
          }
        });

    // Cold start shares are buffered before HomePage subscribes to the stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processInitialSharedFiles();
    });
  }

  /// Handle share payload that opened the app before UI was ready
  Future<void> _processInitialSharedFiles() async {
    await widget.sharingIntentService.loadInitialSharingIfNeeded();
    if (!mounted) return;

    final pending = widget.sharingIntentService.takePendingSharedFiles();
    if (pending.isEmpty) {
      return;
    }

    LogUtil.iTag(logTag, '处理冷启动分享: ${pending.length} 个文件');
    await _handleSharedFiles(pending);
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

        final paths = details.files
            .map((xFile) => xFile.path)
            .where((p) => p.isNotEmpty)
            .toList();

        if (paths.isNotEmpty) {
          await _handleDroppedPaths(paths);
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
                      const SizedBox(height: 16),

                      // Scan devices button
                      OutlinedButton.icon(
                        onPressed: isServerRunning ? _scanDevices : null,
                        icon: const Icon(Icons.search),
                        label: Text(
                          AppLocalizations.of(context).scanDevices,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.blue,
                          side: BorderSide(
                            color: isServerRunning ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Network diagnostics button
                      OutlinedButton.icon(
                        onPressed: isServerRunning ? _runNetworkDiagnostics : null,
                        icon: const Icon(Icons.network_check),
                        label: Text(
                          AppLocalizations.of(context).networkDiagnostics,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.blue,
                          side: BorderSide(
                            color: isServerRunning ? Colors.blue : Colors.grey,
                          ),
                        ),
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
                        selectedItems: selectedItems,
                        isEnabled: isServerRunning,
                        isSending: isSending,
                        onSelectFiles: _selectFiles,
                        onSelectFolder: _selectFolder,
                        onRemoveFile: (index) {
                          final removed = selectedItems[index];
                          setState(() {
                            selectedItems.removeAt(index);
                          });
                          _cacheCleanupService.deleteCacheFilesIfPresent([
                            removed.file.path,
                          ]);
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
                              : selectedItems.length > 1
                              ? AppLocalizations.of(
                                  context,
                                ).filesCount(selectedItems.length)
                              : AppLocalizations.of(context).sendFile,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // QR web share (guest browser download, no app install)
                      OutlinedButton.icon(
                        onPressed: _canShareViaQr() ? _shareViaQr : null,
                        icon: _isCreatingWebShare
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.qr_code_2),
                        label: Text(AppLocalizations.of(context).shareViaQr),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.blue,
                          side: BorderSide(
                            color: _canShareViaQr()
                                ? Colors.blue
                                : Colors.grey,
                          ),
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
        selectedItems.isNotEmpty &&
        isIPValid &&
        isPortValid;
  }

  /// QR share only needs a running server and selected files.
  bool _canShareViaQr() {
    return isServerRunning &&
        !isSending &&
        !_isCreatingWebShare &&
        selectedItems.isNotEmpty;
  }

  /// Create a temporary web-share session and show QR for guest downloads.
  Future<void> _shareViaQr() async {
    if (!_canShareViaQr()) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    if (!widget.serverManager.isRunning()) {
      ToastHelper.showError(context, l10n.webShareServerRequired);
      return;
    }

    final serverAddress = widget.serverManager.getServerAddress();
    if (serverAddress == null || serverAddress.isEmpty) {
      ToastHelper.showError(context, l10n.webShareServerRequired);
      return;
    }

    setState(() => _isCreatingWebShare = true);
    _disableFocusNodes();

    try {
      final session = await WebShareService.instance.createSession(
        items: selectedItems,
      );
      final shareUrl = WebShareService.instance.buildShareUrl(
        serverAddress,
        session.token,
      );

      await _saveWebShareHistory(session.files.map((f) {
        return TransferHistory(
          fileName: f.displayName,
          fileSize: f.size,
          peerIP: AppConstants.webShareHistoryPeerIp,
          peerDeviceName: l10n.webSharePeerName,
          timestamp: session.createdAt,
          isReceived: false,
          success: true,
        );
      }).toList());

      if (!mounted) return;

      ToastHelper.showSuccess(context, l10n.webShareCreated);

      await WebShareQrDialog.show(
        context,
        session: session,
        shareUrl: shareUrl,
        shareUrlBuilder: () {
          final address = widget.serverManager.getServerAddress();
          if (address == null || address.isEmpty) {
            return shareUrl;
          }
          return WebShareService.instance.buildShareUrl(address, session.token);
        },
        onStopSharing: () async {
          WebShareService.instance.stopSession(token: session.token);
          if (mounted) {
            ToastHelper.showInfo(context, l10n.webShareStopped);
          }
        },
      );
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '创建网页分享失败: $e', e, stackTrace);
      if (mounted) {
        ToastHelper.showError(context, l10n.webShareFailed);
      }
    } finally {
      _enableFocusNodes();
      if (mounted) {
        setState(() => _isCreatingWebShare = false);
      }
    }
  }

  Future<void> _saveWebShareHistory(List<TransferHistory> histories) async {
    if (histories.isEmpty) return;
    await _historyManager.saveTransferHistoryBatch(histories);
    widget.serverManager.refreshHistory();
  }

  /// Select multiple files
  Future<void> _selectFiles() async {
    final items = await _fileTransferController.selectFiles(context);

    if (items.isNotEmpty) {
      final previousItems = List<TransferFileItem>.from(selectedItems);
      setState(() {
        selectedItems = items;
      });
      await _cleanupShareCacheForItems(previousItems);
      _scrollToBottom();
    }
  }

  /// Select a folder (all files inside will be sent)
  Future<void> _selectFolder() async {
    final items = await _fileTransferController.selectFolder(context);

    if (items.isNotEmpty) {
      final previousItems = List<TransferFileItem>.from(selectedItems);
      setState(() {
        selectedItems = items;
      });
      await _cleanupShareCacheForItems(previousItems);
      _scrollToBottom();

      if (mounted) {
        ToastHelper.showSuccess(
          context,
          AppLocalizations.of(context).folderFilesAdded(items.length),
        );
      }
    }
  }

  /// Handle dropped paths from drag and drop (files or folders)
  Future<void> _handleDroppedPaths(List<String> paths) async {
    final validItems = await _fileTransferController.validateDroppedPaths(
      context,
      paths,
    );

    if (validItems.isNotEmpty) {
      setState(() {
        selectedItems.addAll(validItems);
      });
      _scrollToBottom();
    }
  }

  /// Handle shared files from other apps
  Future<void> _handleSharedFiles(List<File> sharedFiles) async {
    LogUtil.iTag(logTag, '开始处理分享文件: ${sharedFiles.length} 个');

    Future<void> rejectShare() async {
      await widget.sharingIntentService.cleanupSharedCacheFiles(sharedFiles);
      widget.sharingIntentService.clearSharedFiles();
    }

    if (!isServerRunning) {
      await rejectShare();
      if (!mounted) return;
      ToastHelper.showWarning(
        context,
        AppLocalizations.of(context).serverNotRunning,
      );
      return;
    }

    if (isSending) {
      await rejectShare();
      if (!mounted) return;
      ToastHelper.showWarning(
        context,
        AppLocalizations.of(context).sendingInProgress,
      );
      return;
    }

    final paths = sharedFiles.map((file) => file.path).toList();
    final validItems = await _fileTransferController.validateDroppedPaths(
      context,
      paths,
    );

    if (!mounted) {
      LogUtil.wTag(LogTags.ui, 'The current page is not mounted.');
      return;
    }

    if (validItems.isEmpty) {
      await rejectShare();
      return;
    }

    widget.sharingIntentService.clearSharedFiles();

    setState(() {
      selectedItems.addAll(validItems);
    });

    ToastHelper.showSuccess(
      context,
      AppLocalizations.of(context).filesAdded(validItems.length),
    );

    _scrollToBottom();
  }

  Future<void> _cleanupShareCacheForItems(
    Iterable<TransferFileItem> items,
  ) async {
    if (items.isEmpty) {
      return;
    }

    await _cacheCleanupService.deleteCacheFilesIfPresent(
      items.map((item) => item.file.path),
    );
  }

  /// Send multiple selected files to the target device
  Future<void> _sendFiles() async {
    if (selectedItems.isEmpty || targetIP.isEmpty) {
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
        files: selectedItems,
        targetIP: targetIP,
        targetPort: port,
        secretKey: _secretKeyController.text.trim(),
        onProgress: (progress, bytesTransferred, totalBytes) {
          _overallProgressThrottle.maybeEmit(
            key: 'overall',
            progress: progress,
            bytesTransferred: bytesTransferred,
            totalBytes: totalBytes,
            onEmit: (progress, bytesTransferred, totalBytes) {
              setState(() {
                _transferProgress = progress;
                _bytesTransferred = bytesTransferred;
                _totalBytes = totalBytes;

                // Calculate transfer speed
                if (_transferStartTime != null) {
                  final elapsed = DateTime.now().difference(
                    _transferStartTime!,
                  );
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
          );
        },
        onFileProgress: (fileIndex, progress, bytesTransferred, totalBytes) {
          _fileProgressThrottle.maybeEmit(
            key: fileIndex,
            progress: progress,
            bytesTransferred: bytesTransferred,
            totalBytes: totalBytes,
            onEmit: (progress, bytesTransferred, totalBytes) {
              setState(() {
                _fileProgress[fileIndex] = progress;
                final fileName = selectedItems[fileIndex].transferName;
                final l10n = AppLocalizations.of(context);

                if (progress < 1.0) {
                  _fileStatus[fileIndex] = l10n.transferringProgress(
                    progress * 100,
                  );
                  _transferStatus =
                      '[${fileIndex + 1}/${selectedItems.length}] $fileName: ${l10n.transferring}...';
                } else {
                  if (!_completedFileIndices.contains(fileIndex)) {
                    _completedFileIndices.add(fileIndex);
                    _completedFilesCount++;
                  }
                  _fileStatus[fileIndex] = l10n.sendSuccess;
                }
              });
            },
          );
        },
        onStatusChange: (status) {
          setState(() {
            _transferStatus = status;
          });
        },
        onTransferStart: () {
          ScreenWakeLockService.acquire();
          _overallProgressThrottle.reset();
          _fileProgressThrottle.reset();
          setState(() {
            isSending = true;
            _completedFilesCount = 0;
            _totalFilesCount = selectedItems.length;
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
          ScreenWakeLockService.release();
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
              selectedItems.clear();
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

  /// Scan local network for devices running Icy Easy Send
  Future<void> _scanDevices() async {
    if (!mounted || !isServerRunning) return;

    _disableFocusNodes();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final localIps = await NetworkUtil.getLocalPrivateIPs();

    if (!mounted) return;

    final device = await showDialog<DiscoveredDevice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeviceScanDialog(
        localIps: localIps,
      ),
    );

    _enableFocusNodes();

    if (device == null || !mounted) return;

    _ipController.text = device.ip;
    _portController.text = '${device.port}';
    await _validateIPAddress();
    _validatePort();
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
