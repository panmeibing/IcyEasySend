import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../l10n/current_localizations.dart';
import '../../../services/validation_service.dart';
import '../../../transport/transport_channel.dart';
import '../../../utils/constants.dart';
import '../../../utils/network_util.dart';
import 'connection_prefs_controller.dart';

enum _PortProblem { empty, notNumber, outOfRange }

/// Who Home sends to: a device picked from a scan, or the IP / port typed
/// into the manual form, plus the shared secret key and the IP history.
///
/// Owns the form's text controllers and focus nodes, validates them as they
/// change, and remembers the port and secret key as they are typed.
class TargetEndpointController extends ChangeNotifier {
  TargetEndpointController({
    ConnectionPrefsController? prefs,
    ValidationService? validationService,
  }) : _prefs = prefs ?? ConnectionPrefsController(),
       _validation = validationService ?? ValidationService() {
    ipController.addListener(_onIpEdited);
    portController.addListener(_onPortEdited);
    secretKeyController.addListener(_onSecretKeyEdited);
  }

  final ConnectionPrefsController _prefs;
  final ValidationService _validation;

  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController(
    text: '${AppConstants.defaultPort}',
  );
  final TextEditingController secretKeyController = TextEditingController();
  final FocusNode ipFocusNode = FocusNode();
  final FocusNode portFocusNode = FocusNode();
  final FocusNode secretKeyFocusNode = FocusNode();

  /// This device's address, for checking a typed IP against the local subnet.
  String? serverAddress;

  String _targetIP = '';
  String? _ipErrorMessage;
  bool _ipIsWarning = false;
  _PortProblem? _portProblem;
  bool _checkSubnet = true;
  List<String> _ipHistory = const [];
  PeerRef? _selectedPeer;
  int _ipCheckGeneration = 0;
  bool _disposed = false;

  /// The trimmed IP the last validation ran against.
  String get targetIP => _targetIP;

  /// What is wrong with the typed IP; see [ipMessageIsWarning].
  String? get ipErrorMessage => _ipErrorMessage;

  /// [ipErrorMessage] is advice that does not stop the address being used.
  bool get ipMessageIsWarning => _ipErrorMessage != null && _ipIsWarning;

  String? get portErrorMessage => switch (_portProblem) {
    null => null,
    _PortProblem.empty => appText.portCannotBeEmpty,
    _PortProblem.notNumber => appText.portMustBeNumber,
    _PortProblem.outOfRange => appText.portRange,
  };

  List<String> get ipHistory => _ipHistory;

  PeerRef? get selectedPeer => _selectedPeer;

  int? get port => NetworkUtil.parsePort(portController.text);

  String get secretKey => secretKeyController.text.trim();

  /// A scanned device that can only be reached through the relay.
  bool get hasRelayTarget {
    final peer = _selectedPeer;
    return peer != null &&
        !peer.hasLan &&
        peer.relayOnline &&
        peer.deviceId != null;
  }

  /// A usable typed address. A subnet mismatch is only a warning.
  bool get hasValidLanTarget =>
      _targetIP.isNotEmpty &&
      (_ipErrorMessage == null || _ipIsWarning) &&
      port != null;

  bool get hasTarget => hasRelayTarget || hasValidLanTarget;

  /// `ip:port` for a typed target, or null when a scanned device is selected.
  String? get manualTargetLabel {
    if (_selectedPeer != null || _targetIP.isEmpty) return null;
    final portText = portController.text.trim();
    return portText.isEmpty ? _targetIP : '$_targetIP:$portText';
  }

  /// What network diagnostics should probe, if a clean target IP is typed.
  ({String ip, int port})? get diagnosticsTarget {
    if (_targetIP.isEmpty || (_ipErrorMessage != null && !_ipIsWarning)) {
      return null;
    }
    return (ip: _targetIP, port: port ?? AppConstants.defaultPort);
  }

  /// The peer to send to, combining the scan selection with the form.
  PeerRef? peerForSend() {
    final selected = _selectedPeer;
    if (selected != null) {
      if (selected.preferredTransport == TransportKind.relay ||
          !selected.hasLan) {
        return selected;
      }
      // Keep identity and preferred path from the scan, but honour any IP
      // typed afterwards.
      if (_targetIP.isEmpty) return selected;
      return selected.copyWith(
        lan: LanEndpoint(ip: _targetIP, port: port ?? selected.lan!.port),
      );
    }

    if (!hasValidLanTarget) return null;
    return PeerRef.lanAddress('$_targetIP:$port');
  }

