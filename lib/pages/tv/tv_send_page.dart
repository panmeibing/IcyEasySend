import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/transfer_file_item.dart';
import '../../services/device_discovery_service.dart';
import '../../services/http_server_manager.dart';
import '../../services/paired_device_store.dart';
import '../../services/permission_service.dart';
import '../../services/relay/relay_service.dart';
import '../../transport/peer_directory.dart';
import '../../transport/transport_channel.dart';
import '../../ui/form_factor.dart';
import '../../utils/constants.dart';
import '../../utils/format_util.dart';
import '../../utils/network_util.dart';
import '../../utils/toast_helper.dart';
import '../home/controllers/file_transfer_controller.dart';
import '../home/controllers/web_share_controller.dart';
import '../home/home_ui.dart';
import 'tv_file_browser.dart';
import 'tv_widgets.dart';

class TvSendPage extends StatefulWidget {
  final HTTPServerManager serverManager;

  const TvSendPage({super.key, required this.serverManager});

  @override
  State<TvSendPage> createState() => _TvSendPageState();
}

class _TvSendPageState extends State<TvSendPage> {
  final DeviceDiscoveryService _discovery = DeviceDiscoveryService();
  final FileTransferController _transfer = FileTransferController();
  final WebShareController _webShare = WebShareController();

  List<PeerRef> _peers = [];
  PeerRef? _selected;
  List<TransferFileItem> _files = [];
  bool _scanning = true;
  bool _sending = false;
  bool _sharing = false;
  double _progress = 0;
  String _status = '';

  @override
  void initState() {
    super.initState();
    unawaited(_scan());
  }

  @override
  void dispose() {
    _discovery.cancel();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _peers = [];
    });
    try {
      final localIps = await NetworkUtil.getLocalPrivateIPs();
      final found = await _discovery.scan(localIps: localIps);
      if (!mounted) return;
      final paired = await PairedDeviceStore.instance.loadAll();
      final routes = PeerDirectory.expandRoutes(
        PeerDirectory.merge(
          discovered: found,
          paired: paired,
          onlinePeers: RelayService.instance.client.onlinePeers,
        ),
      );
      if (!mounted) return;
      setState(() {
        _peers = routes;
        _scanning = false;
        if (_selected != null &&
            !routes.any((peer) => peer.isSameRoute(_selected!))) {
          _selected = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _scanning = false);
    }
  }

  Future<void> _enterAddress() async {
    final l10n = AppLocalizations.of(context);
    final text = await showTvTextPrompt(
      context,
      title: l10n.tvEnterAddress,
      label: l10n.tvAddressLabel,
    );
    if (text == null || text.isEmpty || !mounted) return;
    setState(() {
      _selected = PeerRef.lanAddress(text);
    });
  }

  Future<void> _pickFiles() async {
    final l10n = AppLocalizations.of(context);
    try {
      final List<TransferFileItem> picked;
      if (Platform.isAndroid && AppFormFactor.isTv) {
        picked = await _pickFilesOnTv();
      } else {
        if (!context.mounted) return;
        picked = await _transfer.selectFiles(context);
      }
      if (!mounted) return;
      if (picked.isEmpty) return;
      setState(() => _files = picked);
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, l10n.tvPickerUnavailable);
    }
  }

  /// The system document picker is missing on this TV, so browse local files.
  Future<List<TransferFileItem>> _pickFilesOnTv() async {
    final permission = PermissionService();
    if (!await permission.hasStoragePermission()) {
      final result = await permission.requestStoragePermission();
      if (!result.granted || !mounted) return [];
    }
    if (!mounted) return [];
    final paths = await showTvFileBrowser(context);
    if (paths == null || paths.isEmpty || !mounted) return [];
    return _transfer.validateDroppedPaths(context, paths);
  }

  Future<void> _send() async {
    final peer = _selected;
    if (peer == null || _files.isEmpty || _sending) return;
    final port = peer.lan?.port ?? AppConstants.defaultPort;
    final ip = peer.lan?.ip ?? '';
    await _transfer.sendFiles(
      context: context,
      files: _files,
      targetIP: ip,
      targetPort: port,
      peer: peer,
      onProgress: (progress, bytes, total) {
        if (!mounted) return;
        setState(() => _progress = progress);
      },
      onFileProgress: (index, progress, bytes, total) {},
      onStatusChange: (status) {
        if (!mounted) return;
        setState(() => _status = status);
      },
      onTransferStart: () {
        if (!mounted) return;
        setState(() {
          _sending = true;
          _progress = 0;
        });
      },
      onTransferEnd: () {
        if (!mounted) return;
        setState(() => _sending = false);
      },
      onHistoryUpdated: widget.serverManager.refreshHistory,
    );
  }

  Future<void> _share() async {
    await _webShare.shareViaQr(
      context: context,
      selectedItems: _files,
      serverManager: widget.serverManager,
      onCreatingStart: () {
        if (mounted) setState(() => _sharing = true);
      },
      onCreatingEnd: () {
        if (mounted) setState(() => _sharing = false);
      },
      disableFocusNodes: () {},
      enableFocusNodes: () {},
      isMounted: () => mounted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = _selected;
    final canSend = selected != null && _files.isNotEmpty && !_sending;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(l10n.scanDevices, style: HomeUi.sectionTitleStyle),
                  const Spacer(),
                  TvButton(
                    label: l10n.scanDevices,
                    onPressed: () {
                      if (!_scanning) _scan();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _scanning
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          l10n.tvScanning,
                          style: const TextStyle(fontSize: 18),
                        ),
                      )
                    : _peers.isEmpty
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          l10n.tvNoDevices,
                          style: const TextStyle(
                            fontSize: 18,
                            color: HomeUi.inkMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _peers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final peer = _peers[index];
                          final address =
                              peer.lan?.address ?? peer.channelLabel ?? '';
                          return TvRow(
                            title: peer.deviceName ?? address,
                            subtitle: address,
                            selected:
                                selected != null && peer.isSameRoute(selected),
                            onPressed: () => setState(() => _selected = peer),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selected == null
                    ? l10n.sendFiles
                    : (selected.deviceName ?? selected.describe()),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: HomeUi.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _files.isEmpty
                    ? l10n.noFilesSelected
                    : l10n.filesSelected(_files.length),
                style: const TextStyle(fontSize: 16, color: HomeUi.inkMuted),
              ),
              if (_files.isNotEmpty)
                Text(
                  FormatUtil.formatBytes(
                    _files.fold<int>(0, (sum, item) {
                      try {
                        return sum + item.file.lengthSync();
                      } catch (_) {
                        return sum;
                      }
                    }),
                  ),
                  style: const TextStyle(fontSize: 16, color: HomeUi.inkMuted),
                ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_status, style: const TextStyle(fontSize: 16)),
              ],
              if (_sending) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                ),
              ],
              const SizedBox(height: 16),
              TvButton(
                label: l10n.tvChooseFiles,
                onPressed: _sending ? null : _pickFiles,
              ),
              const SizedBox(height: 10),
              TvButton(
                label: l10n.tvEnterAddress,
                onPressed: _sending ? null : _enterAddress,
              ),
              const SizedBox(height: 10),
              TvButton(
                label: l10n.startSending,
                primary: true,
                onPressed: canSend ? _send : null,
              ),
              const SizedBox(height: 10),
              TvButton(
                label: l10n.shareViaQr,
                onPressed:
                    _webShare.canShareViaQr(
                      isServerRunning: widget.serverManager.isRunning(),
                      isSending: _sending,
                      isCreatingWebShare: _sharing,
                      hasSelectedItems: _files.isNotEmpty,
                    )
                    ? _share
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
