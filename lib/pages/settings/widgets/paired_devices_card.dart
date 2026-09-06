import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/paired_device.dart';
import '../../../services/identity_service.dart';
import '../../../services/pairing_service.dart';
import '../../../services/paired_device_store.dart';
import '../../../services/preferences_service.dart';
import '../../../services/relay/relay_client.dart';
import '../../../services/relay/relay_service.dart';
import '../../../models/relay_blocked_peer.dart';
import '../../../utils/constants.dart';
import '../../../utils/dialog_helper.dart';
import '../../../utils/log_util.dart';
import '../../../utils/network_util.dart';
import '../../../transport/transport_channel.dart';
import '../../home/widgets/channel_badge.dart';
import '../../home/widgets/device_scan_dialog.dart';
import '../../pairing/pairing_confirm_dialog.dart';

/// Trusted device list, plus the entry point for pairing a new one.
///
/// Owns its own state rather than going through the settings controllers,
/// because the list also changes from outside this page: an inbound pairing
/// confirmed on this device writes to the store directly.
class PairedDevicesCard extends StatefulWidget {
  const PairedDevicesCard({super.key});

  @override
  State<PairedDevicesCard> createState() => _PairedDevicesCardState();
}

class _PairedDevicesCardState extends State<PairedDevicesCard> {
  final PairedDeviceStore _store = PairedDeviceStore.instance;

  StreamSubscription<List<PairedDevice>>? _subscription;
  StreamSubscription<RelayPresenceEvent>? _presenceSubscription;
  List<PairedDevice> _devices = [];
  Set<String> _onlinePeers = {};
  String? _localDeviceId;
  bool _pairing = false;

  @override
  void initState() {
    super.initState();
    _subscription = _store.changes.listen((devices) {
      if (!mounted) return;
      setState(() => _devices = devices);
    });
    _onlinePeers = Set<String>.from(RelayService.instance.client.onlinePeers);
    _presenceSubscription =
        RelayService.instance.client.presenceChanges.listen((event) {
      if (!mounted) return;
      setState(() {
        if (event.online) {
          _onlinePeers.add(event.deviceId);
        } else {
          _onlinePeers.remove(event.deviceId);
        }
      });
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _presenceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final devices = await _store.loadAll();
    String? deviceId;
    try {
      deviceId = await IdentityService.instance.getDeviceId();
    } catch (e) {
      LogUtil.wTag(LogTags.pairing, '读取本机设备码失败: $e');
    }
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _localDeviceId = deviceId;
    });
  }

