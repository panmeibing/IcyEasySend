import '../models/discovered_device.dart';
import '../models/paired_device.dart';
import 'transport_channel.dart';

/// Builds [PeerRef]s from LAN discovery and relay presence.
///
/// Merge is still keyed by [deviceId] (one physical device). Call
/// [expandRoutes] when presenting a picker so LAN and relay become separate
/// selectable rows.
class PeerDirectory {
  const PeerDirectory._();

  /// Merges [discovered] with paired devices that are currently [onlinePeers].
  ///
  /// [PairedDevice.lastSeenLan] is intentionally not treated as a live LAN
  /// route — only this scan's discoveries populate [PeerRef.lan].
  ///
  /// Paired devices that are offline and were not discovered on the LAN are
  /// omitted: the settings page already lists every trusted device, and a
  /// scan dialog full of unreachable names would only confuse.
  static List<PeerRef> merge({
    Iterable<DiscoveredDevice> discovered = const [],
    Iterable<PairedDevice> paired = const [],
    Set<String> onlinePeers = const {},
  }) {
    final byId = <String, PeerRef>{};
    final anonymous = <PeerRef>[];

    for (final device in discovered) {
      final lan = LanEndpoint(ip: device.ip, port: device.port);
      final id = device.deviceId;
      if (id == null || id.isEmpty) {
        anonymous.add(
          PeerRef(deviceName: device.deviceName, lan: lan),
        );
        continue;
      }

      final existing = byId[id];
      byId[id] = PeerRef(
        deviceId: id,
        deviceName: _preferName(device.deviceName, existing?.deviceName),
        lan: lan,
        relayOnline: onlinePeers.contains(id) || (existing?.relayOnline ?? false),
      );
    }

    for (final device in paired) {
      final online = onlinePeers.contains(device.deviceId);
      final existing = byId[device.deviceId];

      if (existing != null) {
        byId[device.deviceId] = existing.copyWith(
          deviceName: _preferName(existing.deviceName, device.deviceName),
          relayOnline: online || existing.relayOnline,
        );
        continue;
      }

      if (!online) {
        continue;
      }

      byId[device.deviceId] = PeerRef(
        deviceId: device.deviceId,
        deviceName: device.deviceName,
        relayOnline: true,
      );
    }

    final peers = [...byId.values, ...anonymous];
    peers.sort(_compare);
    return peers;
  }

  /// One selectable row per live transport (LAN and/or relay).
  ///
  /// Dual-path devices become two [PeerRef]s that share [PeerRef.deviceId]
  /// but pin [PeerRef.preferredTransport] so the user can choose the path.
  static List<PeerRef> expandRoutes(Iterable<PeerRef> peers) {
    final out = <PeerRef>[];
    for (final peer in peers) {
      final hasLan = peer.hasLan;
      final hasRelay = peer.relayOnline;

      if (hasLan && hasRelay) {
        out.add(
          PeerRef(
            deviceId: peer.deviceId,
            deviceName: peer.deviceName,
            lan: peer.lan,
            preferredTransport: TransportKind.lan,
          ),
        );
        out.add(
          PeerRef(
            deviceId: peer.deviceId,
            deviceName: peer.deviceName,
            relayOnline: true,
            preferredTransport: TransportKind.relay,
          ),
        );
        continue;
      }

      if (hasLan) {
        out.add(
          peer.copyWith(preferredTransport: TransportKind.lan),
        );
        continue;
      }

      if (hasRelay) {
        out.add(
          peer.copyWith(preferredTransport: TransportKind.relay),
        );
        continue;
      }

      out.add(peer);
    }

    out.sort(_compareRoutes);
    return out;
  }

  /// Turns a LAN discovery into a [PeerRef], stamping current relay presence.
  static PeerRef fromDiscovered(
    DiscoveredDevice device, {
    Set<String> onlinePeers = const {},
  }) {
    final id = device.deviceId;
    return PeerRef(
      deviceId: id,
      deviceName: device.deviceName,
      lan: LanEndpoint(ip: device.ip, port: device.port),
      relayOnline: id != null && onlinePeers.contains(id),
    );
  }

  static String? _preferName(String? primary, String? fallback) {
    if (primary != null && primary.isNotEmpty) {
      return primary;
    }
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }
    return primary ?? fallback;
  }

  static int _compare(PeerRef a, PeerRef b) {
    final nameCmp = (a.deviceName ?? '').toLowerCase().compareTo(
      (b.deviceName ?? '').toLowerCase(),
    );
    if (nameCmp != 0) {
      return nameCmp;
    }
    return a.describe().compareTo(b.describe());
  }

  static int _compareRoutes(PeerRef a, PeerRef b) {
    final deviceCmp = _compare(a, b);
    if (deviceCmp != 0) {
      return deviceCmp;
    }
    return (a.preferredTransport?.index ?? -1).compareTo(
      b.preferredTransport?.index ?? -1,
    );
  }
}
