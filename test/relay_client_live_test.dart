@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/relay_config.dart';
import 'package:icy_easy_send/services/identity_service.dart';
import 'package:icy_easy_send/services/relay/relay_client.dart';
import 'package:icy_easy_send/services/relay/relay_protocol.dart';

/// Checks the Dart client against a real `relayd`.
///
/// The signaling protocol is implemented twice, in Go and in Dart, and the
/// admission handshake fails silently and identically for a wrong signature,
/// a wrong device id derivation and a wrong byte order. Only running both
/// halves together proves they agree.
///
/// Skipped unless a server is pointed at explicitly:
///
/// ```
/// dart test --tags live \
///   --dart-define=RELAY_TEST_URL=http://127.0.0.1:18443 \
///   --dart-define=RELAY_TEST_TOKEN=...
/// ```
const String _serverUrl = String.fromEnvironment('RELAY_TEST_URL');
const String _token = String.fromEnvironment('RELAY_TEST_TOKEN');

void main() {
  final configured = _serverUrl.isNotEmpty && _token.isNotEmpty;

  group(
    'RelayClient against a live relayd',
    () {
      late Directory workspace;

      setUp(() async {
        workspace = await Directory.systemTemp.createTemp('relay-live');
      });

      tearDown(() async {
        if (await workspace.exists()) {
          await workspace.delete(recursive: true);
        }
      });

      RelayClient buildClient(String keyName) {
        return RelayClient(
          identity: IdentityService.forTesting(
            filePath: '${workspace.path}${Platform.pathSeparator}$keyName',
          ),
        );
      }

      RelayConfig config() =>
          RelayConfig(serverUrl: _serverUrl, token: _token, enabled: true);

      test('completes the two-layer admission handshake', () async {
        final client = buildClient('alice.key');
        addTearDown(client.dispose);

        await client.applyConfig(config());
        expect(await client.connect(), isTrue);
        expect(client.state, RelayConnectionState.connected);
      });

      test('is rejected when the token is wrong', () async {
        final client = buildClient('alice.key');
        addTearDown(client.dispose);

        await client.applyConfig(
          config().copyWith(token: 'definitely-not-the-right-token-000000'),
        );

        expect(await client.connect(), isFalse);
        expect(client.state, RelayConnectionState.rejected);
      });

      test('reports presence once both devices subscribe', () async {
        final alice = buildClient('alice.key');
        final bob = buildClient('bob.key');
        addTearDown(alice.dispose);
        addTearDown(bob.dispose);

        await alice.applyConfig(config());
        await bob.applyConfig(config());
        expect(await alice.connect(), isTrue);
        expect(await bob.connect(), isTrue);

        final aliceId = await IdentityService.forTesting(
          filePath: '${workspace.path}${Platform.pathSeparator}alice.key',
        ).getDeviceId();
        final bobId = await IdentityService.forTesting(
          filePath: '${workspace.path}${Platform.pathSeparator}bob.key',
        ).getDeviceId();

        final sawBob = alice.presenceChanges.firstWhere(
          (event) => event.deviceId == bobId && event.online,
        );

        await alice.setSubscriptions([bobId]);
        await bob.setSubscriptions([aliceId]);

        await sawBob.timeout(const Duration(seconds: 5));
        expect(alice.isOnline(bobId), isTrue);
      });

      test('forwards a payload and allocates a stream', () async {
        final alice = buildClient('alice.key');
        final bob = buildClient('bob.key');
        addTearDown(alice.dispose);
        addTearDown(bob.dispose);

        await alice.applyConfig(config());
        await bob.applyConfig(config());
        expect(await alice.connect(), isTrue);
        expect(await bob.connect(), isTrue);

        final bobId = await IdentityService.forTesting(
          filePath: '${workspace.path}${Platform.pathSeparator}bob.key',
        ).getDeviceId();

        final delivered = bob.payloads.first;

        final sent = await alice.sendPayload(
          toDeviceId: bobId,
          payload: const TransferCancel(
            sessionId: 'session-1',
            reason: 'smoke test',
          ).toJson(),
        );
        expect(sent.isSuccess, isTrue);

        final inbound = await delivered.timeout(const Duration(seconds: 5));
        expect(inbound.type, RelayPayloadType.transferCancel);

        final stream = await alice.createStream(
          peerDeviceId: bobId,
          role: RelayStreamRole.sender,
        );
        expect(stream.isSuccess, isTrue, reason: stream.errorMessage);
        expect(stream.data, hasLength(64));
      });
    },
    skip: configured
        ? false
        : 'set RELAY_TEST_URL and RELAY_TEST_TOKEN to run against a relayd',
  );
}
