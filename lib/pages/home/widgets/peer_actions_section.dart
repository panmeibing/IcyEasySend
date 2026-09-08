import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../transport/transport_channel.dart';
import '../home_ui.dart';
import 'channel_badge.dart';

/// Scan / clipboard / diagnostics — layout adapts to [HomeBreakpoint].
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
      color: HomeUi.primarySoft,
      borderRadius: BorderRadius.circular(HomeUi.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ChannelBadge.forPeer(selectedPeer!, iconSize: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                messages.selectedRelayPeer(label),
                style: HomeUi.bodyStyle,
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

  /// Narrow screens: full-width rows so Chinese labels never ellipsize.
  Widget _buildNarrowActions(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: isServerRunning ? onScan : null,
          icon: const Icon(Icons.search_rounded, size: 20),
          label: Text(l10n.scanDevices),
          style: HomeUi.softFilledButton(enabled: isServerRunning),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: canRequestClipboard ? onClipboard : null,
          icon: const Icon(Icons.content_paste_rounded, size: 20),
          label: Text(l10n.syncClipboard),
          style: HomeUi.softOutlinedButton(),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isServerRunning ? onDiagnostics : null,
          icon: const Icon(Icons.network_check_rounded, size: 20),
          label: Text(l10n.networkDiagnostics),
          style: HomeUi.softOutlinedButton(),
        ),
      ],
    );
  }

  /// Wide screens: compact three-up with icon above label.
  Widget _buildWideActions(AppLocalizations l10n) {
    Widget stacked({
      required VoidCallback? onPressed,
      required IconData icon,
      required String label,
      required bool filled,
      required bool enabled,
    }) {
      final style = (filled
              ? HomeUi.softFilledButton(enabled: enabled)
              : HomeUi.softOutlinedButton())
          .copyWith(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        ),
      );

      final child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      );

      if (filled) {
        return FilledButton(
          onPressed: onPressed,
          style: style,
          child: child,
        );
      }
      return OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: stacked(
            onPressed: isServerRunning ? onScan : null,
            icon: Icons.search_rounded,
            label: l10n.scanDevices,
            filled: true,
            enabled: isServerRunning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: stacked(
            onPressed: canRequestClipboard ? onClipboard : null,
            icon: Icons.content_paste_rounded,
            label: l10n.syncClipboard,
            filled: false,
            enabled: canRequestClipboard,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: stacked(
            onPressed: isServerRunning ? onDiagnostics : null,
            icon: Icons.network_check_rounded,
            label: l10n.networkDiagnostics,
            filled: false,
            enabled: isServerRunning,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final metrics = HomeLayoutScope.of(context);
    final relayLabel = _selectedRelayPeerLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        metrics.isNarrow
            ? _buildNarrowActions(l10n)
            : _buildWideActions(l10n),
        if (relayLabel != null) ...[
          const SizedBox(height: 12),
          _buildSelectedRelayPeerChip(relayLabel, l10n),
        ],
      ],
    );
  }
}
