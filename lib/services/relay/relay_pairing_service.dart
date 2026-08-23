import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../pages/pairing/pairing_confirm_dialog.dart';
import '../../utils/constants.dart';
import '../../utils/log_util.dart';
import '../../utils/network_util.dart';
import '../../utils/operation_result.dart';
import '../../utils/pairing_message_provider.dart';
import '../identity_service.dart';
import '../paired_device_store.dart';
import '../pairing_service.dart';
import '../preferences_service.dart';
import 'relay_client.dart';
import 'relay_protocol.dart';

/// Pairing two devices that have never shared a network (method B).
///
/// The relay forwards these messages to any device id, which is what lets two
/// strangers meet — and also what lets anyone with the server token knock on
/// any door. Three things keep that in proportion: the server rate-limits
/// pairing messages, the user can switch inbound requests off entirely, and an
/// explicit "block" action remembers a peer so it cannot ask again until
/// removed from the blocklist. A normal reject does not block.
///
/// The security of the exchange itself rests entirely on the six digits. The
/// relay can substitute either public key, but not without the two screens
/// disagreeing, so the dialog asks the user to confirm they compared them out
/// of band rather than offering a button that means "probably fine".
///
/// The initiator gets one guarantee the LAN flow cannot offer: it knows the
/// peer's device id in advance, and a device id is a fingerprint of the public
/// key. A substituted key therefore fails that check before the digits are
/// ever shown.
///
/// Sequence (so both screens show the code together):
///  1. Initiator sends [PairRequest].
///  2. Peer immediately replies with [PairAnnounce] (its public key) and opens
///     the comparison dialog.
///  3. Initiator verifies the announce against the typed device code, derives
///     the same digits, and opens its dialog.
///  4. Peer confirms → [PairResponse]; initiator confirms → [PairConfirm].
class RelayPairingService {
  final RelayClient _client;
  final IdentityService _identity;
  final PairingService _pairingService;
  final PairedDeviceStore _store;
  final PreferencesService _preferences;

  /// Supplied by `RelayService`, exactly as for the receive coordinator.
  final BuildContext? Function()? contextGetter;
  final bool Function()? isInBackgroundGetter;
  final VoidCallback? onPaired;

  final String logTag = LogTags.pairing;

  /// Peers whose request is on screen or waiting to be committed.
  final Map<String, _PendingRelayPairing> _pending = {};

  /// Comparison dialogs still open, keyed by the peer that started them.
  ///
  /// Completing with `null` dismisses the dialog without treating it as a
  /// local refusal (so the initiator backing out does not block anyone).
  final Map<String, Completer<IncomingPairingChoice?>> _openDialogs = {};
  bool _dialogOpen = false;

  StreamSubscription<RelayInboundPayload>? _subscription;

  RelayPairingService({
    required RelayClient client,
    this.contextGetter,
    this.isInBackgroundGetter,
    this.onPaired,
    IdentityService? identity,
    PairingService? pairingService,
    PairedDeviceStore? store,
    PreferencesService? preferences,
  }) : _client = client,
       _identity = identity ?? IdentityService.instance,
       _pairingService = pairingService ?? PairingService.instance,
       _store = store ?? PairedDeviceStore.instance,
       _preferences = preferences ?? PreferencesService();

  void start() {
    _subscription ??= _client.payloads.listen(_onPayload);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    for (final pending in _pending.values) {
      pending.expiry.cancel();
    }
    _pending.clear();
    for (final dialog in _openDialogs.values) {
      if (!dialog.isCompleted) {
        dialog.complete(null);
      }
    }
    _openDialogs.clear();
  }

  // -- initiating -----------------------------------------------------------

