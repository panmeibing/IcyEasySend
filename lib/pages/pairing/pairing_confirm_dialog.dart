import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/pairing_service.dart';
import '../../utils/constants.dart';
import '../../utils/pairing_message_provider.dart';

/// How the receiving user answered an inbound pairing dialog.
enum IncomingPairingChoice {
  /// Numbers match — proceed.
  accepted,

  /// Numbers differ / cancel — refuse without blocking.
  rejected,

  /// Explicitly block this peer from asking again over the relay.
  blocked,
}

/// Shows the six-digit pairing code and collects the user's comparison.
///
/// Both devices display this at the same time; the entire security of LAN
/// pairing rests on the user actually looking at the two screens, so the code
/// is the visual centre of the dialog and neither button is a default action.
class PairingConfirmDialog extends StatefulWidget {
  final String peerDeviceName;
  final String sas;

  /// Set on the device that started the pairing. The dialog drives the
  /// handshake and reflects the peer's decision while the user reads the code.
  final PairingHandshake? handshake;

  /// Auto-reject after this many seconds; null keeps the dialog open.
  final int? countdownSeconds;

  /// Whether the peer is being reached through the relay rather than the LAN.
  ///
  /// Only changes the instruction, but that is the part that matters: the two
  /// users cannot look at each other's screens and have to read the digits out
  /// over some other channel.
  final bool overRelay;

  /// When true (relay inbound), shows a separate "block" action.
  final bool allowBlock;

  /// When set (relay inbound), settles if the initiator backs out so this
  /// dialog can close without waiting for the countdown.
  final Future<IncomingPairingChoice?>? remoteClose;

  /// Relay initiator: settles when the peer has compared the digits.
  final Future<PairingPeerDecision>? relayPeerDecision;

  const PairingConfirmDialog._({
    required this.peerDeviceName,
    required this.sas,
    this.handshake,
    this.countdownSeconds,
    this.overRelay = false,
    this.allowBlock = false,
    this.remoteClose,
    this.relayPeerDecision,
  });

  /// Receiver side (LAN). Returns true when accepted, false when rejected and
  /// null when the user never answered.
  static Future<bool?> showIncoming(
    BuildContext context, {
    required String peerDeviceName,
    required String sas,
    bool overRelay = false,
  }) async {
    final choice = await showDialog<IncomingPairingChoice?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PairingConfirmDialog._(
        peerDeviceName: peerDeviceName,
        sas: sas,
        overRelay: overRelay,
        countdownSeconds: AppConstants.pairingConfirmationCountdown,
      ),
    );
    return switch (choice) {
      IncomingPairingChoice.accepted => true,
      IncomingPairingChoice.rejected || IncomingPairingChoice.blocked => false,
      null => null,
    };
  }

  /// Receiver side (relay). Distinguishes reject from an explicit block.
  ///
  /// [remoteClose] is completed by the pairing service when the initiator
  /// cancels; the dialog then closes itself (instead of leaving a stranded
  /// route that the countdown would pop later).
  static Future<IncomingPairingChoice?> showIncomingRelay(
    BuildContext context, {
    required String peerDeviceName,
    required String sas,
    Future<IncomingPairingChoice?>? remoteClose,
  }) {
    return showDialog<IncomingPairingChoice?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PairingConfirmDialog._(
        peerDeviceName: peerDeviceName,
        sas: sas,
        overRelay: true,
        allowBlock: true,
        remoteClose: remoteClose,
        countdownSeconds: AppConstants.pairingConfirmationCountdown,
      ),
    );
  }

  /// Initiator side of a relay pairing.
  ///
  /// [peerDecision] settles when the peer's user has compared the digits. The
  /// dialog stays open and shows that wait, so both screens remain visible for
  /// the out-of-band comparison until both sides have answered.
  static Future<bool> showRelayOutgoing(
    BuildContext context, {
    required String peerDeviceName,
    required String sas,
    Future<PairingPeerDecision>? peerDecision,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PairingConfirmDialog._(
        peerDeviceName: peerDeviceName,
        sas: sas,
        overRelay: true,
        relayPeerDecision: peerDecision,
      ),
    );
    return result ?? false;
  }

  /// Initiator side. Returns true once both devices have committed.
  static Future<bool> showOutgoing(
    BuildContext context, {
    required PairingHandshake handshake,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PairingConfirmDialog._(
        peerDeviceName: handshake.peerDeviceName,
        sas: handshake.sas,
        handshake: handshake,
      ),
    );
    return result ?? false;
  }

  @override
  State<PairingConfirmDialog> createState() => _PairingConfirmDialogState();
}

class _PairingConfirmDialogState extends State<PairingConfirmDialog> {
  final PairingMessages _messages = PairingMessages.instance;

  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  PairingPeerDecision? _peerDecision;
  bool _busy = false;

  /// Prevents a second [Navigator.pop] from taking the page under the dialog.
  ///
  /// The initiator cancel path pops once, then [finish] tells the peer, who
  /// may answer with a refusal that also tries to close this dialog. Without
  /// the guard the second pop removes [MainContainer] and leaves a black
  /// screen — the same class of bug as the receive-dialog double close.
  bool _closed = false;

