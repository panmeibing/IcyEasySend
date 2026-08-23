import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/discovered_device.dart';
import '../../../services/device_discovery_service.dart';
import '../../../services/paired_device_store.dart';
import '../../../services/relay/relay_service.dart';
import '../../../transport/peer_directory.dart';
import '../../../transport/transport_channel.dart';
import 'channel_badge.dart';

/// Dialog for picking a peer: LAN discoveries merged with relay-online paired
/// devices, one row per [PeerRef.deviceId].
class DeviceScanDialog extends StatefulWidget {
  final Set<String> localIps;

  /// When false, only LAN-reachable peers are listed (LAN pairing needs an IP).
  final bool includeRelayPeers;

  const DeviceScanDialog({
    super.key,
    required this.localIps,
    this.includeRelayPeers = true,
  });

  @override
  State<DeviceScanDialog> createState() => _DeviceScanDialogState();
}

class _DeviceScanDialogState extends State<DeviceScanDialog> {
  final DeviceDiscoveryService _discoveryService = DeviceDiscoveryService();

  List<PeerRef> _peers = [];
  bool _isScanning = true;
  int _scannedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _discoveryService.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _peers = [];
      _scannedCount = 0;
      _totalCount = 0;
    });

    try {
      final devices = await _discoveryService.scan(
        localIps: widget.localIps,
        onProgress: (scanned, total, found) {
          if (!mounted) return;
          setState(() {
            _scannedCount = scanned;
            _totalCount = total;
          });
          unawaited(_rebuildPeers(found, persistLanHints: false));
        },
      );

      if (!mounted) return;
      await _rebuildPeers(devices, persistLanHints: true);
      if (!mounted) return;
      setState(() => _isScanning = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isScanning = false);
    }
  }

  Future<void> _rebuildPeers(
    List<DiscoveredDevice> discovered, {
    required bool persistLanHints,
  }) async {
    final paired = await PairedDeviceStore.instance.loadAll();
    final online = widget.includeRelayPeers
        ? RelayService.instance.client.onlinePeers
        : const <String>{};

    if (persistLanHints) {
      for (final device in discovered) {
        final id = device.deviceId;
        if (id == null || id.isEmpty) {
          continue;
        }
        await PairedDeviceStore.instance.touch(
          id,
          deviceName: device.deviceName,
          lastSeenLan: device.displayAddress,
        );
      }
    }

    final peers = PeerDirectory.merge(
      discovered: discovered,
      paired: paired,
      onlinePeers: online,
    );

    final visible = widget.includeRelayPeers
        ? peers
        : peers.where((p) => p.hasLan).toList();

    if (!mounted) return;
    setState(() => _peers = visible);
  }

  void _selectPeer(PeerRef peer) {
    Navigator.of(context).pop(peer);
  }

  void _cancel() {
    _discoveryService.cancel();
    Navigator.of(context).pop();
  }

  String _shortId(String deviceId) => deviceId.length <= 8
      ? deviceId
      : '${deviceId.substring(0, 4)}-${deviceId.substring(4, 8)}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.devices, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.scanDevicesTitle)),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isScanning) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(
                _totalCount > 0
                    ? l10n.scanProgress(
                        _scannedCount,
                        _totalCount,
                        _peers.length,
                      )
                    : l10n.scanningDevices,
                textAlign: TextAlign.center,
              ),
              if (_peers.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPeerList(),
              ],
            ] else if (_peers.isEmpty) ...[
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                l10n.noDevicesFound,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noDevicesFoundHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ] else ...[
              Text(
                l10n.scanDevicesFound(_peers.length),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              _buildPeerList(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isScanning ? _cancel : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        if (!_isScanning)
          ElevatedButton(
            onPressed: _startScan,
            child: Text(l10n.rescan),
          ),
      ],
    );
  }

  Widget _buildPeerList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _peers.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final peer = _peers[index];
          final base = peer.hasLan
              ? peer.lan!.address
              : (peer.deviceId == null ? '' : _shortId(peer.deviceId!));
          final subtitle = peer.relayOnline && !peer.hasLan
              ? (base.isEmpty ? 'relay' : '$base · relay')
              : peer.relayOnline
              ? '$base · LAN + relay'
              : base;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: ChannelBadge.forPeer(peer),
            ),
            title: Text(
              peer.deviceName?.isNotEmpty == true
                  ? peer.deviceName!
                  : peer.describe(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectPeer(peer),
          );
        },
      ),
    );
  }
}