  /// Asks [peerDeviceId] to pair and returns once both sides can show the code.
  ///
  /// Returns as soon as the peer announces its public key — before either user
  /// has compared the digits — so the initiator's dialog can open alongside
  /// the peer's. [RelayPairingProposal.finish] waits for the peer's comparison
  /// and then commits.
  Future<OperationResult<RelayPairingProposal>> request(
    String peerDeviceId,
  ) async {
    final normalized = peerDeviceId.trim().toLowerCase();
    if (!_isDeviceId(normalized)) {
      return OperationResult.failure(PairingMessages.instance.invalidDeviceCode);
    }

    final localDeviceId = await _identity.getDeviceId();
    if (normalized == localDeviceId) {
      return OperationResult.failure(PairingMessages.instance.cannotPairSelf);
    }
    if (await _store.find(normalized) != null) {
      return OperationResult.failure(PairingMessages.instance.alreadyPaired);
    }

    if (!_client.isConnected && !await _client.connect()) {
      return OperationResult.failure(PairingMessages.instance.relayUnavailable);
    }

    // Await the peer *or* a server error (rate_limited, peer_offline, …).
    // Plain [RelayClient.sendPayload] returns as soon as the frame is written,
    // so a rate-limited request used to look like silence until the announce
    // timeout — which is exactly the "fourth attempt shows nothing" bug.
    final first = await _client.sendAndAwaitReply(
      toDeviceId: normalized,
      kind: RelayKind.pair,
      payload: PairRequest(
        publicKey: await _identity.getPublicKeyBase64(),
        deviceName: await NetworkUtil.getDeviceName(),
        platform: Platform.operatingSystem,
      ).toJson(),
      matches: (payload) =>
          payload['type'] == RelayPayloadType.pairAnnounce ||
          payload['type'] == RelayPayloadType.pairResponse,
      timeout: AppConstants.relayPairReplyTimeout,
    );
    if (!first.isSuccess) {
      return OperationResult.failure(first.errorMessage!);
    }

    final payload = first.data!;

    if (payload['type'] == RelayPayloadType.pairResponse) {
      final response = PairResponse.tryParse(payload);
      // Peer already finished (blocked / rejected / busy / …). Do not burn
      // another rate-limit slot on pair.confirm — the peer is not waiting.
      if (response == null || !response.accepted) {
        return OperationResult.failure(_describeRefusal(response?.reason));
      }
      return _proposalFromKey(
        peerDeviceId: normalized,
        publicKey: response.publicKey,
        deviceName: response.deviceName,
        platform: response.platform,
        peerDecision: Future.value(PairingPeerDecision.accepted),
      );
    }

    final announce = PairAnnounce.tryParse(payload);
    if (announce == null) {
      return OperationResult.failure(PairingMessages.instance.pairingFailed);
    }

    // Listen for the peer's later comparison while this device's dialog is up.
    final decided = Completer<PairingPeerDecision>();
    final replies = _client.payloads.listen((inbound) {
      if (inbound.fromDeviceId != normalized) {
        return;
      }
      if (inbound.payload['type'] != RelayPayloadType.pairResponse) {
        return;
      }
      final response = PairResponse.tryParse(inbound.payload);
      if (response == null || decided.isCompleted) {
        return;
      }
      decided.complete(_decisionFromResponse(response));
    });

    final proposal = await _proposalFromKey(
      peerDeviceId: normalized,
      publicKey: announce.publicKey,
      deviceName: announce.deviceName,
      platform: announce.platform,
      peerDecision: decided.future.timeout(
        AppConstants.relayPairReplyTimeout,
        onTimeout: () => PairingPeerDecision.timeout,
      ),
    );
    if (!proposal.isSuccess) {
      await replies.cancel();
      return proposal;
    }

    unawaited(
      decided.future
          .timeout(AppConstants.relayPairReplyTimeout)
          .whenComplete(replies.cancel),
    );
    return proposal;
  }

