import 'package:flutter/material.dart';

import '../../services/pairing_prompter.dart';
import '../pairing/pairing_confirm_dialog.dart';

/// Installed when the TV shell is active. Layout lives in the confirm dialog,
/// which also covers pairing started from settings.
class TvPairingPrompter extends PairingPrompter {
  const TvPairingPrompter();

  @override
  Future<bool?> confirmIncoming(
    BuildContext context, {
    required String peerDeviceName,
    required String sas,
    bool overRelay = false,
  }) {
    return PairingConfirmDialog.showIncoming(
      context,
      peerDeviceName: peerDeviceName,
      sas: sas,
      overRelay: overRelay,
    );
  }

  @override
  Future<IncomingPairingChoice?> confirmIncomingRelay(
    BuildContext context, {
    required String peerDeviceName,
    required String sas,
    Future<IncomingPairingChoice?>? remoteClose,
  }) {
    return PairingConfirmDialog.showIncomingRelay(
      context,
      peerDeviceName: peerDeviceName,
      sas: sas,
      remoteClose: remoteClose,
    );
  }
}