  bool get _isInitiator =>
      widget.handshake != null || widget.relayPeerDecision != null;

  @override
  void initState() {
    super.initState();

    if (widget.countdownSeconds != null) {
      _remainingSeconds = widget.countdownSeconds!;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _remainingSeconds--);
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _close(null);
        }
      });
    }

    // Sending the request is what makes the peer show the same code, so it
    // starts as soon as this dialog is on screen.
    final handshake = widget.handshake;
    if (handshake != null) {
      unawaited(
        handshake.submit().then((decision) {
          if (!mounted || _closed) return;
          setState(() => _peerDecision = decision);
        }),
      );
    }

    final relayPeer = widget.relayPeerDecision;
    if (relayPeer != null) {
      unawaited(
        relayPeer.then((decision) {
          if (!mounted || _closed) return;
          setState(() => _peerDecision = decision);
          if (decision != PairingPeerDecision.accepted) {
            // Peer refused or gave up; nothing left to compare.
            _close(false);
          }
        }),
      );
    }

    final remoteClose = widget.remoteClose;
    if (remoteClose != null) {
      unawaited(
        remoteClose.then((choice) {
          // Initiator backed out (null) or an external decision arrived.
          _close(choice);
        }),
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _close([Object? result]) {
    if (_closed || !mounted) {
      return;
    }
    _closed = true;
    Navigator.of(context).pop(result);
  }

  Future<void> _accept() async {
    if (widget.handshake == null && widget.relayPeerDecision == null) {
      _close(IncomingPairingChoice.accepted);
      return;
    }

    setState(() => _busy = true);

    if (widget.handshake != null) {
      final decision = _peerDecision ?? await widget.handshake!.submit();
      if (!mounted || _closed) return;

      if (decision != PairingPeerDecision.accepted) {
        setState(() {
          _peerDecision = decision;
          _busy = false;
        });
        return;
      }

      final paired = await widget.handshake!.finish(true);
      if (!mounted || _closed) return;
      _close(paired);
      return;
    }

    // Relay initiator: wait for the peer's comparison if it is still pending,
    // then hand the result back to the caller to commit.
    final decision = _peerDecision ?? await widget.relayPeerDecision!;
    if (!mounted || _closed) return;
    if (decision != PairingPeerDecision.accepted) {
      setState(() {
        _peerDecision = decision;
        _busy = false;
      });
      return;
    }
    _close(true);
  }

  void _reject() {
    if (_closed) {
      return;
    }
    if (widget.handshake != null) {
      unawaited(widget.handshake!.finish(false));
      _close(false);
    } else if (widget.relayPeerDecision != null) {
      _close(false);
    } else {
      _close(IncomingPairingChoice.rejected);
    }
  }

  void _block() {
    _close(IncomingPairingChoice.blocked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final failed =
        _peerDecision != null &&
        _peerDecision != PairingPeerDecision.accepted;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(_messages.pairingTitle)),
        ],
      ),
      content: SizedBox(
        width: screenWidth * AppConstants.dialogWidthPercent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isInitiator
                  ? _messages.outgoingRequest(widget.peerDeviceName)
                  : _messages.incomingRequest(widget.peerDeviceName),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _buildCode(theme),
            const SizedBox(height: 20),
            Text(
              widget.overRelay
                  ? _messages.compareHintRelay
                  : _messages.compareHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            if (_isInitiator) ...[
              const SizedBox(height: 12),
              _buildPeerStatus(theme),
            ],
            if (widget.countdownSeconds != null && _remainingSeconds > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$_remainingSeconds s',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.allowBlock)
          TextButton(
            onPressed: _busy ? null : _block,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_messages.blockPeer),
          ),
        // Stays enabled even while waiting on the peer: a user who sees a
        // mismatched code must be able to stop immediately.
        TextButton(
          onPressed: _reject,
          child: Text(_messages.codesDiffer),
        ),
        ElevatedButton(
          onPressed: (_busy || failed) ? null : _accept,
          child: Text(_messages.codesMatch),
        ),
      ],
    );
  }

  Widget _buildCode(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.sas.split('').join(' '),
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildPeerStatus(ThemeData theme) {
    final (icon, color, text) = switch (_peerDecision) {
      null => (
        null,
        theme.hintColor,
        _messages.waitingPeer,
      ),
      PairingPeerDecision.accepted => (
        Icons.check_circle_outline,
        Colors.green,
        _messages.peerAccepted,
      ),
      PairingPeerDecision.rejected => (
        Icons.cancel_outlined,
        Colors.red,
        _messages.peerRejected,
      ),
      PairingPeerDecision.blocked => (
        Icons.block,
        Colors.red,
        _messages.peerPairingBlocked,
      ),
      PairingPeerDecision.timeout => (
        Icons.timer_off_outlined,
        Colors.orange,
        _messages.peerTimeout,
      ),
      PairingPeerDecision.error => (
        Icons.error_outline,
        Colors.red,
        _messages.pairingFailed,
      ),
    };

    return Row(
      children: [
        if (icon == null)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