  Future<OperationResult<RelayPairingProposal>> _proposalFromKey({
    required String peerDeviceId,
    required String publicKey,
    required String deviceName,
    required String platform,
    required Future<PairingPeerDecision> peerDecision,
  }) async {
    final decoded = IdentityService.decodePublicKey(publicKey);
    if (decoded == null ||
        !await IdentityService.matchesDeviceId(peerDeviceId, decoded)) {
      LogUtil.wTag(logTag, '中转配对公钥与设备码不匹配: $peerDeviceId');
      await _tell(peerDeviceId, accepted: false);
      return OperationResult.failure(
        PairingMessages.instance.identityMismatch,
      );
    }

    return OperationResult.success(
      data: RelayPairingProposal._(
        service: this,
        peerDeviceId: peerDeviceId,
        peerPublicKey: publicKey,
        peerDeviceName: deviceName,
        peerPlatform: platform,
        sas: await PairingService.computeSas(
          await _identity.getPublicKeyBytes(),
          decoded,
        ),
        peerDecision: peerDecision,
      ),
    );
  }

  Future<bool> _tell(String peerDeviceId, {required bool accepted}) async {
    final result = await _client.sendPayload(
      toDeviceId: peerDeviceId,
      kind: RelayKind.pair,
      payload: PairConfirm(accepted: accepted).toJson(),
    );
    return result.isSuccess;
  }

  // -- answering ------------------------------------------------------------

  void _onPayload(RelayInboundPayload inbound) {
    switch (inbound.payload['type']) {
      case RelayPayloadType.pairRequest:
        unawaited(_onRequest(inbound));
      case RelayPayloadType.pairConfirm:
        unawaited(_onConfirm(inbound));
    }
  }

  Future<void> _onRequest(RelayInboundPayload inbound) async {
    final request = PairRequest.tryParse(inbound.payload);
    if (request == null) {
      return;
    }

    final peerDeviceId = inbound.fromDeviceId;
    final publicKey = IdentityService.decodePublicKey(request.publicKey);
    if (publicKey == null ||
        !await IdentityService.matchesDeviceId(peerDeviceId, publicKey)) {
      LogUtil.wTag(logTag, '中转配对请求的设备码与公钥不匹配: $peerDeviceId');
      await _refuse(peerDeviceId, 'identity_mismatch');
      return;
    }

    if (!await _preferences.getRelayPairingEnabled()) {
      LogUtil.iTag(logTag, '已关闭中转配对，忽略来自 $peerDeviceId 的请求');
      await _refuse(peerDeviceId, 'disabled');
      return;
    }

    // Explicit blocklist only — a normal reject does not write here. Always
    // answer so the initiator is not left waiting for a timeout.
    if (await _preferences.isRelayPairingBlocked(peerDeviceId)) {
      LogUtil.iTag(logTag, '已拉黑，拒绝来自 $peerDeviceId 的中转配对请求');
      await _refuse(peerDeviceId, 'blocked');
      return;
    }

    if (await _store.find(peerDeviceId) != null) {
      await _refuse(peerDeviceId, 'already_paired');
      return;
    }

    if (_dialogOpen) {
      await _refuse(peerDeviceId, 'busy');
      return;
    }
    if (!_hasUsableUi()) {
      LogUtil.wTag(logTag, '无可用界面，拒绝中转配对请求: $peerDeviceId');
      await _refuse(peerDeviceId, 'no_ui');
      return;
    }

    final sas = await PairingService.computeSas(
      publicKey,
      await _identity.getPublicKeyBytes(),
    );

    final context = contextGetter?.call();
    if (context == null || !context.mounted || !_hasUsableUi()) {
      await _refuse(peerDeviceId, 'no_ui');
      return;
    }

    // Announce first so the initiator can open its dialog while this one is
    // still coming up — that is what makes the out-of-band comparison possible.
    await _client.sendPayload(
      toDeviceId: peerDeviceId,
      kind: RelayKind.pair,
      payload: PairAnnounce(
        publicKey: await _identity.getPublicKeyBase64(),
        deviceName: await NetworkUtil.getDeviceName(),
        platform: Platform.operatingSystem,
      ).toJson(),
    );

    final remoteDismiss = Completer<IncomingPairingChoice?>();
    _openDialogs[peerDeviceId] = remoteDismiss;
    _dialogOpen = true;
    IncomingPairingChoice? choice;
    try {
      // The dialog closes itself when [remoteDismiss] completes (initiator
      // cancel), so a single [showDialog] future covers both paths — no
      // Future.any that would leave a stranded route behind.
      choice = await PairingConfirmDialog.showIncomingRelay(
        context,
        peerDeviceName: request.deviceName.isEmpty
            ? peerDeviceId
            : request.deviceName,
        sas: sas,
        remoteClose: remoteDismiss.future,
      );
    } finally {
      _openDialogs.remove(peerDeviceId);
      _dialogOpen = false;
      if (!remoteDismiss.isCompleted) {
        remoteDismiss.complete(null);
      }
    }

    // `rejected` / `blocked` = this user answered. `null` = timeout or
    // initiator cancel — do not write the blocklist in those cases.
    if (choice != IncomingPairingChoice.accepted) {
      LogUtil.iTag(logTag, '未接受来自 $peerDeviceId 的中转配对请求');
      if (choice == IncomingPairingChoice.blocked) {
        await _preferences.blockRelayPairing(
          peerDeviceId,
          deviceName: request.deviceName,
        );
        await _refuse(peerDeviceId, 'blocked');
      } else if (choice == IncomingPairingChoice.rejected) {
        await _refuse(peerDeviceId, 'rejected');
      } else {
        await _refuse(peerDeviceId, 'timeout');
      }
      return;
    }

    _remember(
      peerDeviceId: peerDeviceId,
      publicKey: request.publicKey,
      deviceName: request.deviceName,
      platform: request.platform,
    );

    await _client.sendPayload(
      toDeviceId: peerDeviceId,
      kind: RelayKind.pair,
      payload: PairResponse(
        accepted: true,
        publicKey: await _identity.getPublicKeyBase64(),
        deviceName: await NetworkUtil.getDeviceName(),
        platform: Platform.operatingSystem,
      ).toJson(),
    );
  }