  /// LAN pairing entry point.
  ///
  /// Intentionally unused while the "pair new device" button is hidden: LAN
  /// transfers do not require pairing today. Kept so the button can be restored
  /// without rewriting the flow.
  // ignore: unused_element
  Future<void> _startPairing() async {
    final localIps = await NetworkUtil.getLocalPrivateIPs();
    if (!mounted) return;

    final target = await showDialog<PeerRef>(
      context: context,
      builder: (_) => DeviceScanDialog(
        localIps: localIps,
        includeRelayPeers: false,
      ),
    );
    if (target == null || !mounted || target.lan == null) return;

    setState(() => _pairing = true);
    final prepared = await PairingService.instance.prepare(
      target.lan!.address,
    );
    if (!mounted) return;
    setState(() => _pairing = false);

    if (!prepared.isSuccess) {
      await DialogHelper.showErrorDialog(
        context,
        title: AppLocalizations.of(context).pairingFailed,
        message: prepared.errorMessage!,
        confirmText: AppLocalizations.of(context).confirm,
      );
      return;
    }

    final handshake = prepared.data!;
    final paired = await PairingConfirmDialog.showOutgoing(
      context,
      handshake: handshake,
    );
    if (!mounted || !paired) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).pairingSucceeded(handshake.peerDeviceName)),
      ),
    );
  }

  /// Pairing with a device that is not on this network (method B).
  ///
  /// The device code has to arrive out of band — read aloud, messaged, or
  /// scanned — and is checked against the public key that comes back, so a
  /// relay cannot answer on behalf of the device the user meant.
  Future<void> _startRelayPairing() async {
    final deviceCode = await showDialog<String>(
      context: context,
      builder: (_) => const _DeviceCodePrompt(),
    );
    if (deviceCode == null || deviceCode.isEmpty || !mounted) return;

    setState(() => _pairing = true);
    final proposed = await RelayService.instance.pairing.request(deviceCode);
    if (!mounted) return;
    setState(() => _pairing = false);

    if (!proposed.isSuccess) {
      await DialogHelper.showErrorDialog(
        context,
        title: AppLocalizations.of(context).pairingFailed,
        message: proposed.errorMessage!,
        confirmText: AppLocalizations.of(context).confirm,
      );
      return;
    }

    final proposal = proposed.data!;
    final agreed = await PairingConfirmDialog.showRelayOutgoing(
      context,
      peerDeviceName: proposal.peerDeviceName.isEmpty
          ? proposal.peerDeviceId
          : proposal.peerDeviceName,
      sas: proposal.sas,
      peerDecision: proposal.peerDecision,
    );

    // When the peer rejects/blocks, the dialog closes itself immediately —
    // surface that as an error so it does not look like a mysterious flash.
    if (!agreed) {
      final peerDecision = await _settledPeerDecision(proposal.peerDecision);
      await proposal.finish(false);
      if (!mounted) return;
      final message = switch (peerDecision) {
        PairingPeerDecision.rejected => AppLocalizations.of(context).peerRejected,
        PairingPeerDecision.blocked => AppLocalizations.of(context).peerPairingBlocked,
        PairingPeerDecision.timeout => AppLocalizations.of(context).peerTimeout,
        _ => null,
      };
      if (message != null) {
        await DialogHelper.showErrorDialog(
          context,
          title: AppLocalizations.of(context).pairingFailed,
          message: message,
          confirmText: AppLocalizations.of(context).confirm,
        );
      }
      return;
    }

    final paired = await proposal.finish(true);
    if (!mounted || !paired) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).pairingSucceeded(proposal.peerDeviceName)),
      ),
    );
  }

  /// Non-blocking peek: if the peer has already decided, return it; otherwise
  /// null (local cancel / still waiting).
  Future<PairingPeerDecision?> _settledPeerDecision(
    Future<PairingPeerDecision> peerDecision,
  ) async {
    try {
      return await peerDecision.timeout(Duration.zero);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _unpair(PairedDevice device) async {
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: AppLocalizations.of(context).unpair,
      message: AppLocalizations.of(context).unpairConfirm(device.deviceName),
      confirmText: AppLocalizations.of(context).unpair,
      cancelText: AppLocalizations.of(context).cancel,
      icon: Icons.link_off,
      iconColor: Colors.orange,
    );
    if (!confirmed) return;
    await _store.remove(device.deviceId);
  }

  Future<void> _showBlocklist() async {
    final preferences = PreferencesService();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _RelayPairBlocklistDialog(
          preferences: preferences,
          messages: AppLocalizations.of(context),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF2196F3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).pairedDevicesTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (_localDeviceId != null) ...[
              const SizedBox(height: 16),
              _buildLocalIdentity(),
            ],
            const SizedBox(height: 16),
            if (_devices.isEmpty)
              Text(
                AppLocalizations.of(context).pairedDevicesEmpty,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              )
            else
              ..._devices.map(_buildDeviceTile),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                // LAN "pair new device" is hidden for now: on the local
                // network, file transfer does not require pairing, so this
                // entry looked useful but had no effect on everyday use.
                // Keep [_startPairing] and the button wiring below so we can
                // re-enable it when LAN pairing becomes a real prerequisite
                // (e.g. encryption / auto-accept).
                // OutlinedButton.icon(
                //   onPressed: _pairing ? null : _startPairing,
                //   icon: _pairing
                //       ? const SizedBox(
                //           width: 16,
                //           height: 16,
                //           child: CircularProgressIndicator(strokeWidth: 2),
                //         )
                //       : const Icon(Icons.add_link, size: 18),
                //   label: Text(AppLocalizations.of(context).addPairedDevice),
                // ),
                OutlinedButton.icon(
                  onPressed: _pairing ? null : _startRelayPairing,
                  icon: const Icon(Icons.cloud_sync_outlined, size: 18),
                  label: Text(AppLocalizations.of(context).pairOverRelay),
                ),
                OutlinedButton.icon(
                  onPressed: _pairing ? null : _showBlocklist,
                  icon: const Icon(Icons.block, size: 18),
                  label: Text(AppLocalizations.of(context).pairingBlocklistManage),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalIdentity() {
    final deviceId = _localDeviceId!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).deviceCodeLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                deviceId,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.copy, size: 18, color: Colors.grey[600]),
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: deviceId)),
        ),
      ],
    );
  }

  Widget _buildDeviceTile(PairedDevice device) {
    final online = _onlinePeers.contains(device.deviceId);
    final hasLanHint = device.lastSeenLan != null && device.lastSeenLan!.isNotEmpty;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        child: ChannelBadge(
          hasLan: hasLanHint,
          hasRelay: online,
          iconSize: 18,
        ),
      ),
      title: Text(
        device.deviceName.isEmpty ? device.shortDeviceId : device.deviceName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          device.shortDeviceId,
          if (hasLanHint) device.lastSeenLan!,
          if (online) 'relay',
        ].join(' · '),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.link_off, size: 20),
        tooltip: AppLocalizations.of(context).unpair,
        onPressed: () => _unpair(device),
      ),
    );
  }
}

