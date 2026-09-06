import 'package:flutter/widgets.dart';

/// What the local user decided when shown an incoming pairing request.
enum IncomingPairingChoice {
  /// Numbers match — proceed.
  accepted,

  /// Numbers differ / cancel — refuse without blocking.
  rejected,

  /// Explicitly block this peer from asking again over the relay.
  blocked,
}

/// How the service layer asks the user to compare pairing digits.
///
/// Inbound pairing arrives over HTTP or the relay socket, so the code that
/// needs the user's answer sits in the service layer — but the answer can only
/// come from a widget. Without this seam the services import the dialog
/// directly, which points the dependency backwards and makes the pairing
/// handshake impossible to exercise without pumping a real widget tree.
///
/// The UI layer installs the real implementation at startup; see
/// `DialogPairingPrompter` in `lib/pages/pairing/pairing_confirm_dialog.dart`.
abstract class PairingPrompter {
  const PairingPrompter();

  static PairingPrompter instance = const _NoUiPairingPrompter();

  /// LAN receiver side. Null means the user never answered.
  Future<bool?> confirmIncoming(
    BuildContext context, {
    required String peerDeviceName,
    required String sas,
    bool overRelay = false,
  });

  /// Relay receiver side, which additionally offers "block this peer".
  ///
  /// [remoteClose] completes when the initiator gives up, so the prompt can
  /// take itself down instead of stranding a route the countdown pops later.
  Future<IncomingPairingChoice?> confirmIncomingRelay(
    BuildContext context, {
    required String peerDeviceName,
    required String sas,
    Future<IncomingPairingChoice?>? remoteClose,
  });
}

/// Stands in until the UI layer installs itself, and in tests that never do.
///
/// Refusing is the safe answer: a pairing nobody can see is a pairing nobody
/// agreed to.
class _NoUiPairingPrompter extends PairingPrompter {
  const _NoUiPairingPrompter();

  @override
  Future<bool?> confirmIncoming(
    BuildContext context, {
    required String peerDeviceName,
    required String sas,
    bool overRelay = false,
  }) async => false;

  @override
  Future<IncomingPairingChoice?> confirmIncomingRelay(
    BuildContext context, {
    required String peerDeviceName,
    required String sas,
    Future<IncomingPairingChoice?>? remoteClose,
  }) async => IncomingPairingChoice.rejected;
}