  /// Commits the pairing once the initiator's user has agreed as well.
  Future<void> _onConfirm(RelayInboundPayload inbound) async {
    final confirm = PairConfirm.tryParse(inbound.payload);
    if (confirm == null) {
      return;
    }

    // Initiator backed out (or otherwise finished) while the comparison dialog
    // is still on screen — dismiss it without counting as a local refusal.
    final open = _openDialogs.remove(inbound.fromDeviceId);
    if (open != null && !open.isCompleted) {
      open.complete(null);
      if (!confirm.accepted) {
        LogUtil.iTag(logTag, '${inbound.fromDeviceId} 的用户取消了中转配对');
      }
      return;
    }

    final pending = _pending.remove(inbound.fromDeviceId);
    pending?.expiry.cancel();
    if (pending == null) {
      if (!confirm.accepted) {
        return;
      }
      LogUtil.wTag(logTag, '收到未知或已过期的中转配对确认: ${inbound.fromDeviceId}');
      return;
    }

    if (!confirm.accepted) {
      LogUtil.iTag(logTag, '${inbound.fromDeviceId} 的用户取消了中转配对');
      return;
    }

    final stored = await _pairingService.trust(
      deviceId: pending.deviceId,
      publicKey: pending.publicKey,
      deviceName: pending.deviceName,
      platform: pending.platform,
    );
    if (stored) {
      LogUtil.iTag(
        logTag,
        '已通过中转配对: ${pending.deviceName} (${pending.deviceId})',
      );
      onPaired?.call();
    }
  }

  Future<void> _refuse(String peerDeviceId, String reason) async {
    await _client.sendPayload(
      toDeviceId: peerDeviceId,
      kind: RelayKind.pair,
      payload: PairResponse(accepted: false, reason: reason).toJson(),
    );
  }