  /// Fills the form from what was used last time.
  Future<void> load() async {
    final saved = await _prefs.loadHomeConnectionPrefs();
    if (_disposed) return;

    _ipHistory = saved.ipHistory;
    _checkSubnet = saved.enableIPValidation;
    if (saved.lastUsedIP?.isNotEmpty ?? false) {
      ipController.text = saved.lastUsedIP!;
    }
    portController.text = saved.lastUsedPort.toString();
    if (saved.targetSecretKey?.isNotEmpty ?? false) {
      secretKeyController.text = saved.targetSecretKey!;
    }
    // Unchanged text fires no listener, so validate explicitly.
    _onPortEdited();
    await _validateIp();
  }

  /// Re-reads the subnet check setting, which lives on the settings page.
  Future<void> reloadIPValidationSetting() async {
    _checkSubnet = await _prefs.loadIPValidationEnabled();
    if (_disposed) return;
    await _validateIp();
  }

  Future<void> reloadHistory() async {
    final history = await _prefs.loadIPHistory();
    if (_disposed) return;
    _ipHistory = history;
    notifyListeners();
  }

  Future<bool> removeFromHistory(String ip) async {
    final removed = await _prefs.deleteIPFromHistory(ip);
    if (removed) await reloadHistory();
    return removed;
  }

  void useHistoryIP(String ip) => ipController.text = ip;

  void resetPort() => portController.text = '${AppConstants.defaultPort}';

  /// Targets [peer], loading its LAN address into the form when that is the
  /// route it prefers.
  void select(PeerRef peer) {
    _selectedPeer = peer;
    notifyListeners();
    if (peer.hasLan && peer.preferredTransport != TransportKind.relay) {
      ipController.text = peer.lan!.ip;
      portController.text = '${peer.lan!.port}';
    } else {
      // A stale LAN address must not linger behind a relay route.
      ipController.clear();
    }
  }

  void clearSelection() {
    if (_selectedPeer == null) return;
    _selectedPeer = null;
    notifyListeners();
  }

  /// Keeps the form from taking focus while a transfer or dialog is running.
  void lockInput() {
    for (final node in _focusNodes) {
      node.unfocus();
      node.canRequestFocus = false;
    }
  }

  /// Safe after [dispose]: a transfer can finish after Home is gone.
  void unlockInput() {
    if (_disposed) return;
    for (final node in _focusNodes) {
      node.canRequestFocus = true;
    }
  }

  List<FocusNode> get _focusNodes => [
    ipFocusNode,
    portFocusNode,
    secretKeyFocusNode,
  ];

  void _onIpEdited() {
    // Typing a different address means the scan selection no longer applies;
    // for a relay-only selection, typing anything means switching to LAN.
    final selected = _selectedPeer;
    final typed = ipController.text.trim();
    if (selected != null &&
        typed.isNotEmpty &&
        (!selected.hasLan || typed != selected.lan!.ip)) {
      _selectedPeer = null;
    }
    unawaited(_validateIp());
  }

  Future<void> _validateIp() async {
    final ip = ipController.text.trim();
    final generation = ++_ipCheckGeneration;

    if (ip.isEmpty) {
      _setIpState(ip, null, false);
      return;
    }

    final result = await _validation.validateIPv4WithSubnet(
      ip,
      serverAddress: serverAddress,
      enableValidation: _checkSubnet,
    );
    // A newer edit has superseded this check.
    if (_disposed || generation != _ipCheckGeneration) return;
    final showMessage = !result.isValid || result.isWarning;
    _setIpState(ip, showMessage ? result.errorMessage : null, result.isWarning);
  }

  void _setIpState(String ip, String? error, bool isWarning) {
    _targetIP = ip;
    _ipErrorMessage = error;
    _ipIsWarning = isWarning;
    notifyListeners();
  }

  void _onPortEdited() {
    final text = portController.text.trim();
    final parsed = int.tryParse(text);
    _portProblem = text.isEmpty
        ? _PortProblem.empty
        : parsed == null
        ? _PortProblem.notNumber
        : !NetworkUtil.isValidPort(parsed)
        ? _PortProblem.outOfRange
        : null;
    if (_portProblem == null) unawaited(_prefs.savePort(text));
    notifyListeners();
  }

  void _onSecretKeyEdited() {
    unawaited(_prefs.saveTargetSecretKey(secretKeyController.text));
  }

  @override
  void dispose() {
    _disposed = true;
    ipController.dispose();
    portController.dispose();
    secretKeyController.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
