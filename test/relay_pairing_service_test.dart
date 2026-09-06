import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/paired_device.dart';
import 'package:icy_easy_send/pages/pairing/pairing_confirm_dialog.dart';
import 'package:icy_easy_send/services/identity_service.dart';
import 'package:icy_easy_send/services/paired_device_store.dart';
import 'package:icy_easy_send/services/pairing_service.dart';
import 'package:icy_easy_send/services/preferences_service.dart';
import 'package:icy_easy_send/services/relay/relay_client.dart';
import 'package:icy_easy_send/services/relay/relay_pairing_service.dart';
import 'package:icy_easy_send/services/relay/relay_protocol.dart';
import 'package:icy_easy_send/utils/operation_result.dart';
import 'package:icy_easy_send/utils/pairing_message_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pairing two devices that have never shared a network (method B).
///
/// Both ends are real services talking through a pair of clients wired to each
/// other, so what is exercised is the actual exchange: the fingerprint check
/// that catches a swapped key, the switches that let a user refuse to take
/// part, and the two-step commit that keeps one side from trusting a device
/// the other side walked away from.
void main() {
  late Directory workspace;
  late IdentityService initiatorIdentity;
  late IdentityService peerIdentity;
  late String initiatorDeviceId;
  late String peerDeviceId;
  late _FakeRelayClient initiatorClient;
  late _FakeRelayClient peerClient;
  late PairedDeviceStore initiatorStore;
  late PairedDeviceStore peerStore;
  late RelayPairingService initiator;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    workspace = await Directory.systemTemp.createTemp('relay-pairing');
    initiatorIdentity = IdentityService.forTesting(
      filePath: _path(workspace, 'initiator.key'),
    );
    peerIdentity = IdentityService.forTesting(
      filePath: _path(workspace, 'peer.key'),
    );
    initiatorDeviceId = await initiatorIdentity.getDeviceId();
    peerDeviceId = await peerIdentity.getDeviceId();

    initiatorClient = _FakeRelayClient(
      deviceId: initiatorDeviceId,
      identity: initiatorIdentity,
    );
    peerClient = _FakeRelayClient(
      deviceId: peerDeviceId,
      identity: peerIdentity,
    );
    initiatorClient.peer = peerClient;
    peerClient.peer = initiatorClient;

    initiatorStore = PairedDeviceStore.forTesting(
      filePath: _path(workspace, 'initiator.json'),
    );
    peerStore = PairedDeviceStore.forTesting(
      filePath: _path(workspace, 'peer.json'),
    );

    initiator = RelayPairingService(
      client: initiatorClient,
      identity: initiatorIdentity,
      pairingService: PairingService.forTesting(
        identityService: initiatorIdentity,
        store: initiatorStore,
      ),
      store: initiatorStore,
      preferences: PreferencesService(),
    )..start();
  });

  tearDown(() async {
    await initiator.stop();
    await initiatorClient.shutdown();
    await peerClient.shutdown();
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  /// Answers the initiator's request the way a peer whose user agreed would.
  void scriptAcceptingPeer({String? publicKey}) {
    peerClient.onPayload = (from, payload) async {
      if (payload['type'] != RelayPayloadType.pairRequest) {
        return;
      }
      final key = publicKey ?? await peerIdentity.getPublicKeyBase64();
      await peerClient.sendPayload(
        toDeviceId: from,
        payload: PairAnnounce(
          publicKey: key,
          deviceName: 'Peer',
          platform: 'linux',
        ).toJson(),
      );
      await peerClient.sendPayload(
        toDeviceId: from,
        payload: PairResponse(
          accepted: true,
          publicKey: key,
          deviceName: 'Peer',
          platform: 'linux',
        ).toJson(),
      );
    };
  }

  group('asking to pair', () {
    test('rejects anything that is not a device code', () async {
      for (final input in ['', 'abc', 'zz$peerDeviceId', '${peerDeviceId}0']) {
        final result = await initiator.request(input);
        expect(result.isSuccess, isFalse, reason: input);
        expect(result.errorMessage, PairingMessages.instance.invalidDeviceCode);
      }
      expect(initiatorClient.sent, isEmpty);
    });

    test('accepts a code the user typed in capitals', () async {
      scriptAcceptingPeer();

      final result = await initiator.request(peerDeviceId.toUpperCase());

      expect(result.isSuccess, isTrue, reason: result.errorMessage);
      expect(result.data!.peerDeviceId, peerDeviceId);
    });

    test('refuses to pair with itself', () async {
      final result = await initiator.request(initiatorDeviceId);

      expect(result.errorMessage, PairingMessages.instance.cannotPairSelf);
      expect(initiatorClient.sent, isEmpty);
    });

    test('refuses a device that is already paired', () async {
      await initiatorStore.upsert(
        PairedDevice(
          deviceId: peerDeviceId,
          publicKey: await peerIdentity.getPublicKeyBase64(),
          deviceName: 'Peer',
          pairedAt: DateTime.now(),
        ),
      );

      final result = await initiator.request(peerDeviceId);

      expect(result.errorMessage, PairingMessages.instance.alreadyPaired);
      expect(initiatorClient.sent, isEmpty);
    });

    test('gives up when the relay cannot be reached', () async {
      initiatorClient.online = false;

      final result = await initiator.request(peerDeviceId);

      expect(result.errorMessage, PairingMessages.instance.relayUnavailable);
    });

    test('turns the peer refusal into something the user can act on', () async {
      peerClient.onPayload = (from, payload) async {
        await peerClient.sendPayload(
          toDeviceId: from,
          payload: const PairResponse(
            accepted: false,
            reason: 'disabled',
          ).toJson(),
        );
      };

      final result = await initiator.request(peerDeviceId);

      expect(result.errorMessage, PairingMessages.instance.peerRelayPairingOff);
      // Early refusals do not send pair.confirm — that used to burn a second
      // rate-limit slot and make the fourth retry look like silence.
      expect(
        initiatorClient.sent.map((e) => e.payload['type']),
        everyElement(RelayPayloadType.pairRequest),
      );
    });

    test('explains when the peer still trusts this device', () async {
      peerClient.onPayload = (from, payload) async {
        await peerClient.sendPayload(
          toDeviceId: from,
          payload: const PairResponse(
            accepted: false,
            reason: 'already_paired',
          ).toJson(),
        );
      };

      final result = await initiator.request(peerDeviceId);

      expect(result.errorMessage, PairingMessages.instance.peerAlreadyPaired);
    });

    test('stops when the answered key is not the one the code names', () async {
      // A relay that swaps the key it forwards is the attack method B has to
      // survive, and the device code is a fingerprint of that key.
      scriptAcceptingPeer(
        publicKey: await initiatorIdentity.getPublicKeyBase64(),
      );

      final result = await initiator.request(peerDeviceId);

      expect(result.errorMessage, PairingMessages.instance.identityMismatch);
      expect(await initiatorStore.find(peerDeviceId), isNull);
    });

    test('both devices arrive at the same digits', () async {
      scriptAcceptingPeer();

      final result = await initiator.request(peerDeviceId);

      final expected = await PairingService.computeSas(
        await peerIdentity.getPublicKeyBytes(),
        await initiatorIdentity.getPublicKeyBytes(),
      );
      expect(result.data!.sas, expected);
      expect(result.data!.sas, hasLength(6));
    });

    test('nothing is trusted until the user has compared them', () async {
      scriptAcceptingPeer();

      expect((await initiator.request(peerDeviceId)).isSuccess, isTrue);

      expect(await initiatorStore.find(peerDeviceId), isNull);
    });

    test('agreeing writes the trust entry and tells the peer', () async {
      scriptAcceptingPeer();
      final proposal = (await initiator.request(peerDeviceId)).data!;

      expect(await proposal.finish(true), isTrue);

      final stored = await initiatorStore.find(peerDeviceId);
      expect(stored!.publicKey, await peerIdentity.getPublicKeyBase64());
      expect(stored.deviceName, 'Peer');
      expect(initiatorClient.sent.last.payload['type'],
          RelayPayloadType.pairConfirm);
      expect(initiatorClient.sent.last.payload['accepted'], isTrue);
    });

    test('walking away trusts nobody', () async {
      scriptAcceptingPeer();
      final proposal = (await initiator.request(peerDeviceId)).data!;

      expect(await proposal.finish(false), isFalse);

      expect(await initiatorStore.find(peerDeviceId), isNull);
      expect(initiatorClient.sent.last.payload['accepted'], isFalse);
    });

    test('only the first decision counts', () async {
      scriptAcceptingPeer();
      final proposal = (await initiator.request(peerDeviceId)).data!;

      expect(await proposal.finish(true), isTrue);
      // A dialog dismissed while the commit was in flight must not be able to
      // contradict it.
      expect(await proposal.finish(false), isTrue);
      expect(await initiatorStore.find(peerDeviceId), isNotNull);
    });
  });

  group('being asked to pair', () {
    late RelayPairingService peer;

    /// Starts the peer's service with the given UI availability.
    RelayPairingService startPeer({BuildContext? Function()? contextGetter}) {
      return peer = RelayPairingService(
        client: peerClient,
        identity: peerIdentity,
        pairingService: PairingService.forTesting(
          identityService: peerIdentity,
          store: peerStore,
        ),
        store: peerStore,
        preferences: PreferencesService(),
        contextGetter: contextGetter ?? () => null,
        isInBackgroundGetter: () => false,
      )..start();
    }

    tearDown(() async {
      await peer.stop();
    });

    /// Sends a raw pairing request and returns the answer, if any.
    Future<Map<String, dynamic>?> ask(PairRequest request) async {
      startPeer();
      await initiatorClient.sendPayload(
        toDeviceId: peerDeviceId,
        payload: request.toJson(),
      );
      // Two turns: one for the peer to read it, one for its answer to arrive.
      await pumpEventQueue();
      return peerClient.sent.isEmpty ? null : peerClient.sent.last.payload;
    }

    Future<PairRequest> genuineRequest() async => PairRequest(
      publicKey: await initiatorIdentity.getPublicKeyBase64(),
      deviceName: 'Initiator',
      platform: 'windows',
    );

    test('refuses a request whose key does not match its device code', () async {
      final answer = await ask(
        PairRequest(
          publicKey: await peerIdentity.getPublicKeyBase64(),
          deviceName: 'Impostor',
          platform: 'windows',
        ),
      );

      expect(answer!['accepted'], isFalse);
      expect(answer['reason'], 'identity_mismatch');
    });

    test('refuses everyone when inbound pairing is switched off', () async {
      await PreferencesService().saveRelayPairingEnabled(false);

      final answer = await ask(await genuineRequest());

      expect(answer!['accepted'], isFalse);
      expect(answer['reason'], 'disabled');
    });

    test('refuses a device that is on the pairing blocklist', () async {
      await PreferencesService().blockRelayPairing(initiatorDeviceId);

      final answer = await ask(await genuineRequest());

      expect(answer!['accepted'], isFalse);
      expect(answer['reason'], 'blocked');
    });

    test('refuses a device that is already in the trust list', () async {
      await peerStore.upsert(
        PairedDevice(
          deviceId: initiatorDeviceId,
          publicKey: await initiatorIdentity.getPublicKeyBase64(),
          deviceName: 'Initiator',
          pairedAt: DateTime.now(),
        ),
      );

      final answer = await ask(await genuineRequest());

      expect(answer!['reason'], 'already_paired');
    });

    test('refuses when there is no screen to show the code on', () async {
      final answer = await ask(await genuineRequest());

      expect(answer!['accepted'], isFalse);
      expect(answer['reason'], 'no_ui');
    });

    test('a confirmation for a request that was never answered is ignored',
        () async {
      startPeer();

      await initiatorClient.sendPayload(
        toDeviceId: peerDeviceId,
        payload: const PairConfirm(accepted: true).toJson(),
      );
      await pumpEventQueue();

      expect(await peerStore.find(initiatorDeviceId), isNull);
    });
  });

  group('the whole exchange', () {
    late RelayPairingService peer;
    late BuildContext peerContext;

    Future<void> startPeerWithUi(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              peerContext = context;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      // Started outside the fake clock: everything the two services do is
      // ordinary asynchronous work, and only the dialog belongs to the widget
      // tree's own notion of time.
      await tester.runAsync(() async {
        peer = RelayPairingService(
          client: peerClient,
          identity: peerIdentity,
          pairingService: PairingService.forTesting(
            identityService: peerIdentity,
            store: peerStore,
          ),
          store: peerStore,
          preferences: PreferencesService(),
          contextGetter: () => peerContext,
          isInBackgroundGetter: () => false,
          // These tests drive the real dialog, so they install it the way
          // main() does rather than leaning on the auto-refusing default.
          prompter: const DialogPairingPrompter(),
        )..start();
      });
    }

    /// Lets both halves of the exchange make progress until [done] holds.
    ///
    /// The two services read files and preferences, which only advances inside
    /// [WidgetTester.runAsync], while the widget tree only advances between
    /// pumps. Neither alone gets anywhere, so this alternates them.
    Future<void> settleUntil(
      WidgetTester tester,
      bool Function() done, {
      String what = 'the exchange',
    }) async {
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
        if (done()) {
          return;
        }
      }
      fail('$what never happened');
    }

    /// Starts something on one of the services without blocking on it.
    ///
    /// Neither side can finish while the test is waiting inside `runAsync`,
    /// because each is waiting on the other, so the result is collected
    /// through a callback and driven by [settleUntil] instead.
    Future<void> begin(WidgetTester tester, Future<void> Function() action) {
      return tester.runAsync(() async => unawaited(action()));
    }

    testWidgets('both users agreeing pairs both devices', (tester) async {
      await startPeerWithUi(tester);

      OperationResult<RelayPairingProposal>? asked;
      await begin(
        tester,
        () => initiator.request(peerDeviceId).then((r) => asked = r),
      );
      // Announce arrives before either user taps, so the proposal is ready
      // while the peer's dialog is already on screen.
      await settleUntil(
        tester,
        () =>
            asked != null &&
            find
                .text(PairingMessages.instance.codesMatch)
                .evaluate()
                .isNotEmpty,
        what: 'simultaneous pairing dialogs',
      );

      expect(asked!.isSuccess, isTrue);
      final proposal = asked!.data!;
      expect(proposal.sas, hasLength(6));

      await tester.tap(find.text(PairingMessages.instance.codesMatch));
      await settleUntil(
        tester,
        () => find.text(PairingMessages.instance.codesMatch).evaluate().isEmpty,
        what: 'the peer dialog to close',
      );

      // The peer has agreed but is not trusting anyone yet: it is waiting to
      // hear that this user saw the same digits.
      await tester.runAsync(() async {
        expect(await peerStore.find(initiatorDeviceId), isNull);
      });

      bool? committed;
      await begin(
        tester,
        () => proposal.finish(true).then((r) => committed = r),
      );
      await settleUntil(tester, () => committed != null, what: 'the commit');

      expect(committed, isTrue);
      await tester.runAsync(() async {
        expect(await initiatorStore.find(peerDeviceId), isNotNull);
        expect(await peerStore.find(initiatorDeviceId), isNotNull);
      });
    });

    testWidgets('the initiator backing out leaves the peer untrusting',
        (tester) async {
      await startPeerWithUi(tester);

      OperationResult<RelayPairingProposal>? asked;
      await begin(
        tester,
        () => initiator.request(peerDeviceId).then((r) => asked = r),
      );
      await settleUntil(
        tester,
        () =>
            asked != null &&
            find
                .text(PairingMessages.instance.codesMatch)
                .evaluate()
                .isNotEmpty,
        what: 'simultaneous pairing dialogs',
      );

      bool? committed;
      await begin(
        tester,
        () => asked!.data!.finish(false).then((r) => committed = r),
      );
      await settleUntil(tester, () => committed != null, what: 'the refusal');

      expect(committed, isFalse);
      await tester.runAsync(() async {
        expect(await initiatorStore.find(peerDeviceId), isNull);
        expect(await peerStore.find(initiatorDeviceId), isNull);
      });
    });

    testWidgets('rejecting without block still allows a later request',
        (tester) async {
      await startPeerWithUi(tester);

      OperationResult<RelayPairingProposal>? asked;
      await begin(
        tester,
        () => initiator.request(peerDeviceId).then((r) => asked = r),
      );
      await settleUntil(
        tester,
        () =>
            asked != null &&
            find
                .text(PairingMessages.instance.codesDiffer)
                .evaluate()
                .isNotEmpty,
        what: 'simultaneous pairing dialogs',
      );

      await tester.tap(find.text(PairingMessages.instance.codesDiffer));
      await settleUntil(
        tester,
        () => find.text(PairingMessages.instance.codesDiffer).evaluate().isEmpty,
        what: 'the peer dialog to close',
      );

      bool? committed;
      await begin(
        tester,
        () => asked!.data!.finish(true).then((r) => committed = r),
      );
      await settleUntil(tester, () => committed != null, what: 'the refusal');

      expect(committed, isFalse);
      await tester.runAsync(() async {
        expect(
          await PreferencesService().getRelayPairBlocklist(),
          isNot(contains(initiatorDeviceId)),
        );
      });

      // A plain reject must not lock the peer out of another attempt.
      peerClient.sent.clear();
      OperationResult<RelayPairingProposal>? asked2;
      await begin(
        tester,
        () => initiator.request(peerDeviceId).then((r) => asked2 = r),
      );
      await settleUntil(
        tester,
        () =>
            asked2 != null &&
            asked2!.isSuccess &&
            find
                .text(PairingMessages.instance.codesMatch)
                .evaluate()
                .isNotEmpty,
        what: 'a second pairing dialog',
      );
      expect(asked2!.isSuccess, isTrue);
    });

    testWidgets('blocking remembers the peer and refuses the next request',
        (tester) async {
      await startPeerWithUi(tester);

      OperationResult<RelayPairingProposal>? asked;
      await begin(
        tester,
        () => initiator.request(peerDeviceId).then((r) => asked = r),
      );
      await settleUntil(
        tester,
        () =>
            asked != null &&
            find.text(PairingMessages.instance.blockPeer).evaluate().isNotEmpty,
        what: 'simultaneous pairing dialogs',
      );

      await tester.tap(find.text(PairingMessages.instance.blockPeer));
      await settleUntil(
        tester,
        () => find.text(PairingMessages.instance.blockPeer).evaluate().isEmpty,
        what: 'the peer dialog to close',
      );

      bool? committed;
      await begin(
        tester,
        () => asked!.data!.finish(true).then((r) => committed = r),
      );
      await settleUntil(tester, () => committed != null, what: 'the block');

      expect(committed, isFalse);
      await tester.runAsync(() async {
        expect(
          await PreferencesService().getRelayPairBlocklist(),
          contains(initiatorDeviceId),
        );
      });

      peerClient.sent.clear();
      var asked2 = false;
      await begin(tester, () async {
        await initiatorClient.sendPayload(
          toDeviceId: peerDeviceId,
          payload: PairRequest(
            publicKey: await initiatorIdentity.getPublicKeyBase64(),
            deviceName: 'Initiator',
            platform: 'windows',
          ).toJson(),
        );
        asked2 = true;
      });
      await settleUntil(tester, () => asked2, what: 'the second request');
      await settleUntil(
        tester,
        () => peerClient.sent.isNotEmpty,
        what: 'the blocked refusal',
      );

      expect(peerClient.sent.last.payload['type'], RelayPayloadType.pairResponse);
      expect(peerClient.sent.last.payload['accepted'], isFalse);
      expect(peerClient.sent.last.payload['reason'], 'blocked');
      expect(find.text(PairingMessages.instance.codesMatch), findsNothing);
    });

    tearDown(() async {
      await peer.stop();
    });
  });
}

