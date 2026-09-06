/// Relay UI and clipboard strings, resolved through [appText].
library;

import '../l10n/current_localizations.dart';

class RelayMessages {
  static final RelayMessages instance = RelayMessages._();

  factory RelayMessages() => instance;

  RelayMessages._();

  String get title => appText.title;
  String get description => appText.description;
  String get encryptionNotice => appText.encryptionNotice;
  String get acceptPairingLabel => appText.acceptPairingLabel;
  String get acceptPairingHint => appText.acceptPairingHint;
  String get iosForegroundNotice => appText.iosForegroundNotice;
  String get enableLabel => appText.enableLabel;
  String get serverUrlLabel => appText.serverUrlLabel;
  String get tokenLabel => appText.tokenLabel;
  String get invalidUrl => appText.invalidUrl;
  String get insecureUrlWarning => appText.insecureUrlWarning;
  String get testConnection => appText.testConnection;
  String get testSucceeded => appText.testSucceeded;
  String get save => appText.save;
  String get saved => appText.saved;
  String get saveFailed => appText.saveFailed;
  String get statusDisabled => appText.statusDisabled;
  String get statusConnecting => appText.statusConnecting;
  String get statusConnected => appText.statusConnected;
  String get statusReconnecting => appText.statusReconnecting;
  String get statusRejected => appText.statusRejected;
  String get clipboardNeedsPairing => appText.clipboardNeedsPairing;
  String get clipboardRelayUnavailable => appText.clipboardRelayUnavailable;
  String get clipboardPeerOffline => appText.clipboardPeerOffline;
  String get clipboardFailed => appText.clipboardFailed;
  String get clipboardPeerNoUi => appText.clipboardPeerNoUi;
  String get clipboardPeerBusy => appText.clipboardPeerBusy;
  String get clipboardEmpty => appText.clipboardEmpty;
  String get clipboardTooLargeForRelay => appText.clipboardTooLargeForRelay;
  String get clipboardStreamFailed => appText.clipboardStreamFailed;
  String get clipboardPeerTimeout => appText.clipboardPeerTimeout;
  String get clipboardDeclined => appText.clipboardDeclined;
  String selectedRelayPeer(String name) => appText.selectedRelayPeer(name);
  String get clearSelectedPeer => appText.clearSelectedPeer;
}
