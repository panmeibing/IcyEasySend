import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/transfer_data.dart';
import 'package:icy_easy_send/models/transfer_file_item.dart';
import 'package:icy_easy_send/transport/channel_selector.dart';
import 'package:icy_easy_send/transport/transport_channel.dart';
import 'package:icy_easy_send/utils/operation_result.dart';

class _ProbeChannel implements TransportChannel {
  _ProbeChannel({required this.kind});

  @override
  final TransportKind kind;

  ProbeResult? result;
  Duration delay = Duration.zero;
  int probeCalls = 0;
  PeerRef? lastPeer;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<ProbeResult> probe(PeerRef peer, {Duration? timeout}) async {
    probeCalls++;
    lastPeer = peer;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return result ??
        ProbeResult.reachable(
          kind: kind,
          rtt: const Duration(milliseconds: 1),
        );
  }

  @override
  Future<Map<String, OperationResult<TransferData>>> sendFiles({
    required PeerRef peer,
    required List<TransferFileItem> files,
    String? secretKey,
    TransferProgressCallback? onProgress,
    FileProgressCallback? onFileProgress,
    void Function(String status)? onStatusChange,
    VoidCallback? onHistoryUpdated,
  }) async =>
      {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ProbeChannel lan;
  late _ProbeChannel relay;
  late ChannelSelector selector;

  setUp(() {
    lan = _ProbeChannel(kind: TransportKind.lan);
    relay = _ProbeChannel(kind: TransportKind.relay);
    selector = ChannelSelector(
      lan: lan,
      relay: relay,
      lanWinWindow: const Duration(milliseconds: 80),
      relayProbeTimeout: const Duration(milliseconds: 200),
    );
  });

  test('LAN wins when both channels are reachable', () async {
    final peer = PeerRef(
      deviceId: 'abc',
      lan: LanEndpoint.parse('192.168.1.10:9527'),
      relayOnline: true,
    );

    final selection = await selector.select(peer);

    expect(selection, isNotNull);
    expect(selection!.channel.kind, TransportKind.lan);
    expect(lan.probeCalls, 1);
  });

  test('relay is used when the LAN probe fails', () async {
    lan.result = ProbeResult.unreachable(
      kind: TransportKind.lan,
      errorMessage: 'down',
    );
    final peer = PeerRef(
      deviceId: 'abc',
      lan: LanEndpoint.parse('192.168.1.10:9527'),
      relayOnline: true,
    );

    final selection = await selector.select(peer);

    expect(selection, isNotNull);
    expect(selection!.channel.kind, TransportKind.relay);
    expect(relay.probeCalls, 1);
  });

  test('relay is used when the LAN probe misses its win window', () async {
    lan.delay = const Duration(milliseconds: 200);
    final peer = PeerRef(
      deviceId: 'abc',
      lan: LanEndpoint.parse('192.168.1.10:9527'),
      relayOnline: true,
    );

    final selection = await selector.select(peer);

    expect(selection, isNotNull);
    expect(selection!.channel.kind, TransportKind.relay);
  });

  test('relay-only peers never probe the LAN', () async {
    const peer = PeerRef(deviceId: 'abc', relayOnline: true);

    final selection = await selector.select(peer);

    expect(selection!.channel.kind, TransportKind.relay);
    expect(lan.probeCalls, 0);
    expect(relay.probeCalls, 1);
  });

  test('LAN-only peers never probe the relay', () async {
    final peer = PeerRef.lanAddress('192.168.1.10:9527');

    final selection = await selector.select(peer);

    expect(selection!.channel.kind, TransportKind.lan);
    expect(relay.probeCalls, 0);
  });

  test('preferredTransport relay skips LAN even when hasLan', () async {
    final peer = PeerRef(
      deviceId: 'abc',
      lan: LanEndpoint.parse('192.168.1.10:9527'),
      relayOnline: true,
      preferredTransport: TransportKind.relay,
    );

    final selection = await selector.select(peer);

    expect(selection!.channel.kind, TransportKind.relay);
    expect(lan.probeCalls, 0);
    expect(relay.probeCalls, 1);
  });

  test('preferredTransport lan skips relay even when relayOnline', () async {
    final peer = PeerRef(
      deviceId: 'abc',
      lan: LanEndpoint.parse('192.168.1.10:9527'),
      relayOnline: true,
      preferredTransport: TransportKind.lan,
    );

    final selection = await selector.select(peer);

    expect(selection!.channel.kind, TransportKind.lan);
    expect(lan.probeCalls, 1);
    expect(relay.probeCalls, 0);
  });

  test('returns null when neither channel can reach the peer', () async {
    lan.result = ProbeResult.unreachable(
      kind: TransportKind.lan,
      errorMessage: 'lan down',
    );
    relay.result = ProbeResult.unreachable(
      kind: TransportKind.relay,
      errorMessage: 'relay down',
    );
    final peer = PeerRef(
      deviceId: 'abc',
      lan: LanEndpoint.parse('192.168.1.10:9527'),
      relayOnline: true,
    );

    expect(await selector.select(peer), isNull);
  });
}
