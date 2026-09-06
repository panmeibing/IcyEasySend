import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../transport/transport_channel.dart';
import 'channel_badge.dart';

/// Scan / diagnostics / clipboard actions and selected relay peer chip.
class PeerActionsSection extends StatelessWidget {
  final bool isServerRunning;
  final bool canRequestClipboard;
  final PeerRef? selectedPeer;
  final VoidCallback onScan;
  final VoidCallback onDiagnostics;
  final VoidCallback onClipboard;
  final VoidCallback onClearPeer;

  const PeerActionsSection({
    super.key,
    required this.isServerRunning,
    required this.canRequestClipboard,
    required this.selectedPeer,
    required this.onScan,
    required this.onDiagnostics,
    required this.onClipboard,
    required this.onClearPeer,
  });

  String? _selectedRelayPeerLabel() {
    final peer = selectedPeer;
    if (peer == null || peer.hasLan || !peer.relayOnline) {
      return null;
    }
    if (peer.deviceName != null && peer.deviceName!.isNotEmpty) {
      return peer.deviceName;
    }
    final id = peer.deviceId;
    if (id == null || id.isEmpty) {
      return null;
    }
    return id.length <= 8 ? id : '${id.substring(0, 8)}…';
  }

  Widget _buildSelectedRelayPeerChip(String label, AppLocalizations messages) {
    return Material(
      color: Colors.blue.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ChannelBadge.forPeer(selectedPeer!, iconSize: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                messages.selectedRelayPeer(label),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: onClearPeer,
              child: Text(messages.clearSelectedPeer),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final relayLabel = _selectedRelayPeerLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: isServerRunning ? onScan : null,
          icon: const Icon(Icons.search),
          label: Text(l10n.scanDevices),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            foregroundColor: Colors.blue,
            side: BorderSide(
              color: isServerRunning ? Colors.blue : Colors.grey,
            ),
          ),
        ),
        if (relayLabel != null) ...[
          const SizedBox(height: 12),
          _buildSelectedRelayPeerChip(relayLabel, l10n),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: isServerRunning ? onDiagnostics : null,
          icon: const Icon(Icons.network_check),
          label: Text(l10n.networkDiagnostics),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            foregroundColor: Colors.blue,
            side: BorderSide(
              color: isServerRunning ? Colors.blue : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: canRequestClipboard ? onClipboard : null,
          icon: const Icon(Icons.content_paste),
          label: Text(l10n.syncClipboard),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            foregroundColor: Colors.blue,
            side: BorderSide(
              color: canRequestClipboard ? Colors.blue : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
