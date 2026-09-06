import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/relay_config.dart';
import '../../../services/preferences_service.dart';
import '../../../services/relay/relay_client.dart';
import '../../../services/relay/relay_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/toast_helper.dart';

/// Relay server settings.
///
/// Self-contained like [PairedDevicesCard], because the connection state it
/// shows changes on its own: the client reconnects in the background whether
/// or not this page is open.
class RelayServerCard extends StatefulWidget {
  const RelayServerCard({super.key});

  @override
  State<RelayServerCard> createState() => _RelayServerCardState();
}

class _RelayServerCardState extends State<RelayServerCard> {
  final RelayService _relay = RelayService.instance;
  final PreferencesService _preferencesService = PreferencesService();

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  StreamSubscription<RelayConnectionState>? _stateSubscription;
  RelayConnectionState _state = RelayConnectionState.disabled;
  bool _enabled = false;
  bool _acceptPairing = true;
  bool _tokenVisible = false;
  bool _testing = false;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    _state = _relay.state;
    _stateSubscription = _relay.stateChanges.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await _preferencesService.getRelayConfig();
    final acceptPairing = await _preferencesService.getRelayPairingEnabled();
    if (!mounted) return;
    setState(() {
      _urlController.text = config.serverUrl;
      _tokenController.text = config.token;
      _enabled = config.enabled;
      _acceptPairing = acceptPairing;
    });
  }

  /// The settings as currently typed, which is what both saving and testing
  /// should act on — testing what is stored rather than what is on screen
  /// would make the button useless while fixing a typo.
  RelayConfig _draft({bool? enabled}) {
    return RelayConfig(
      serverUrl: _urlController.text.trim(),
      token: _tokenController.text.trim(),
      enabled: enabled ?? _enabled,
    );
  }

  bool _validate(RelayConfig config) {
    if (config.serverUrl.isEmpty || config.baseUri != null) {
      setState(() => _urlError = null);
      return config.serverUrl.isEmpty ? !config.enabled : true;
    }
    setState(() => _urlError = AppLocalizations.of(context).invalidUrl);
    return false;
  }

  Future<void> _save() async {
    final config = _draft();
    if (!_validate(config)) {
      return;
    }

    final saved = await _relay.updateConfig(config);
    if (!mounted) return;
    if (saved) {
      ToastHelper.showSuccess(context, AppLocalizations.of(context).saved);
    } else {
      ToastHelper.showError(context, AppLocalizations.of(context).saveFailed);
    }
  }

  Future<void> _test() async {
    final config = _draft(enabled: true);
    if (!_validate(config)) {
      return;
    }

    setState(() => _testing = true);
    final result = await _relay.testConnection(config);
    if (!mounted) return;

    setState(() => _testing = false);
    if (result.isSuccess) {
      ToastHelper.showSuccess(context, AppLocalizations.of(context).testSucceeded);
    } else {
      ToastHelper.showError(context, result.errorMessage ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final insecure = _urlController.text.trim().startsWith('http://');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatusChip(l10n),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.description,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            _buildNotice(
              icon: Icons.lock_outline,
              color: Colors.green,
              text: l10n.encryptionNotice,
            ),
            if (Platform.isIOS) ...[
              const SizedBox(height: 8),
              _buildNotice(
                icon: Icons.info_outline,
                color: Colors.blueGrey,
                text: l10n.iosForegroundNotice,
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.enableLabel),
              value: _enabled,
              onChanged: (value) async {
                setState(() => _enabled = value);
                // Same as the pairing policy switch: toggling must take effect
                // immediately. Leaving it as a draft until "Save" made it look
                // like the switch did nothing while the socket stayed up.
                final config = _draft(enabled: value);
                if (!_validate(config)) {
                  setState(() => _enabled = !value);
                  return;
                }
                final saved = await _relay.updateConfig(config);
                // The build context rather than the State: it is the one the
                // toast below is shown in.
                if (!context.mounted) return;
                if (saved) {
                  ToastHelper.showSuccess(context, l10n.saved);
                } else {
                  setState(() => _enabled = !value);
                  ToastHelper.showError(context, l10n.saveFailed);
                }
              },
            ),
            // Saved on the spot rather than with the rest of the form: it is a
            // standing policy about who may reach this device, not part of the
            // server settings being edited.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.acceptPairingLabel),
              subtitle: Text(
                l10n.acceptPairingHint,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              value: _acceptPairing,
              onChanged: (value) async {
                setState(() => _acceptPairing = value);
                await _preferencesService.saveRelayPairingEnabled(value);
              },
            ),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.serverUrlLabel,
                hintText: 'https://relay.example.com',
                errorText: _urlError,
                helperText: insecure ? l10n.insecureUrlWarning : null,
                helperMaxLines: 2,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() => _urlError = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              // The token is a shared secret, so it is masked by default the
              // way a password would be.
              obscureText: !_tokenVisible,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: l10n.tokenLabel,
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(
                    _tokenVisible ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _tokenVisible = !_tokenVisible),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering, size: 18),
                  label: Text(l10n.testConnection),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _testing ? null : _save,
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required MaterialColor color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AppLocalizations l10n) {
    final (label, color) = switch (_state) {
      RelayConnectionState.connected => (l10n.statusConnected, Colors.green),
      RelayConnectionState.connecting => (l10n.statusConnecting, Colors.blue),
      RelayConnectionState.reconnecting => (
        l10n.statusReconnecting,
        Colors.orange,
      ),
      RelayConnectionState.rejected => (l10n.statusRejected, Colors.red),
      RelayConnectionState.disabled => (l10n.statusDisabled, Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
