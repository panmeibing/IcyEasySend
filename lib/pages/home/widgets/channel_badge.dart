import 'package:flutter/material.dart';

import '../../../transport/transport_channel.dart';

/// Small LAN / relay icons for a peer row.
///
/// Design: lightning for LAN, cloud for relay; when both are available the
/// lightning leads so the preferred path is the one the eye hits first.
class ChannelBadge extends StatelessWidget {
  final bool hasLan;
  final bool hasRelay;
  final double iconSize;

  const ChannelBadge({
    super.key,
    required this.hasLan,
    required this.hasRelay,
    this.iconSize = 18,
  });

  factory ChannelBadge.forPeer(PeerRef peer, {Key? key, double iconSize = 18}) {
    return ChannelBadge(
      key: key,
      hasLan: peer.hasLan,
      hasRelay: peer.relayOnline,
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!hasLan && !hasRelay) {
      return Icon(Icons.devices, color: Colors.grey[500], size: iconSize);
    }

    final icons = <Widget>[
      if (hasLan)
        Icon(Icons.bolt, color: Colors.amber[800], size: iconSize),
      if (hasRelay)
        Icon(Icons.cloud_outlined, color: Colors.blueGrey[600], size: iconSize),
    ];

    if (icons.length == 1) {
      return icons.single;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icons[0],
        SizedBox(width: iconSize * 0.15),
        icons[1],
      ],
    );
  }
}
