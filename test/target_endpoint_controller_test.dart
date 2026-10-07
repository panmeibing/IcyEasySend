import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/pages/home/controllers/target_endpoint_controller.dart';
import 'package:icy_easy_send/pages/home/widgets/orbit_canvas.dart';
import 'package:icy_easy_send/services/preferences_service.dart';
import 'package:icy_easy_send/transport/transport_channel.dart';
import 'package:icy_easy_send/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TargetEndpointController endpoint;

  /// Lets listener-triggered async validation finish.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> type(String ip) async {
    endpoint.ipController.text = ip;
    await settle();
  }

  final lanPeer = PeerRef(
    deviceId: 'device-a',
    deviceName: 'Laptop',
    lan: LanEndpoint(ip: '192.168.1.20', port: 9000),
    preferredTransport: TransportKind.lan,
  );
  const relayPeer = PeerRef(
    deviceId: 'device-b',
    relayOnline: true,
    preferredTransport: TransportKind.relay,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    endpoint = TargetEndpointController();
  });

  tearDown(() => endpoint.dispose());

  test('load restores the last target and secret key', () async {
    SharedPreferences.setMockInitialValues({
      'last_used_ip': '192.168.1.9',
      'last_used_port': 8123,
      'target_device_secret_key': 'shh',
      'ip_history': ['192.168.1.9', '192.168.1.8'],
    });

    await endpoint.load();
    await settle();

    expect(endpoint.ipController.text, '192.168.1.9');
    expect(endpoint.port, 8123);
    expect(endpoint.secretKey, 'shh');
    expect(endpoint.ipHistory, ['192.168.1.9', '192.168.1.8']);
    expect(endpoint.hasValidLanTarget, isTrue);
    expect(endpoint.manualTargetLabel, '192.168.1.9:8123');
  });

  test('port problems are reported and only good ports are saved', () async {
    endpoint.portController.text = '';
    expect(endpoint.portErrorMessage, isNotNull);
    endpoint.portController.text = 'abc';
    expect(endpoint.portErrorMessage, isNotNull);
    endpoint.portController.text = '70000';
    expect(endpoint.portErrorMessage, isNotNull);
    expect(endpoint.port, isNull);

    endpoint.portController.text = '8088';
    expect(endpoint.portErrorMessage, isNull);
    await settle();
    expect(await PreferencesService().getLastUsedPort(), 8088);
  });

  test('a malformed IP is not a target', () async {
    await type('999.1.1.1');
    expect(endpoint.ipErrorMessage, isNotNull);
    expect(endpoint.ipMessageIsWarning, isFalse);
    expect(endpoint.hasTarget, isFalse);
    expect(endpoint.peerForSend(), isNull);
    expect(endpoint.diagnosticsTarget, isNull);
  });

  test('a typed address becomes a LAN peer', () async {
    await type('192.168.1.30');
    final peer = endpoint.peerForSend()!;
    expect(peer.lan!.ip, '192.168.1.30');
    expect(peer.lan!.port, AppConstants.defaultPort);
    expect(endpoint.diagnosticsTarget, (
      ip: '192.168.1.30',
      port: AppConstants.defaultPort,
    ));
  });

  test('another subnet warns but still sends', () async {
    endpoint.serverAddress = '192.168.1.5:${AppConstants.defaultPort}';
    endpoint.ipController.text = '192.168.2.40';
    // The subnet check waits on a connectivity lookup.
    await pumpEventQueue();

    expect(endpoint.ipErrorMessage, contains('192.168.2.40'));
    expect(endpoint.ipMessageIsWarning, isTrue);
    expect(endpoint.hasValidLanTarget, isTrue);
    expect(endpoint.peerForSend()!.lan!.ip, '192.168.2.40');
    expect(endpoint.diagnosticsTarget?.ip, '192.168.2.40');
  });

  test('the same subnet shows no message', () async {
    endpoint.serverAddress = '192.168.1.5:${AppConstants.defaultPort}';
    endpoint.ipController.text = '192.168.1.40';
    // The subnet check waits on a connectivity lookup.
    await pumpEventQueue();

    expect(endpoint.ipErrorMessage, isNull);
    expect(endpoint.ipMessageIsWarning, isFalse);
  });

  test(
    'selecting a LAN peer fills the form and keeps a port override',
    () async {
      endpoint.select(lanPeer);
      await settle();

      expect(endpoint.selectedPeer, lanPeer);
      expect(endpoint.ipController.text, '192.168.1.20');
      expect(endpoint.manualTargetLabel, isNull);

      endpoint.portController.text = '9100';
      final peer = endpoint.peerForSend()!;
      expect(peer.deviceId, 'device-a');
      expect(peer.lan!.port, 9100);
    },
  );

  test('typing another address drops the scan selection', () async {
    endpoint.select(lanPeer);
    await settle();
    await type('192.168.1.21');
    expect(endpoint.selectedPeer, isNull);
  });

  test('a relay-only peer clears the LAN form and is a target', () async {
    await type('192.168.1.30');
    endpoint.select(relayPeer);
    await settle();

    expect(endpoint.ipController.text, isEmpty);
    expect(endpoint.targetIP, isEmpty);
    expect(endpoint.hasRelayTarget, isTrue);
    expect(endpoint.hasTarget, isTrue);
    expect(endpoint.peerForSend(), relayPeer);

    await type('192.168.1.31');
    expect(endpoint.selectedPeer, isNull);
  });

  test('history removal refreshes the list', () async {
    SharedPreferences.setMockInitialValues({
      'ip_history': ['10.0.0.1', '10.0.0.2'],
    });
    await endpoint.reloadHistory();
    expect(await endpoint.removeFromHistory('10.0.0.1'), isTrue);
    expect(endpoint.ipHistory, ['10.0.0.2']);
  });

  test('input can be unlocked after the page is gone', () {
    final controller = TargetEndpointController()..lockInput();
    expect(controller.ipFocusNode.canRequestFocus, isFalse);
    controller.dispose();
    expect(controller.unlockInput, returnsNormally);
  });

  group('orbit satellites', () {
    test('bringing a shown route forward keeps its angle', () {
      final ring = [
        const OrbitSatellite(peer: relayPeer, angleDegrees: 10),
        OrbitSatellite(peer: lanPeer, angleDegrees: 170),
      ];
      final next = OrbitSatellite.bringToFront(ring, lanPeer);
      expect(next.map((s) => s.peer), [lanPeer, relayPeer]);
      expect(next.first.angleDegrees, 170);
    });

    test('the ring never grows past its limit', () {
      var ring = <OrbitSatellite>[];
      for (var i = 0; i < OrbitSatellite.maxVisible + 3; i++) {
        ring = OrbitSatellite.bringToFront(
          ring,
          PeerRef.lanAddress('10.0.0.$i:53317'),
        );
      }
      expect(ring, hasLength(OrbitSatellite.maxVisible));
    });

    test('replacing a device drops its stale routes', () {
      final staleLan = PeerRef.lanAddress(
        '192.168.0.5:53317',
        deviceId: 'device-b',
      );
      final ring = [
        OrbitSatellite(peer: staleLan, angleDegrees: 0),
        OrbitSatellite(peer: lanPeer, angleDegrees: 90),
      ];
      final next = OrbitSatellite.replaceDevice(ring, relayPeer, [relayPeer]);
      expect(next.map((s) => s.peer), [relayPeer, lanPeer]);
    });
  });
}
