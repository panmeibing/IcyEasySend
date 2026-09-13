import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/discovered_device.dart';
import 'package:icy_easy_send/models/paired_device.dart';
import 'package:icy_easy_send/transport/peer_directory.dart';
import 'package:icy_easy_send/transport/transport_channel.dart';

void main() {
  final phoneKey = base64Encode(Uint8List(32));

  PairedDevice paired({
    required String id,
    String name = 'Phone',
    String? lastSeenLan,
  }) {
    return PairedDevice(
      deviceId: id,
      publicKey: phoneKey,
      deviceName: name,
      pairedAt: DateTime.fromMillisecondsSinceEpoch(0),
      lastSeenLan: lastSeenLan,
    );
  }

  test('merges a LAN discovery with a relay-online paired device', () {
    final peers = PeerDirectory.merge(
      discovered: const [
        DiscoveredDevice(
          ip: '192.168.1.10',
          port: 9527,
          deviceName: 'Phone',
          deviceId: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
      ],
      paired: [
        paired(
          id: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          name: 'Old Name',
          lastSeenLan: '192.168.1.99:9527',
        ),
      ],
      onlinePeers: {'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'},
    );

    expect(peers, hasLength(1));
    expect(peers.single.deviceId, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
    expect(peers.single.deviceName, 'Phone');
    expect(peers.single.lan!.address, '192.168.1.10:9527');
    expect(peers.single.relayOnline, isTrue);
  });

  test('lists a relay-online paired device that was not discovered on LAN', () {
    final peers = PeerDirectory.merge(
      paired: [
        paired(id: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb', name: 'Laptop'),
      ],
      onlinePeers: {'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'},
    );

    expect(peers, hasLength(1));
    expect(peers.single.deviceName, 'Laptop');
    expect(peers.single.hasLan, isFalse);
    expect(peers.single.relayOnline, isTrue);
  });

  test('does not revive stale lastSeenLan as a live LAN route', () {
    final peers = PeerDirectory.merge(
      paired: [
        paired(
          id: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          name: 'Laptop',
          lastSeenLan: '192.168.1.50:9527',
        ),
      ],
      onlinePeers: {'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'},
    );

    expect(peers, hasLength(1));
    expect(peers.single.hasLan, isFalse);
    expect(peers.single.relayOnline, isTrue);
  });

  test('expandRoutes splits dual-path peers into LAN and relay rows', () {
    final peers = PeerDirectory.expandRoutes([
      PeerRef(
        deviceId: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        deviceName: 'Phone',
        lan: LanEndpoint.parse('192.168.1.10:9527'),
        relayOnline: true,
      ),
    ]);

    expect(peers, hasLength(2));
    expect(peers[0].preferredTransport, TransportKind.lan);
    expect(peers[0].hasLan, isTrue);
    expect(peers[0].relayOnline, isFalse);
    expect(peers[1].preferredTransport, TransportKind.relay);
    expect(peers[1].hasLan, isFalse);
    expect(peers[1].relayOnline, isTrue);
  });

  test('omits paired devices that are offline and not on the LAN', () {
    final peers = PeerDirectory.merge(
      paired: [paired(id: 'cccccccccccccccccccccccccccccccc')],
      onlinePeers: const {},
    );

    expect(peers, isEmpty);
  });

  test('keeps pre-identity discoveries as anonymous LAN peers', () {
    final peers = PeerDirectory.merge(
      discovered: const [
        DiscoveredDevice(
          ip: '192.168.1.20',
          port: 9527,
          deviceName: 'Legacy',
        ),
      ],
      paired: [paired(id: 'dddddddddddddddddddddddddddddddd')],
      onlinePeers: {'dddddddddddddddddddddddddddddddd'},
    );

    expect(peers, hasLength(2));
    expect(peers.where((p) => p.deviceId == null).single.deviceName, 'Legacy');
    expect(
      peers.where((p) => p.deviceId == 'dddddddddddddddddddddddddddddddd'),
      hasLength(1),
    );
  });

  test('two discoveries with the same deviceId become one peer', () {
    final peers = PeerDirectory.merge(
      discovered: const [
        DiscoveredDevice(
          ip: '192.168.1.10',
          port: 9527,
          deviceName: 'Phone',
          deviceId: 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
        ),
        DiscoveredDevice(
          ip: '192.168.1.11',
          port: 9527,
          deviceName: 'Phone',
          deviceId: 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
        ),
      ],
    );

    expect(peers, hasLength(1));
    // Last write wins for the address.
    expect(peers.single.lan!.ip, '192.168.1.11');
  });
}
