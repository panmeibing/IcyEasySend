import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/transfer_history.dart';
import '../../services/http_server_manager.dart';
import '../../services/preferences_service.dart';
import '../../services/transfer_history_service.dart';
import '../../utils/format_util.dart';
import '../home/home_ui.dart';
import '../settings/controllers/device_controller.dart';
import 'tv_widgets.dart';

class TvReceivePage extends StatefulWidget {
  final HTTPServerManager serverManager;

  const TvReceivePage({super.key, required this.serverManager});

  @override
  State<TvReceivePage> createState() => TvReceivePageState();
}

class TvReceivePageState extends State<TvReceivePage> {
  final PreferencesService _preferences = PreferencesService();
  late final DeviceController _deviceController = DeviceController(_preferences);
  final TransferHistoryService _history = TransferHistoryService();

  String _deviceName = '';
  bool _running = false;
  String? _address;
  List<TransferHistory> _recent = [];

  @override
  void initState() {
    super.initState();
    widget.serverManager.addServerStatusCallback(_onServer);
    _load();
  }

  @override
  void dispose() {
    widget.serverManager.removeServerStatusCallback(_onServer);
    super.dispose();
  }

  void _onServer() {
    if (!mounted) return;
    setState(() {
      _running = widget.serverManager.isRunning();
      _address = widget.serverManager.getServerAddress();
    });
  }

  Future<void> refreshRecent() => _loadRecent();

  Future<void> _load() async {
    final info = await _deviceController.loadDeviceInfo();
    if (!mounted) return;
    setState(() {
      _deviceName = info['name'] ?? '';
      _running = widget.serverManager.isRunning();
      _address = widget.serverManager.getServerAddress();
    });
    await _loadRecent();
  }

  Future<void> _loadRecent() async {
    final history = await _history.loadHistory();
    if (!mounted) return;
    setState(() {
      _recent = history.where((item) => item.isReceived).take(3).toList();
    });
  }

  Future<void> _showAddress() async {
    final address = _address;
    if (address == null || address.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  address,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                    color: HomeUi.ink,
                  ),
                ),
                if (_deviceName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _deviceName,
                    style: const TextStyle(fontSize: 20, color: HomeUi.inkMuted),
                  ),
                ],
                const SizedBox(height: 24),
                TvButton(
                  label: l10n.close,
                  primary: true,
                  autofocus: true,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final address = _address;
    final canShow = _running && address != null && address.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _running ? l10n.serverRunning : l10n.serverStopped,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _running ? HomeUi.runningAccent : HomeUi.stoppedAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                canShow ? address : '—',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: HomeUi.ink,
                ),
              ),
              if (_deviceName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _deviceName,
                  style: const TextStyle(fontSize: 18, color: HomeUi.inkMuted),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                l10n.tvReceiveHint,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  color: HomeUi.inkMuted,
                ),
              ),
              const SizedBox(height: 20),
              TvButton(
                label: l10n.tvShowAddress,
                primary: true,
                // Stay enabled before the server address arrives. The nav rail
                // takes the initial focus; this button must not grab it.
                onPressed: () {
                  if (canShow) _showAddress();
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.tvRecentReceives, style: HomeUi.sectionTitleStyle),
              const SizedBox(height: 12),
              if (_recent.isEmpty)
                Text(
                  l10n.tvNoRecent,
                  style: const TextStyle(fontSize: 16, color: HomeUi.inkMuted),
                )
              else
                for (final item in _recent) ...[
                  TvRow(
                    title: item.fileName,
                    subtitle:
                        '${FormatUtil.formatBytes(item.fileSize)} · ${item.peerDeviceName ?? item.peerIP}',
                    onPressed: () => _showPath(item),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showPath(TransferHistory item) async {
    final l10n = AppLocalizations.of(context);
    final path = item.savedPath ?? l10n.filePathNotExist;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.fileName, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 8),
                Text(path, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                TvButton(
                  label: l10n.close,
                  primary: true,
                  autofocus: true,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
