/// Transfer status strings, resolved through [appText].
library;

import '../l10n/current_localizations.dart';

class TransferStatusProvider {
  static final TransferStatusProvider _instance = TransferStatusProvider._();

  factory TransferStatusProvider() => _instance;

  TransferStatusProvider._();

  String get checkingTargetDevice => appText.checkingTargetDevice;
  String get preparingTransferInfo => appText.preparingTransferInfo;
  String waitingForReceiverConfirmFiles(int count) =>
      appText.waitingForReceiverConfirmFiles(count);
  String transferringFile(int current, int total, String fileName) =>
      appText.transferringFile(current, total, fileName);
  String targetDeviceError(String error) => appText.targetDeviceError(error);
  String get lanRouteUnavailable => appText.lanRouteUnavailable;
  String get relayRouteUnavailable => appText.relayRouteUnavailable;

  /// Both LAN and relay failed. Distinct from [appText.peerUnreachable], which
  /// is the pairing-side "cannot open a connection" message.
  String get peerUnreachable => appText.peerUnreachableBoth;

  String get relayNotConnected => appText.relayNotConnected;
  String get relayPeerOffline => appText.relayPeerOffline;
  String get relayPeerNotPaired => appText.relayPeerNotPaired;
  String get relayPeerBusy => appText.relayPeerBusy;
  String get relayNeedsPairedDevice => appText.relayNeedsPairedDevice;
  String get relayNegotiatingSession => appText.relayNegotiatingSession;
  String get relayIdentityMismatch => appText.relayIdentityMismatch;
  String get relayTransferNotice => appText.relayTransferNotice;
  String retryingAfterInterruption(int attempt, int maxAttempts) =>
      appText.retryingAfterInterruption(attempt, maxAttempts);
  String get receiverRejected => appText.receiverRejected;
  String receiverRejectedWithStatus(int statusCode) =>
      appText.receiverRejectedWithStatus(statusCode);
  String get transferIdNotFound => appText.transferIdNotFound;
  String get receiveComplete => appText.receiveComplete;

  /// [progress] is 0.0–1.0; the ARB message expects a percentage.
  String receivingProgress(double progress) =>
      appText.receivingProgress(progress * 100);
}
