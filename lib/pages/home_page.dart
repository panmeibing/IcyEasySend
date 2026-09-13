import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:icy_easy_send/utils/log_util.dart';
import '../l10n/app_localizations.dart';
import '../models/transfer_file_item.dart';
import '../services/cache_cleanup_service.dart';
import '../services/http_server_manager.dart';
import '../services/sharing_intent_service.dart';
import '../services/validation_service.dart';
import '../transport/transport_channel.dart';
import '../utils/constants.dart';
import '../utils/dialog_helper.dart';
import '../utils/network_diagnostics.dart';
import '../utils/network_util.dart';
import '../utils/toast_helper.dart';
import 'home/controllers/clipboard_controller.dart';
import 'home/controllers/connection_prefs_controller.dart';
import 'home/controllers/file_transfer_controller.dart';
import 'home/controllers/send_progress_controller.dart';
import 'home/controllers/share_intent_handler.dart';
import 'home/controllers/web_share_controller.dart';
import 'home/home_ui.dart';
import 'home/widgets/device_scan_dialog.dart';
import 'home/widgets/drag_drop_overlay.dart';
import 'home/widgets/network_diagnostics_dialog.dart';
import 'home/widgets/orbit_canvas.dart';
import 'home/widgets/orbit_dock.dart';
import 'home/widgets/orbit_sheets.dart';
import 'home/widgets/orbit_status_pill.dart';

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

  /// Peer chosen from orbit scan / manual flow. Cleared when the user edits IP.
  PeerRef? _selectedPeer;

  /// Peers shown as orbit satellites (with stable random angles).
  List<OrbitSatellite> _orbitPeers = [];

  /// Bumps when endpoint validation changes so modal sheets can rebuild.
  final ValueNotifier<int> _endpointUiTick = ValueNotifier<int>(0);

  final SendProgressController _sendProgress = SendProgressController();

  // Services
  late final ValidationService _validationService;
  late final ConnectionPrefsController _connectionPrefs;
  late final FileTransferController _fileTransferController;
  late final ClipboardController _clipboardController;
  late final CacheCleanupService _cacheCleanupService;
  late final WebShareController _webShareController;
  late final ShareIntentHandler _shareIntentHandler;
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

  // Drag and drop state
  bool _isDragging = false;

  // Sharing intent subscription
  StreamSubscription? _sharingIntentSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize services
    _validationService = ValidationService();
    _connectionPrefs = ConnectionPrefsController();
    _fileTransferController = FileTransferController();
    _clipboardController = ClipboardController();
    _cacheCleanupService = CacheCleanupService();
    _webShareController = WebShareController();
    _shareIntentHandler = ShareIntentHandler(
      fileTransferController: _fileTransferController,
      cacheCleanupService: _cacheCleanupService,
      sharingIntentService: widget.sharingIntentService,
    );

    // Set context for server manager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.serverManager.setContext(context);
        // Register network change callback
        widget.serverManager.addNetworkChangeCallback(_onNetworkChanged);
        widget.serverManager.addServerStatusCallback(_onServerStatusChanged);
      }
    });

    _updateServerStatus();

    // Add listeners
    _ipController.addListener(_validateIPAddress);
    _portController.addListener(_validatePort);
    _secretKeyController.addListener(_saveTargetSecretKey);

    // One prefs batch instead of five sequential SharedPreferences trips + setStates
    unawaited(_loadHomeConnectionPrefs());

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

  Future<void> _loadHomeConnectionPrefs() async {
    final prefs = await _connectionPrefs.loadHomeConnectionPrefs();
    if (!mounted) return;

    if (prefs.lastUsedIP != null && prefs.lastUsedIP!.isNotEmpty) {
      _ipController.text = prefs.lastUsedIP!;
    }
    _portController.text = prefs.lastUsedPort.toString();
    if (prefs.targetSecretKey != null && prefs.targetSecretKey!.isNotEmpty) {
      _secretKeyController.text = prefs.targetSecretKey!;
    }

    setState(() {
      _ipHistory = prefs.ipHistory;
      _enableIPValidation = prefs.enableIPValidation;
    });

    // Validate after controllers are filled (listeners already attached).
    _validateIPAddress();
    _validatePort();
  }

  /// Handle share payload that opened the app before UI was ready
  Future<void> _processInitialSharedFiles() async {
    await _shareIntentHandler.processInitialSharedFiles(
      isMounted: () => mounted,
      handleSharedFiles: _handleSharedFiles,
    );
  }

  @override
  void dispose() {
    widget.serverManager.removeNetworkChangeCallback(_onNetworkChanged);
    widget.serverManager.removeServerStatusCallback(_onServerStatusChanged);
    _sharingIntentSubscription?.cancel();
    _endpointUiTick.dispose();
    _ipController.dispose();
    _portController.dispose();
    _secretKeyController.dispose();
    _ipFocusNode.dispose();
    _portFocusNode.dispose();
    _secretKeyFocusNode.dispose();
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

  void _onServerStatusChanged() {
    if (mounted) {
      _updateServerStatus();
    }
  }

  /// Validate the IP address in real-time
  Future<void> _validateIPAddress() async {
    // Typing a different address means the scan selection no longer applies.
    final selected = _selectedPeer;
    if (selected != null && selected.hasLan) {
      final typed = _ipController.text.trim();
      if (typed.isNotEmpty && typed != selected.lan!.ip) {
        _selectedPeer = null;
      }
    } else if (selected != null && !selected.hasLan) {
      // Relay-only selection: any typed IP means the user is switching to LAN.
      if (_ipController.text.trim().isNotEmpty) {
        _selectedPeer = null;
      }
    }

    final ip = _ipController.text.trim();

    if (ip.isEmpty) {
      setState(() {
        targetIP = ip;
        _ipErrorMessage = null;
        _ipIsWarning = false;
      });
      _endpointUiTick.value++;
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
    _endpointUiTick.value++;
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
    _endpointUiTick.value++;
  }

  /// Save the current target device secret key to preferences
  Future<void> _saveTargetSecretKey() async {
    await _connectionPrefs.saveTargetSecretKey(_secretKeyController.text);
  }

  /// Load IP address history from preferences
  Future<void> _loadIPHistory() async {
    final history = await _connectionPrefs.loadIPHistory();
    if (mounted) {
      setState(() {
        _ipHistory = history;
      });
    }
  }

  /// Load IP validation enabled state from preferences
  Future<void> _loadIPValidationEnabled() async {
    final enabled = await _connectionPrefs.loadIPValidationEnabled();
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
    await _connectionPrefs.savePort(_portController.text);
  }

  /// Delete an IP address from history
  Future<void> _deleteIPFromHistory(String ip) async {
    final success = await _connectionPrefs.deleteIPFromHistory(ip);
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
              backgroundColor: HomeUi.pageBackground,
              appBar: AppBar(
                backgroundColor: HomeUi.pageBackground,
                surfaceTintColor: Colors.transparent,
                title: const Text(AppConstants.projectName),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: OrbitStatusPill(
                        isServerRunning: isServerRunning,
                        serverAddress: serverAddress,
                      ),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  if (Platform.isAndroid && isServerRunning)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Text(
                        AppLocalizations.of(context)
                            .androidBackgroundReceiveHint,
                        style: HomeUi.captionStyle.copyWith(
                          color: HomeUi.inkMuted.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      child: OrbitCanvas(
                        isServerRunning: isServerRunning,
                        isSending: isSending,
                        selectedItems: selectedItems,
                        satellites: _orbitPeers,
                        selectedPeer: _selectedPeer,
                        onCoreTap: _onOrbitCoreTap,
                        onScan: _scanDevices,
                        onPeerSelected: _applySelectedPeer,
                      ),
                    ),
                  ),
                  OrbitDock(
                    isServerRunning: isServerRunning,
                    isSending: isSending,
                    isCreatingWebShare: _isCreatingWebShare,
                    canSend: _canSend(),
                    canShareViaQr: _canShareViaQr(),
                    selectedPeer: _selectedPeer,
                    manualTargetLabel: _manualTargetLabel(),
                    progress: _sendProgress.progress,
                    progressStatus: _sendProgress.status,
                    onMore: _showOrbitMore,
                    onSend: _sendFiles,
                    onShareViaQr: _shareViaQr,
                    onAddFiles: _onOrbitAddFiles,
                    onClearPeer: () {
                      setState(() => _selectedPeer = null);
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isDragging) const DragDropOverlay(),
        ],
      ),
    );
  }

  String? _manualTargetLabel() {
    if (_selectedPeer != null) return null;
    final ip = targetIP.trim();
    if (ip.isEmpty) return null;
    final port = _portController.text.trim();
    return port.isEmpty ? ip : '$ip:$port';
  }

  void _onOrbitCoreTap() {
    if (!isServerRunning || isSending) return;
    if (selectedItems.isEmpty) {
      showOrbitPickSheet(
        context: context,
        onSelectFiles: () => _selectFiles(append: false),
        onSelectFolder: () => _selectFolder(append: false),
      );
    } else {
      showOrbitFilesSheet(
        context: context,
        items: selectedItems,
        isSending: isSending,
        onAdd: _onOrbitAddFiles,
        onClear: _clearSelectedFiles,
        onRemove: _removeSelectedFileAt,
      );
    }
  }

  void _onOrbitAddFiles() {
    showOrbitPickSheet(
      context: context,
      onSelectFiles: () => _selectFiles(append: selectedItems.isNotEmpty),
      onSelectFolder: () => _selectFolder(append: selectedItems.isNotEmpty),
    );
  }

  void _removeSelectedFileAt(int index) {
    if (index < 0 || index >= selectedItems.length || isSending) return;
    final removed = selectedItems[index];
    setState(() {
      selectedItems.removeAt(index);
    });
    _cacheCleanupService.deleteCacheFilesIfPresent([removed.file.path]);
  }

  void _clearSelectedFiles() {
    if (isSending || selectedItems.isEmpty) return;
    final previous = List<TransferFileItem>.from(selectedItems);
    setState(() => selectedItems.clear());
    unawaited(_shareIntentHandler.cleanupShareCacheForItems(previous));
  }

  Future<void> _showOrbitMore() async {
    if (!mounted || !isServerRunning) return;
    await showOrbitMoreSheet(
      context: context,
      canRequestClipboard: _canRequestClipboard(),
      onClipboard: _requestClipboard,
      onDiagnostics: _runNetworkDiagnostics,
      ipController: _ipController,
      portController: _portController,
      secretKeyController: _secretKeyController,
      ipFocusNode: _ipFocusNode,
      portFocusNode: _portFocusNode,
      secretKeyFocusNode: _secretKeyFocusNode,
      endpointUiTick: _endpointUiTick,
      ipErrorReader: () => _ipErrorMessage,
      portErrorReader: () => _portErrorMessage,
      ipHistory: _ipHistory,
      serverAddress: serverAddress,
      isEnabled: isServerRunning,
      onIPSelected: (ip) {
        _ipController.text = ip;
        _validateIPAddress();
      },
      onIPDeleted: _deleteIPFromHistory,
      onPortReset: () {
        _portController.text = '${AppConstants.defaultPort}';
        _validatePort();
      },
      onSecretHelp: () => _showSecretKeyHelp(context),
    );
  }

  void _showSecretKeyHelp(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    DialogHelper.showCustomDialog(
      context,
      title: Row(
        children: [
          const Icon(Icons.help_outline_rounded, color: HomeUi.primary),
          const SizedBox(width: 8),
          Text(l10n.aboutSecretKey),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.secretKeyFeatureTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.secretKeyFeatureDesc,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.secretKeyUsageSteps,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.secretKeyUsageStep1}\n${l10n.secretKeyUsageStep2}\n${l10n.secretKeyUsageStep3}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.secretKeyTip,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1976D2)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.gotIt),
        ),
      ],
    );
  }

  Future<void> _applySelectedPeer(PeerRef peer) async {
    if (!mounted) return;

    final existingIndex = _orbitPeers.indexWhere(
      (s) => s.peer.isSameRoute(peer),
    );
    setState(() {
      _selectedPeer = peer;
      if (existingIndex >= 0) {
        // Keep the satellite's angle; refresh peer data for this route.
        final existing = _orbitPeers.removeAt(existingIndex);
        _orbitPeers = [
          OrbitSatellite(peer: peer, angleDegrees: existing.angleDegrees),
          ..._orbitPeers,
        ].take(OrbitSatellite.maxVisible).toList();
      } else {
        _orbitPeers = [
          OrbitSatellite(
            peer: peer,
            angleDegrees: OrbitSatellite.pickAngle(_orbitPeers),
          ),
          ..._orbitPeers,
        ].take(OrbitSatellite.maxVisible).toList();
      }
    });

    if (peer.hasLan && peer.preferredTransport != TransportKind.relay) {
      _ipController.text = peer.lan!.ip;
      _portController.text = '${peer.lan!.port}';
      await _validateIPAddress();
      _validatePort();
    } else {
      // Relay / no-LAN route: do not keep a stale LAN address in the form.
      _ipController.clear();
      setState(() {
        targetIP = '';
        _ipErrorMessage = null;
        _ipIsWarning = false;
      });
    }
  }

  /// Check if the send button should be enabled
  bool _canSend() {
    if (!isServerRunning || isSending || selectedItems.isEmpty) {
      return false;
    }
    return _hasRelayPeerTarget() || _hasValidLanTarget();
  }

  bool _hasRelayPeerTarget() {
    final peer = _selectedPeer;
    return peer != null &&
        !peer.hasLan &&
        peer.relayOnline &&
        peer.deviceId != null;
  }

  bool _hasValidLanTarget() {
    final portText = _portController.text.trim();
    final port = int.tryParse(portText);
    final isPortValid = port != null && port >= 1 && port <= 65535;
    final isIPValid =
        targetIP.isNotEmpty && (_ipErrorMessage == null || _ipIsWarning);
    return isIPValid && isPortValid;
  }

  /// QR share only needs a running server and selected files.
  bool _canShareViaQr() {
    return _webShareController.canShareViaQr(
      isServerRunning: isServerRunning,
      isSending: isSending,
      isCreatingWebShare: _isCreatingWebShare,
      hasSelectedItems: selectedItems.isNotEmpty,
    );
  }

  /// Create a temporary web-share session and show QR for guest downloads.
  Future<void> _shareViaQr() async {
    if (!_canShareViaQr()) {
      return;
    }

    await _webShareController.shareViaQr(
      context: context,
      selectedItems: selectedItems,
      serverManager: widget.serverManager,
      onCreatingStart: () {
        setState(() => _isCreatingWebShare = true);
      },
      onCreatingEnd: () {
        if (mounted) {
          setState(() => _isCreatingWebShare = false);
        }
      },
      disableFocusNodes: _disableFocusNodes,
      enableFocusNodes: _enableFocusNodes,
      isMounted: () => mounted,
    );
  }

  /// Select multiple files
  Future<void> _selectFiles({bool append = false}) async {
    final items = await _fileTransferController.selectFiles(context);

    if (items.isNotEmpty) {
      final previousItems = List<TransferFileItem>.from(selectedItems);
      setState(() {
        if (append) {
          selectedItems = [...selectedItems, ...items];
        } else {
          selectedItems = items;
        }
      });
      if (!append) {
        await _shareIntentHandler.cleanupShareCacheForItems(previousItems);
      }
    }
  }

  /// Select a folder (all files inside will be sent)
  Future<void> _selectFolder({bool append = false}) async {
    final items = await _fileTransferController.selectFolder(context);

    if (items.isNotEmpty) {
      final previousItems = List<TransferFileItem>.from(selectedItems);
      setState(() {
        if (append) {
          selectedItems = [...selectedItems, ...items];
        } else {
          selectedItems = items;
        }
      });
      if (!append) {
        await _shareIntentHandler.cleanupShareCacheForItems(previousItems);
      }

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
    }
  }

  /// Handle shared files from other apps
  Future<void> _handleSharedFiles(List<File> sharedFiles) async {
    await _shareIntentHandler.handleSharedFiles(
      context: context,
      sharedFiles: sharedFiles,
      isServerRunning: isServerRunning,
      isSending: isSending,
      isMounted: () => mounted,
      onItemsAdded: (items) {
        setState(() {
          selectedItems.addAll(items);
        });
      },
    );
  }

  /// Send multiple selected files to the target device
  Future<void> _sendFiles() async {
    if (selectedItems.isEmpty || !_canSend()) {
      return;
    }

    final peer = _peerForSend();
    if (peer == null) {
      return;
    }

    final portText = _portController.text.trim();
    final port = int.tryParse(portText) ?? AppConstants.defaultPort;

    _disableFocusNodes();

    try {
      await _fileTransferController.sendFiles(
        context: context,
        files: selectedItems,
        targetIP: peer.lan?.ip ?? targetIP,
        targetPort: peer.lan?.port ?? port,
        peer: peer,
        secretKey: _secretKeyController.text.trim(),
        onProgress: (progress, bytesTransferred, totalBytes) {
          // The transfer outlives this page — callbacks keep arriving after
          // the user navigates away, and every one of them calls setState.
          if (!mounted) {
            return;
          }
          _sendProgress.onOverallProgress(
            progress: progress,
            bytesTransferred: bytesTransferred,
            totalBytes: totalBytes,
            onUiUpdate: () => setState(() {}),
          );
        },
        onFileProgress: (fileIndex, progress, bytesTransferred, totalBytes) {
          if (!mounted) {
            return;
          }
          _sendProgress.onFileProgress(
            fileIndex: fileIndex,
            progress: progress,
            items: selectedItems,
            l10n: AppLocalizations.of(context),
            onUiUpdate: () => setState(() {}),
          );
        },
        onStatusChange: (status) {
          if (!mounted) {
            return;
          }
          _sendProgress.onStatusChange(status, () => setState(() {}));
        },
        onTransferStart: () {
          final preparing = mounted
              ? AppLocalizations.of(context).preparingSend
              : '';
          _sendProgress.onTransferStart(
            fileCount: selectedItems.length,
            preparingLabel: preparing,
            onUiUpdate: () {
              if (!mounted) {
                return;
              }
              setState(() => isSending = true);
            },
          );
        },
        onTransferEnd: () {
          _sendProgress.onTransferEnd(
            onUiUpdate: () {
              if (!mounted) {
                return;
              }
              setState(() => isSending = false);
            },
            clearSelectedItems: () => selectedItems.clear(),
          );
        },
        onHistoryUpdated: () {
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

  /// Builds the peer to send to from the scan selection and/or the IP fields.
  PeerRef? _peerForSend() {
    final selected = _selectedPeer;
    if (selected != null) {
      if (selected.preferredTransport == TransportKind.relay ||
          !selected.hasLan) {
        return selected;
      }
      // Keep identity / preferred path from the scan, but honour any IP the
      // user typed afterwards.
      final portText = _portController.text.trim();
      final port = int.tryParse(portText) ?? selected.lan!.port;
      if (targetIP.isNotEmpty) {
        return selected.copyWith(lan: LanEndpoint(ip: targetIP, port: port));
      }
      return selected;
    }

    if (targetIP.isEmpty) {
      return null;
    }
    final portText = _portController.text.trim();
    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      return null;
    }
    return PeerRef.lanAddress('$targetIP:$port');
  }

  /// Scan local network via the original progress dialog (with cancel).
  Future<void> _scanDevices() async {
    if (!mounted || !isServerRunning) return;

    _disableFocusNodes();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final localIps = await NetworkUtil.getLocalPrivateIPs();
    if (!mounted) return;

    final selection = await showDialog<DeviceScanSelection>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeviceScanDialog(localIps: localIps),
    );

    _enableFocusNodes();

    if (selection == null || !mounted) return;
    await _applyScanSelection(selection);
  }

  /// Places every live route for the chosen device on the orbit, then selects.
  Future<void> _applyScanSelection(DeviceScanSelection selection) async {
    final selected = selection.selected;
    final deviceRoutes = selection.allRoutes
        .where((route) => route.isSameDevice(selected))
        .toList();

    setState(() {
      // Drop stale paths for this device (e.g. old LAN after leaving Wi‑Fi).
      _orbitPeers =
          _orbitPeers.where((s) => !s.peer.isSameDevice(selected)).toList();

      for (final route in deviceRoutes) {
        _orbitPeers = [
          OrbitSatellite(
            peer: route,
            angleDegrees: OrbitSatellite.pickAngle(_orbitPeers),
          ),
          ..._orbitPeers,
        ].take(OrbitSatellite.maxVisible).toList();
      }
    });

    await _applySelectedPeer(selected);
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
        await NetworkDiagnosticsDialog.show(
          context,
          report: report,
          targetIP: diagTargetIP,
          targetPort: diagTargetPort,
          onClose: _enableFocusNodes,
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
    if (_hasRelayPeerTarget()) {
      return isServerRunning && !isSending;
    }
    return isServerRunning && !isSending && _hasValidLanTarget();
  }

  /// Request clipboard content from target device
  Future<void> _requestClipboard() async {
    final peer = _peerForSend();
    if (peer == null) {
      return;
    }

    _disableFocusNodes();

    try {
      final portText = _portController.text.trim();
      final port = int.tryParse(portText);

      await _clipboardController.syncClipboardFromPeer(
        context: context,
        peer: peer,
        targetPort: port,
        secretKey: _secretKeyController.text.trim(),
        onSuccess: () async {
          if (mounted && peer.hasLan) {
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