String _path(Directory directory, String name) =>
    '${directory.path}${Platform.pathSeparator}$name';

/// A relay client wired straight to another one.
///
/// Only the four members the pairing service uses are real; everything else
/// belongs to the socket, which is exactly what these tests do not need.
class _FakeRelayClient extends RelayClient {
  final String deviceId;

  final StreamController<RelayInboundPayload> _inbound =
      StreamController<RelayInboundPayload>.broadcast();

  /// Everything this client was asked to forward.
  final List<({String to, Map<String, dynamic> payload})> sent = [];

  /// The client on the other end of the imaginary relay.
  _FakeRelayClient? peer;

  /// Whether the relay is reachable at all.
  bool online = true;

  /// Stands in for a peer that has no pairing service of its own.
  Future<void> Function(String from, Map<String, dynamic> payload)? onPayload;

  _FakeRelayClient({required this.deviceId, required IdentityService identity})
    : super(identity: identity);

  @override
  bool get isConnected => online;

  @override
  Future<bool> connect() async => online;

  @override
  Stream<RelayInboundPayload> get payloads => _inbound.stream;

  @override
  Future<OperationResult<void>> sendPayload({
    required String toDeviceId,
    required Map<String, dynamic> payload,
    String kind = RelayKind.transfer,
  }) async {
    if (!online) {
      return OperationResult.failure('未连接到中转服务器');
    }
    sent.add((to: toDeviceId, payload: payload));
    peer?._receive(deviceId, payload);
    return OperationResult.success();
  }

