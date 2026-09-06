/// Pairing strings, resolved through [appText].
///
/// Kept as a named entry point so pairing code does not have to reach for
/// `AppLocalizations` by name; the translations themselves live in the ARBs.
library;

import '../l10n/current_localizations.dart';

class PairingMessages {
  static final PairingMessages instance = PairingMessages._();

  factory PairingMessages() => instance;

  PairingMessages._();

  String get peerUnreachable => appText.peerUnreachable;
  String get peerUnsupported => appText.peerUnsupported;
  String get identityMismatch => appText.identityMismatch;
  String get cannotPairSelf => appText.cannotPairSelf;
  String get pairingTitle => appText.pairingTitle;
  String get compareHint => appText.compareHint;
  String get compareHintRelay => appText.compareHintRelay;
  String get pairOverRelay => appText.pairOverRelay;
  String get enterDeviceCode => appText.enterDeviceCode;
  String get invalidDeviceCode => appText.invalidDeviceCode;
  String get alreadyPaired => appText.alreadyPaired;
  String get peerAlreadyPaired => appText.peerAlreadyPaired;
  String get relayUnavailable => appText.relayUnavailable;
  String get peerBusy => appText.peerBusy;
  String get peerPairingBlocked => appText.peerPairingBlocked;
  String get peerRelayPairingOff => appText.peerRelayPairingOff;
  String incomingRequest(String deviceName) =>
      appText.incomingRequest(deviceName);
  String outgoingRequest(String deviceName) =>
      appText.outgoingRequest(deviceName);
  String get waitingPeer => appText.waitingPeer;
  String get peerAccepted => appText.peerAccepted;
  String get peerRejected => appText.peerRejected;
  String get peerTimeout => appText.peerTimeout;
  String get pairingFailed => appText.pairingFailed;
  String pairingSucceeded(String deviceName) =>
      appText.pairingSucceeded(deviceName);
  String get codesMatch => appText.codesMatch;
  String get codesDiffer => appText.codesDiffer;
  String get blockPeer => appText.blockPeer;
  String get pairingBlocklistTitle => appText.pairingBlocklistTitle;
  String get pairingBlocklistEmpty => appText.pairingBlocklistEmpty;
  String get pairingBlocklistManage => appText.pairingBlocklistManage;
  String get unblockPeer => appText.unblockPeer;
  String unblockPeerConfirm(String name) => appText.unblockPeerConfirm(name);
  String get pairedDevicesTitle => appText.pairedDevicesTitle;
  String get pairedDevicesEmpty => appText.pairedDevicesEmpty;
  String get addPairedDevice => appText.addPairedDevice;
  String get unpair => appText.unpair;
  String unpairConfirm(String deviceName) => appText.unpairConfirm(deviceName);
  String get deviceCodeLabel => appText.deviceCodeLabel;
}
