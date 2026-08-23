import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/transport/transport_channel.dart';
import 'package:icy_easy_send/utils/constants.dart';

void main() {
  group('LanEndpoint', () {
    test('parses ip:port', () {
      final endpoint = LanEndpoint.parse('192.168.1.10:9527');

      expect(endpoint.ip, '192.168.1.10');
      expect(endpoint.port, 9527);
      expect(endpoint.address, '192.168.1.10:9527');
    });

    test('parses a bare ip using the default port', () {
      final endpoint = LanEndpoint.parse('192.168.1.10');

      expect(endpoint.ip, '192.168.1.10');
      expect(endpoint.port, AppConstants.defaultPort);
    });

    test('keeps the original address verbatim', () {
      // The address is written to transfer history and handed to
      // NetworkUtil.buildHttpUrl, so normalising it would rewrite history
      // entries for callers that pass a bare IP.
      expect(LanEndpoint.parse('192.168.1.10').address, '192.168.1.10');
      expect(LanEndpoint.parse('10.0.0.1:8080').address, '10.0.0.1:8080');
      expect(LanEndpoint.parse('').address, '');
    });

    test('falls back to the default port when the port is not a number', () {
      final endpoint = LanEndpoint.parse('192.168.1.10:abc');

      expect(endpoint.port, AppConstants.defaultPort);
      expect(endpoint.address, '192.168.1.10:abc');
    });

    test('composes the address from ip and port', () {
      final endpoint = LanEndpoint(ip: '10.0.0.5', port: 1234);

      expect(endpoint.address, '10.0.0.5:1234');
    });

    test('compares by address', () {
      expect(
        LanEndpoint.parse('10.0.0.5:1'),
        LanEndpoint(ip: '10.0.0.5', port: 1),
      );
      expect(
        LanEndpoint.parse('10.0.0.5:1').hashCode,
        LanEndpoint(ip: '10.0.0.5', port: 1).hashCode,
      );
      expect(
        LanEndpoint.parse('10.0.0.5:1'),
        isNot(LanEndpoint.parse('10.0.0.6:1')),
      );
    });
  });

  group('PeerRef', () {
    test('lanAddress builds a LAN-only peer', () {
      final peer = PeerRef.lanAddress('192.168.1.10:9527');

      expect(peer.hasLan, isTrue);
      expect(peer.lan!.address, '192.168.1.10:9527');
      expect(peer.deviceId, isNull);
      expect(peer.relayOnline, isFalse);
    });

    test('describe falls back to the address when no name is known', () {
      expect(
        PeerRef.lanAddress('192.168.1.10:9527').describe(),
        '192.168.1.10:9527',
      );
    });

    test('describe prefers the device name and keeps the address', () {
      final peer = PeerRef.lanAddress(
        '192.168.1.10:9527',
        deviceName: 'Desktop',
      );

      expect(peer.describe(), 'Desktop (192.168.1.10:9527)');
    });

    test('describe uses the device id when nothing else is known', () {
      expect(const PeerRef(deviceId: 'a3f2').describe(), 'a3f2');
      expect(const PeerRef().describe(), 'unknown');
    });

    test('copyWith replaces only the given fields', () {
      final peer = PeerRef.lanAddress(
        '192.168.1.10:9527',
        deviceName: 'Desktop',
      );
      final updated = peer.copyWith(deviceId: 'a3f2', relayOnline: true);

      expect(updated.deviceId, 'a3f2');
      expect(updated.relayOnline, isTrue);
      expect(updated.deviceName, 'Desktop');
      expect(updated.lan, peer.lan);
    });
  });

  group('ProbeResult', () {
    test('reachable is ok and attempted', () {
      final result = ProbeResult.reachable(
        kind: TransportKind.lan,
        rtt: const Duration(milliseconds: 42),
        deviceName: 'Desktop',
      );

      expect(result.ok, isTrue);
      expect(result.attempted, isTrue);
      expect(result.rtt, const Duration(milliseconds: 42));
      expect(result.deviceName, 'Desktop');
    });

    test('unreachable means it was tried and failed', () {
      final result = ProbeResult.unreachable(
        kind: TransportKind.lan,
        errorMessage: 'timeout',
      );

      expect(result.ok, isFalse);
      expect(result.attempted, isTrue);
      expect(result.errorMessage, 'timeout');
    });

    test('unavailable means nothing was tried', () {
      final result = ProbeResult.unavailable(kind: TransportKind.relay);

      expect(result.ok, isFalse);
      expect(result.attempted, isFalse);
    });
  });
}