  @override
  Future<OperationResult<Map<String, dynamic>>> sendAndAwaitReply({
    required String toDeviceId,
    required Map<String, dynamic> payload,
    required bool Function(Map<String, dynamic> reply) matches,
    required Duration timeout,
    String kind = RelayKind.transfer,
  }) async {
    if (!online) {
      return OperationResult.failure('未连接到中转服务器');
    }

    // Armed before sending, as the real client does, so an answer that comes
    // straight back is not missed.
    final reply = _inbound.stream
        .firstWhere(
          (event) => event.fromDeviceId == toDeviceId && matches(event.payload),
        )
        .timeout(timeout);

    await sendPayload(toDeviceId: toDeviceId, payload: payload, kind: kind);

    try {
      return OperationResult.success(data: (await reply).payload);
    } on TimeoutException {
      return OperationResult.failure('对方设备没有响应');
    }
  }

  void _receive(String from, Map<String, dynamic> payload) {
    if (_inbound.isClosed) {
      return;
    }
    _inbound.add(RelayInboundPayload(fromDeviceId: from, payload: payload));
    final handler = onPayload;
    if (handler != null) {
      unawaited(handler(from, payload));
    }
  }

  Future<void> shutdown() async {
    await _inbound.close();
    await dispose();
  }
}
