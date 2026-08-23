import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/relay_config.dart';
import '../../../services/preferences_service.dart';
import '../../../services/relay/relay_client.dart';
import '../../../services/relay/relay_service.dart';
import '../../../utils/relay_message_provider.dart';
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
  final RelayMessages _messages = RelayMessages.instance;
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
    setState(() => _urlError = _messages.invalidUrl);
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
      ToastHelper.showSuccess(context, _messages.saved);
    } else {
      ToastHelper.showError(context, _messages.saveFailed);
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
      ToastHelper.showSuccess(context, _messages.testSucceeded);
    } else {
      ToastHelper.showError(context, result.errorMessage ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    _messages.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _messages.description,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            _buildNotice(
              icon: Icons.lock_outline,
              color: Colors.green,
              text: _messages.encryptionNotice,
            ),
            if (Platform.isIOS) ...[
              const SizedBox(height: 8),
              _buildNotice(
                icon: Icons.info_outline,
                color: Colors.blueGrey,
                text: _messages.iosForegroundNotice,
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_messages.enableLabel),
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
                if (!mounted) return;
                if (saved) {
                  ToastHelper.showSuccess(context, _messages.saved);
                } else {
                  setState(() => _enabled = !value);
                  ToastHelper.showError(context, _messages.saveFailed);
                }
              },
            ),
            // Saved on the spot rather than with the rest of the form: it is a
            // standing policy about who may reach this device, not part of the
            // server settings being edited.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_messages.acceptPairingLabel),
              subtitle: Text(
                _messages.acceptPairingHint,
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
                labelText: _messages.serverUrlLabel,
                hintText: 'https://relay.example.com',
                errorText: _urlError,
                helperText: insecure ? _messages.insecureUrlWarning : null,
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
                labelText: _messages.tokenLabel,
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
                  label: Text(_messages.testConnection),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _testing ? null : _save,
                  child: Text(_messages.save),
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

  Widget _buildStatusChip() {
    final (label, color) = switch (_state) {
      RelayConnectionState.connected => (_messages.statusConnected, Colors.green),
      RelayConnectionState.connecting => (_messages.statusConnecting, Colors.blue),
      RelayConnectionState.reconnecting => (
        _messages.statusReconnecting,
        Colors.orange,
      ),
      RelayConnectionState.rejected => (_messages.statusRejected, Colors.red),
      RelayConnectionState.disabled => (_messages.statusDisabled, Colors.grey),
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