  void _remember({
    required String peerDeviceId,
    required String publicKey,
    required String deviceName,
    required String platform,
  }) {
    _pending.remove(peerDeviceId)?.expiry.cancel();
    _pending[peerDeviceId] = _PendingRelayPairing(
      deviceId: peerDeviceId,
      publicKey: publicKey,
      deviceName: deviceName,
      platform: platform,
      expiry: Timer(AppConstants.relayPairPendingTtl, () {
        if (_pending.remove(peerDeviceId) != null) {
          LogUtil.iTag(logTag, '中转配对确认超时，丢弃 $peerDeviceId');
        }
      }),
    );
  }

  bool _hasUsableUi() {
    if (isInBackgroundGetter?.call() ?? false) {
      return false;
    }
    final context = contextGetter?.call();
    return context != null && context.mounted;
  }

  String _describeRefusal(String? reason) {
    final messages = PairingMessages.instance;
    switch (reason) {
      case 'disabled':
        return messages.peerRelayPairingOff;
      case 'already_paired':
        return messages.peerAlreadyPaired;
      case 'busy':
        return messages.peerBusy;
      case 'blocked':
        return messages.peerPairingBlocked;
      case 'no_ui':
        return messages.peerUnreachable;
      case 'timeout':
        return messages.peerTimeout;
      default:
        return messages.peerRejected;
    }
  }

  static PairingPeerDecision _decisionFromResponse(PairResponse response) {
    if (response.accepted) {
      return PairingPeerDecision.accepted;
    }
    if (response.reason == 'blocked') {
      return PairingPeerDecision.blocked;
    }
    if (response.reason == 'timeout') {
      return PairingPeerDecision.timeout;
    }
    return PairingPeerDecision.rejected;
  }

  /// A device id is 32 hexadecimal characters; anything else is a typo.
  static bool _isDeviceId(String value) {
    return RegExp(r'^[0-9a-f]{32}$').hasMatch(value);
  }
}

/// An announced pairing, waiting for both users to compare the digits.
class RelayPairingProposal {
  final RelayPairingService _service;

  final String peerDeviceId;
  final String peerPublicKey;
  final String peerDeviceName;
  final String peerPlatform;

  /// The six digits both users read to each other.
  final String sas;

  /// Settles when the peer's user has compared the digits (or given up).
  final Future<PairingPeerDecision> peerDecision;

  Future<bool>? _completion;

  RelayPairingProposal._({
    required RelayPairingService service,
    required this.peerDeviceId,
    required this.peerPublicKey,
    required this.peerDeviceName,
    required this.peerPlatform,
    required this.sas,
    required this.peerDecision,
  }) : _service = service;

  /// Commits or abandons the pairing on both devices.
  ///
  /// Only the first call has an effect, so a dialog that is dismissed while
  /// the commit is in flight cannot contradict it.
  Future<bool> finish(bool accepted) {
    return _completion ??= _finish(accepted);
  }

  Future<bool> _finish(bool accepted) async {
    if (!accepted) {
      await _service._tell(peerDeviceId, accepted: false);
      return false;
    }

    final decision = await peerDecision;
    if (decision != PairingPeerDecision.accepted) {
      // Peer already refused or timed out; still tell them we are done so any
      // pending state on their side is cleared.
      await _service._tell(peerDeviceId, accepted: false);
      return false;
    }

    final told = await _service._tell(peerDeviceId, accepted: true);
    if (!told) {
      return false;
    }

    return _service._pairingService.trust(
      deviceId: peerDeviceId,
      publicKey: peerPublicKey,
      deviceName: peerDeviceName,
      platform: peerPlatform,
    );
  }
}

/// A pairing this device's user approved, waiting on the initiator.
class _PendingRelayPairing {
  final String deviceId;
  final String publicKey;
  final String deviceName;
  final String platform;
  final Timer expiry;

  _PendingRelayPairing({
    required this.deviceId,
    required this.publicKey,
    required this.deviceName,
    required this.platform,
    required this.expiry,
  });
}
