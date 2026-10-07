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
import '../transport/transport_channel.dart';
import '../utils/constants.dart';
import '../utils/network_util.dart';
import '../utils/toast_helper.dart';
import 'home/controllers/clipboard_controller.dart';
import 'home/controllers/file_transfer_controller.dart';
import 'home/controllers/send_progress_controller.dart';
import 'home/controllers/share_intent_handler.dart';
import 'home/controllers/target_endpoint_controller.dart';
import 'home/controllers/web_share_controller.dart';
import 'home/home_ui.dart';
import 'home/widgets/device_scan_dialog.dart';
import 'home/widgets/drag_drop_overlay.dart';
import 'home/widgets/network_diagnostics_dialog.dart';
import 'home/widgets/orbit_canvas.dart';
import 'home/widgets/orbit_dock.dart';
import 'home/widgets/orbit_sheets.dart';
import 'home/widgets/orbit_status_pill.dart';
import 'home/widgets/secret_key_help_dialog.dart';

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

  List<TransferFileItem> selectedItems = [];
  bool isServerRunning = false;
  String? serverAddress;
  bool isSending = false;
  bool _isCreatingWebShare = false;
  bool _isDragging = false;

  /// Peers shown as orbit satellites (with stable random angles).
  List<OrbitSatellite> _orbitPeers = [];

  final TargetEndpointController _endpoint = TargetEndpointController();
  final SendProgressController _sendProgress = SendProgressController();
  final FileTransferController _fileTransferController =
      FileTransferController();
  final ClipboardController _clipboardController = ClipboardController();
  final CacheCleanupService _cacheCleanupService = CacheCleanupService();
  final WebShareController _webShareController = WebShareController();
  late final ShareIntentHandler _shareIntentHandler;

  StreamSubscription? _sharingIntentSubscription;

  @override
  void initState() {
    super.initState();

    _shareIntentHandler = ShareIntentHandler(
      fileTransferController: _fileTransferController,
      cacheCleanupService: _cacheCleanupService,
      sharingIntentService: widget.sharingIntentService,
    );

    // Dialog context is owned by MainContainer (stable shell). Home only
    // registers network/server status callbacks for this tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.serverManager.addNetworkChangeCallback(_onNetworkChanged);
        widget.serverManager.addServerStatusCallback(_onServerStatusChanged);
      }
    });

    _updateServerStatus();
    _endpoint.addListener(_onEndpointChanged);
    unawaited(_endpoint.load());

    // Listen for shared files while the app is already running
    _sharingIntentSubscription = widget.sharingIntentService.sharedFilesStream
        .listen((files) {
          LogUtil.iTag(logTag, '收到运行中分享: ${files.length} 个文件');
          if (files.isNotEmpty && mounted) {
            _handleSharedFiles(files);
          }
        });

    // Cold start shares are buffered before HomePage subscribes to the stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shareIntentHandler.processInitialSharedFiles(
        isMounted: () => mounted,
        handleSharedFiles: _handleSharedFiles,
      );
    });
  }

  @override
  void dispose() {
    widget.serverManager.removeNetworkChangeCallback(_onNetworkChanged);
    widget.serverManager.removeServerStatusCallback(_onServerStatusChanged);
    _sharingIntentSubscription?.cancel();
    _endpoint.dispose();
    super.dispose();
  }

  /// Called when returning from settings, where the subnet check is toggled.
  void reloadIPValidationSetting() {
    _endpoint.reloadIPValidationSetting();
  }

  void _onEndpointChanged() {
    if (mounted) setState(() {});
  }

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

  void _updateServerStatus() {
    setState(() {
      isServerRunning = widget.serverManager.isRunning();
      serverAddress = widget.serverManager.getServerAddress();
    });
    _endpoint.serverAddress = serverAddress;
  }

  bool get _canSend =>
      isServerRunning &&
      !isSending &&
      selectedItems.isNotEmpty &&
      _endpoint.hasTarget;

  bool get _canRequestClipboard =>
      isServerRunning && !isSending && _endpoint.hasTarget;

  bool get _canShareViaQr => _webShareController.canShareViaQr(
    isServerRunning: isServerRunning,
    isSending: isSending,
    isCreatingWebShare: _isCreatingWebShare,
    hasSelectedItems: selectedItems.isNotEmpty,
  );

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) {
        if (isServerRunning && !isSending) {
          setState(() => _isDragging = true);
        }
      },
      onDragExited: (details) {
        setState(() => _isDragging = false);
      },
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (!isServerRunning || isSending) return;

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
            onTap: () => FocusScope.of(context).unfocus(),
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
                        AppLocalizations.of(
                          context,
                        ).androidBackgroundReceiveHint,
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
                        selectedPeer: _endpoint.selectedPeer,
                        onCoreTap: _onOrbitCoreTap,
                        onScan: _scanDevices,
                        onPeerSelected: _selectPeer,
                      ),
                    ),
                  ),
                  OrbitDock(
                    isServerRunning: isServerRunning,
                    isSending: isSending,
                    isCreatingWebShare: _isCreatingWebShare,
                    canSend: _canSend,
                    canShareViaQr: _canShareViaQr,
                    selectedPeer: _endpoint.selectedPeer,
                    manualTargetLabel: _endpoint.manualTargetLabel,
                    progress: _sendProgress.progress,
                    progressStatus: _sendProgress.status,
                    transferSpeed: _sendProgress.speed,
                    estimatedTimeRemaining:
                        _sendProgress.estimatedTimeRemaining,
                    onMore: _showOrbitMore,
                    onSend: _sendFiles,
                    onShareViaQr: _shareViaQr,
                    onAddFiles: _onOrbitAddFiles,
                    onClearPeer: _endpoint.clearSelection,
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

  // Target selection

  void _selectPeer(PeerRef peer) {
    if (!mounted) return;
    setState(() {
      _orbitPeers = OrbitSatellite.bringToFront(_orbitPeers, peer);
    });
    _endpoint.select(peer);
  }

  /// Scan the local network via the progress dialog (with cancel).
  Future<void> _scanDevices() async {
    if (!mounted || !isServerRunning) return;

    final selection = await _withInputLocked(() async {
      // Lets the focus change land before the dialog takes over.
      await Future.delayed(const Duration(milliseconds: 100));
      final localIps = await NetworkUtil.getLocalPrivateIPs();
      if (!mounted) return null;
      return showDialog<DeviceScanSelection>(
        context: context,
        barrierDismissible: false,
        builder: (context) => DeviceScanDialog(localIps: localIps),
      );
    });
    if (selection == null || !mounted) return;

    // Every live route for the chosen device goes on the orbit.
    final selected = selection.selected;
    setState(() {
      _orbitPeers = OrbitSatellite.replaceDevice(
        _orbitPeers,
        selected,
        selection.allRoutes.where((route) => route.isSameDevice(selected)),
      );
    });
    _selectPeer(selected);
  }

  Future<void> _showOrbitMore() async {
    if (!mounted || !isServerRunning) return;
    await showOrbitMoreSheet(
      context: context,
      canRequestClipboard: _canRequestClipboard,
      onClipboard: _requestClipboard,
      onDiagnostics: _runNetworkDiagnostics,
      endpoint: _endpoint,
      isEnabled: isServerRunning,
      onIPDeleted: _deleteIPFromHistory,
      onSecretHelp: () => showSecretKeyHelpDialog(context),
    );
  }

  Future<void> _deleteIPFromHistory(String ip) async {
    final removed = await _endpoint.removeFromHistory(ip);
    if (removed && mounted) {
      ToastHelper.showSuccess(
        context,
        AppLocalizations.of(context).ipDeleted(ip),
      );
    }
  }

  // File selection

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

  Future<void> _selectFiles({required bool append}) async {
    final items = await _fileTransferController.selectFiles(context);
    await _addPickedItems(items, append: append);
  }

  /// Select a folder (all files inside will be sent)
  Future<void> _selectFolder({required bool append}) async {
    final items = await _fileTransferController.selectFolder(context);
    await _addPickedItems(items, append: append);
    if (items.isNotEmpty && mounted) {
      ToastHelper.showSuccess(
        context,
        AppLocalizations.of(context).folderFilesAdded(items.length),
      );
    }
  }

  /// Adds to or replaces the selection. Replaced shared files are deleted
  /// from the share cache.
  Future<void> _addPickedItems(
    List<TransferFileItem> items, {
    required bool append,
  }) async {
    if (items.isEmpty || !mounted) return;
    final previous = selectedItems;
    setState(() {
      selectedItems = append ? [...selectedItems, ...items] : items;
    });
    if (!append) {
      await _shareIntentHandler.cleanupShareCacheForItems(previous);
    }
  }

  void _removeSelectedFileAt(int index) {
    if (index < 0 || index >= selectedItems.length || isSending) return;
    final removed = selectedItems[index];
    setState(() => selectedItems.removeAt(index));
    _cacheCleanupService.deleteCacheFilesIfPresent([removed.file.path]);
  }

  void _clearSelectedFiles() {
    if (isSending || selectedItems.isEmpty) return;
    final previous = List<TransferFileItem>.from(selectedItems);
    setState(() => selectedItems.clear());
    unawaited(_shareIntentHandler.cleanupShareCacheForItems(previous));
  }

  /// Handle dropped paths from drag and drop (files or folders)
  Future<void> _handleDroppedPaths(List<String> paths) async {
    final validItems = await _fileTransferController.validateDroppedPaths(
      context,
      paths,
    );
    if (validItems.isNotEmpty && mounted) {
      setState(() => selectedItems.addAll(validItems));
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
        setState(() => selectedItems.addAll(items));
      },
    );
  }

  // Actions

  /// Runs [action] with the target form unable to take focus, so the
  /// keyboard does not pop up behind dialogs or during a transfer.
  Future<T> _withInputLocked<T>(Future<T> Function() action) async {
    _endpoint.lockInput();
    FocusScope.of(context).unfocus();
    try {
      return await action();
    } finally {
      _endpoint.unlockInput();
    }
  }

  /// Create a temporary web-share session and show QR for guest downloads.
  Future<void> _shareViaQr() async {
    if (!_canShareViaQr) return;

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
      disableFocusNodes: () {
        _endpoint.lockInput();
        FocusScope.of(context).unfocus();
      },
      enableFocusNodes: _endpoint.unlockInput,
      isMounted: () => mounted,
    );
  }

  /// Send the selected files to the target device
  Future<void> _sendFiles() async {
    if (!_canSend) return;
    final peer = _endpoint.peerForSend();
    if (peer == null) return;

    await _withInputLocked(
      () => _fileTransferController.sendFiles(
        context: context,
        files: selectedItems,
        targetIP: peer.lan?.ip ?? _endpoint.targetIP,
        targetPort:
            peer.lan?.port ?? _endpoint.port ?? AppConstants.defaultPort,
        peer: peer,
        secretKey: _endpoint.secretKey,
        onProgress: (progress, bytesTransferred, totalBytes) {
          // The transfer outlives this page — callbacks keep arriving after
          // the user navigates away, and every one of them calls setState.
          if (!mounted) return;
          _sendProgress.onOverallProgress(
            progress: progress,
            bytesTransferred: bytesTransferred,
            totalBytes: totalBytes,
            onUiUpdate: () => setState(() {}),
          );
        },
        onFileProgress: (fileIndex, progress, bytesTransferred, totalBytes) {
          if (!mounted) return;
          _sendProgress.onFileProgress(
            fileIndex: fileIndex,
            progress: progress,
            items: selectedItems,
            l10n: AppLocalizations.of(context),
            onUiUpdate: () => setState(() {}),
          );
        },
        onStatusChange: (status) {
          if (!mounted) return;
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
              if (mounted) setState(() => isSending = true);
            },
          );
        },
        onTransferEnd: () {
          _sendProgress.onTransferEnd(
            onUiUpdate: () {
              if (mounted) setState(() => isSending = false);
            },
            clearSelectedItems: () => selectedItems.clear(),
          );
        },
        onHistoryUpdated: widget.serverManager.refreshHistory,
      ),
    );
  }

  /// Request clipboard content from target device
  Future<void> _requestClipboard() async {
    final peer = _endpoint.peerForSend();
    if (peer == null) return;

    await _withInputLocked(
      () => _clipboardController.syncClipboardFromPeer(
        context: context,
        peer: peer,
        targetPort: _endpoint.port,
        secretKey: _endpoint.secretKey,
        onSuccess: () async {
          // A LAN sync records the address in the history.
          if (mounted && peer.hasLan) {
            await _endpoint.reloadHistory();
          }
        },
        onError: () {
          // Error already handled by controller
        },
      ),
    );
  }

  Future<void> _runNetworkDiagnostics() async {
    if (!mounted) return;
    final target = _endpoint.diagnosticsTarget;
    await _withInputLocked(() async {
      // Lets the focus change land before the loading dialog appears.
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      await NetworkDiagnosticsDialog.run(
        context,
        targetIP: target?.ip,
        targetPort: target?.port,
      );
    });
  }
}
