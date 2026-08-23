import 'dart:async';

import '../utils/constants.dart';
import '../utils/log_util.dart';
import '../utils/transfer_status_provider.dart';
import 'transport_channel.dart';

/// Outcome of picking a route for one send.
class ChannelSelection {
  final TransportChannel channel;
  final ProbeResult probe;

  const ChannelSelection({required this.channel, required this.probe});
}

/// Picks LAN or relay by racing both probes, with a short LAN win window.
///
/// Both probes start together. If the LAN answers within
/// [AppConstants.relayLanWinWindow], it wins and the relay result is ignored.
/// Otherwise the relay is used when it is reachable. Selection is once per
/// transfer: mid-transfer migration is deliberately out of scope (decision D9).
class ChannelSelector {
  final TransportChannel lan;
  final TransportChannel relay;
  final Duration lanWinWindow;
  final Duration relayProbeTimeout;
  final TransferStatusProvider _statusProvider;
  final String logTag = LogTags.transfer;

  ChannelSelector({
    required this.lan,
    required this.relay,
    this.lanWinWindow = AppConstants.relayLanWinWindow,
    this.relayProbeTimeout = AppConstants.relayProbeTimeout,
    TransferStatusProvider? statusProvider,
  }) : _statusProvider = statusProvider ?? TransferStatusProvider();

  /// Returns null when neither channel can reach [peer].
  Future<ChannelSelection?> select(PeerRef peer) async {
    final lanFuture = peer.hasLan
        ? lan.probe(peer, timeout: lanWinWindow)
        : Future.value(
            ProbeResult.unavailable(
              kind: TransportKind.lan,
              errorMessage: _statusProvider.lanRouteUnavailable,
            ),
          );

    final relayFuture = peer.relayOnline
        ? relay.probe(peer, timeout: relayProbeTimeout)
        : Future.value(
            ProbeResult.unavailable(
              kind: TransportKind.relay,
              errorMessage: _statusProvider.relayRouteUnavailable,
            ),
          );

    // Give the LAN its win window even when the probe itself uses a shorter
    // timeout: a late LAN answer after the window has closed must not steal
    // a relay that already won.
    final lanResult = await lanFuture.timeout(
      lanWinWindow,
      onTimeout: () => ProbeResult.unreachable(
        kind: TransportKind.lan,
        errorMessage: _statusProvider.lanRouteUnavailable,
      ),
    );

    if (lanResult.ok) {
      unawaited(relayFuture);
      LogUtil.iTag(
        logTag,
        '选路: 局域网 '
        '(rtt=${lanResult.rtt?.inMilliseconds}ms, peer=${peer.describe()})',
      );
      return ChannelSelection(channel: lan, probe: lanResult);
    }

    final relayResult = await relayFuture;
    if (relayResult.ok) {
      LogUtil.iTag(
        logTag,
        '选路: 中转 (peer=${peer.describe()})',
      );
      return ChannelSelection(channel: relay, probe: relayResult);
    }

    LogUtil.wTag(
      logTag,
      '选路失败: lan=${lanResult.errorMessage}, '
      'relay=${relayResult.errorMessage}, peer=${peer.describe()}',
    );
    return null;
  }

  /// Human-readable reason when [select] returned null.
  String unreachableMessage(PeerRef peer) {
    if (peer.hasLan && (peer.relayOnline || peer.deviceId != null)) {
      return _statusProvider.peerUnreachable;
    }
    if (peer.hasLan) {
      return _statusProvider.lanRouteUnavailable;
    }
    return _statusProvider.relayRouteUnavailable;
  }
}
