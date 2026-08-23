import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/relay_config.dart';
import 'package:icy_easy_send/services/identity_service.dart';
import 'package:icy_easy_send/services/relay/relay_client.dart';
import 'package:icy_easy_send/services/relay/relay_crypto.dart';
import 'package:icy_easy_send/services/relay/relay_protocol.dart';
import 'package:icy_easy_send/utils/constants.dart';

/// Minimal relay signaling server for [RelayClient] unit tests.
class _MockRelayServer {
  _MockRelayServer(this._server);

  final HttpServer _server;
  final List<WebSocket> _sockets = [];

  static Future<_MockRelayServer> start({String token = 'test-token'}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final mock = _MockRelayServer(server);

    server.listen((request) async {
      if (request.uri.path != AppConstants.relaySignalPath) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        final auth = request.headers.value(HttpHeaders.authorizationHeader);
        request.response.statusCode =
            auth == 'Bearer $token' ? HttpStatus.badRequest : HttpStatus.unauthorized;
        await request.response.close();
        return;
      }

      final socket = await WebSocketTransformer.upgrade(request);
      mock._sockets.add(socket);
      unawaited(mock._handshake(socket));
    });

    return mock;
  }

  int get port => _server.port;

  RelayConfig config({String token = 'test-token'}) => RelayConfig(
    serverUrl: 'http://127.0.0.1:$port',
    token: token,
    enabled: true,
  );

  Future<void> closeAllSockets() async {
    final sockets = List<WebSocket>.from(_sockets);
    _sockets.clear();
    for (final socket in sockets) {
      await socket.close();
    }
  }

  Future<void> dispose() async {
    await closeAllSockets();
    await _server.close(force: true);
  }

  Future<void> _handshake(WebSocket socket) async {
    socket.add(
      jsonEncode(
        RelayEnvelope.build(
          RelayMessageType.challenge,
          fields: {'nonce': base64Encode(List<int>.filled(32, 7))},
        ),
      ),
    );

    await for (final frame in socket) {
      final envelope = RelayEnvelope.decode(frame as String);
      if (envelope == null) {
        continue;
      }

      switch (envelope.type) {
        case RelayMessageType.auth:
          socket.add(
            jsonEncode(
              RelayEnvelope.build(
                RelayMessageType.welcome,
                fields: {'sessionId': 'relay-session-${_sockets.length}'},
              ),
            ),
          );
        case RelayMessageType.subscribe:
          final peers = envelope.raw['peers'];
          if (peers is List) {
            for (final peer in peers) {
              if (peer is! String || peer.isEmpty) {
                continue;
              }
              socket.add(
                jsonEncode(
                  RelayEnvelope.build(
                    RelayMessageType.presence,
                    fields: {'deviceId': peer, 'online': true},
                  ),
                ),
              );
            }
          }
        case RelayMessageType.ping:
          socket.add(jsonEncode(RelayEnvelope.build(RelayMessageType.pong)));
        default:
          break;
      }
    }
  }
}

void main() {
  late Directory workspace;
  late _MockRelayServer server;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('relay-client-test');
    server = await _MockRelayServer.start();
  });

  tearDown(() async {
    await server.dispose();
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  RelayClient buildClient(IdentityService identity) {
    return RelayClient(identity: identity);
  }

  Future<void> seedSessions({
    required RelayClient client,
    required IdentityService localIdentity,
  }) async {
    final peerIdentity = IdentityService.forTesting(
      filePath: '${workspace.path}${Platform.pathSeparator}peer.key',
    );
    final localId = await localIdentity.getDeviceId();
    final peerId = await peerIdentity.getDeviceId();

    final offer = await RelayCrypto.createOffer('transfer-session-1');
    final answered = await RelayCrypto.answerOffer(
      offer: offer.payload,
      senderDeviceId: localId,
      receiverDeviceId: peerId,
      identity: peerIdentity,
    );
    expect(answered.isSuccess, isTrue);

    final completed = await RelayCrypto.completeOffer(
      offer: offer,
      answer: answered.data!.answer,
      senderDeviceId: localId,
      receiverDeviceId: peerId,
      receiverPublicKey: await peerIdentity.getPublicKeyBytes(),
    );
    expect(completed.isSuccess, isTrue);

    client.sessions.add(completed.data!);
  }

  test('transient disconnect preserves negotiated crypto sessions', () async {
    final identity = IdentityService.forTesting(
      filePath: '${workspace.path}${Platform.pathSeparator}device.key',
    );
    final client = buildClient(identity);
    addTearDown(client.dispose);

    await client.applyConfig(server.config());
    expect(await client.connect(), isTrue);

    await seedSessions(client: client, localIdentity: identity);
    expect(client.sessions.length, 1);

    final reconnecting = client.stateChanges.firstWhere(
      (state) => state == RelayConnectionState.reconnecting,
    );

    await server.closeAllSockets();
    await reconnecting.timeout(const Duration(seconds: 3));
    expect(client.sessions.length, 1);

    await client.stateChanges
        .firstWhere((state) => state == RelayConnectionState.connected)
        .timeout(const Duration(seconds: 5));
    expect(client.sessions.length, 1);
  });

  test('intentional disconnect clears negotiated crypto sessions', () async {
    final identity = IdentityService.forTesting(
      filePath: '${workspace.path}${Platform.pathSeparator}device.key',
    );
    final client = buildClient(identity);
    addTearDown(client.dispose);

    await client.applyConfig(server.config());
    expect(await client.connect(), isTrue);
    await seedSessions(client: client, localIdentity: identity);
    expect(client.sessions.length, 1);

    await client.disconnect();

    expect(client.sessions.length, 0);
    expect(client.state, RelayConnectionState.disabled);
  });

  test('transient disconnect preserves known online peers', () async {
    final identity = IdentityService.forTesting(
      filePath: '${workspace.path}${Platform.pathSeparator}device.key',
    );
    final client = buildClient(identity);
    addTearDown(client.dispose);

    await client.applyConfig(server.config());
    expect(await client.connect(), isTrue);

    const peerId = 'peer-device-42';
    final sawPeer = client.presenceChanges.firstWhere(
      (event) => event.deviceId == peerId && event.online,
    );
    await client.setSubscriptions([peerId]);
    await sawPeer.timeout(const Duration(seconds: 3));

    expect(client.isOnline(peerId), isTrue);

    final reconnecting = client.stateChanges.firstWhere(
      (state) => state == RelayConnectionState.reconnecting,
    );
    await server.closeAllSockets();
    await reconnecting.timeout(const Duration(seconds: 3));

    expect(client.isOnline(peerId), isTrue);
  });
}