/// Collects the peer's device code before a relay pairing.
class _DeviceCodePrompt extends StatefulWidget {
  const _DeviceCodePrompt();

  @override
  State<_DeviceCodePrompt> createState() => _DeviceCodePromptState();
}

class _DeviceCodePromptState extends State<_DeviceCodePrompt> {
  final TextEditingController _controller = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim().toLowerCase();
    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(code)) {
      setState(() => _error = AppLocalizations.of(context).invalidDeviceCode);
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).pairOverRelay),
      content: SizedBox(
        width: MediaQuery.of(context).size.width *
            AppConstants.dialogWidthPercent,
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 2,
          minLines: 1,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).enterDeviceCode,
            errorText: _error,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) {
            if (_error != null) {
              setState(() => _error = null);
            }
          },
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(AppLocalizations.of(context).confirm),
        ),
      ],
    );
  }
}

/// Lists peers blocked from relay pairing and lets the user unblock them.
class _RelayPairBlocklistDialog extends StatefulWidget {
  final PreferencesService preferences;
  final AppLocalizations messages;

  const _RelayPairBlocklistDialog({
    required this.preferences,
    required this.messages,
  });

  @override
  State<_RelayPairBlocklistDialog> createState() =>
      _RelayPairBlocklistDialogState();
}

class _RelayPairBlocklistDialogState extends State<_RelayPairBlocklistDialog> {
  late Future<List<RelayBlockedPeer>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.preferences.getRelayPairBlocklistEntries();
  }

  Future<void> _reload() async {
    setState(() {
      _entries = widget.preferences.getRelayPairBlocklistEntries();
    });
  }

  Future<void> _unblock(RelayBlockedPeer peer) async {
    final label = peer.deviceName.isNotEmpty ? peer.deviceName : peer.deviceId;
    final confirmed = await DialogHelper.showConfirmDialog(
      context,
      title: widget.messages.unblockPeer,
      message: widget.messages.unblockPeerConfirm(label),
      confirmText: widget.messages.unblockPeer,
      cancelText: AppLocalizations.of(context).cancel,
      icon: Icons.block,
      iconColor: Colors.orange,
    );
    if (!confirmed) return;
    await widget.preferences.unblockRelayPairing(peer.deviceId);
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text(widget.messages.pairingBlocklistTitle),
      content: SizedBox(
        width: screenWidth * AppConstants.dialogWidthPercent,
        child: FutureBuilder<List<RelayBlockedPeer>>(
          future: _entries,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final peers = snapshot.data ?? const <RelayBlockedPeer>[];
            if (peers.isEmpty) {
              return Text(
                widget.messages.pairingBlocklistEmpty,
                style: TextStyle(color: Colors.grey[600]),
              );
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: peers.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final peer = peers[index];
                  final title = peer.deviceName.isNotEmpty
                      ? peer.deviceName
                      : peer.deviceId;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(title),
                    subtitle: peer.deviceName.isNotEmpty
                        ? Text(
                            peer.deviceId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: TextButton(
                      onPressed: () => _unblock(peer),
                      child: Text(widget.messages.unblockPeer),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).close),
        ),
      ],
    );
  }
}
