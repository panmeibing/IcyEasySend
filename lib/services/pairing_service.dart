import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

import '../models/paired_device.dart';
import '../utils/constants.dart';
import '../utils/http_helper.dart';
import '../utils/log_util.dart';
import '../utils/network_util.dart';
import '../utils/operation_result.dart';
import '../utils/pairing_message_provider.dart';
import 'identity_service.dart';
import 'paired_device_store.dart';
import 'transfer/health_checker.dart';

/// Outcome of the peer's half of the handshake.
enum PairingPeerDecision { accepted, rejected, blocked, timeout, error }

/// LAN pairing (method A in `docs/relay-design.md`).
///
/// The exchange is deliberately split so both screens can show the same code
/// at the same time, which is the only thing that makes the out-of-band
/// comparison meaningful:
///
///  1. [prepare] fetches the peer's public key from `/health` and derives the
///     short authentication string locally. Nothing is trusted yet.
///  2. The initiator shows the code and calls [PairingHandshake.submit],
///     which makes the peer show the same code and wait for its user.
///  3. Once both users have agreed, [PairingHandshake.finish] tells the peer
///     to commit and stores the peer locally.
///
/// The public key is fetched over plain HTTP, so a LAN attacker could swap it.
/// The code comparison is what closes that hole: a man in the middle would
/// have to make two different key pairs produce the same six digits.
class PairingService {
  static final PairingService instance = PairingService._();

  PairingService._()
    : _healthChecker = HealthChecker(),
      _identityService = IdentityService.instance,
      _store = PairedDeviceStore.instance;

  PairingService.forTesting({
    HealthChecker? healthChecker,
    IdentityService? identityService,
    PairedDeviceStore? store,
  }) : _healthChecker = healthChecker ?? HealthChecker(),
       _identityService = identityService ?? IdentityService.instance,
       _store = store ?? PairedDeviceStore.instance;

  final HealthChecker _healthChecker;
  final IdentityService _identityService;
  final PairedDeviceStore _store;

  static final Sha256 _sha256 = Sha256();

  final String logTag = LogTags.pairing;

  /// Derives the six-digit code both devices display.
  ///
  /// The two public keys are sorted before hashing so the initiator and the
  /// receiver, which see them in opposite order, still agree on the digits.
  static Future<String> computeSas(
    List<int> publicKeyA,
    List<int> publicKeyB,
  ) async {
    final ordered = _compareBytes(publicKeyA, publicKeyB) <= 0
        ? [publicKeyA, publicKeyB]
        : [publicKeyB, publicKeyA];

    final input = <int>[
      ...utf8.encode(AppConstants.sasContext),
      ...ordered[0],
      ...ordered[1],
    ];

    final digest = await _sha256.hash(input);
    final bytes = digest.bytes;
    final value =
        (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];

    final modulus = _pow10(AppConstants.sasDigits);
    return (value % modulus).toString().padLeft(AppConstants.sasDigits, '0');
  }

  /// Looks up [targetAddress] and derives the pairing code.
  ///
  /// [targetAddress] is `ip` or `ip:port`, matching the rest of the app.
  Future<OperationResult<PairingHandshake>> prepare(String targetAddress) async {
    final health = await _healthChecker.checkHealth(targetAddress);
    if (!health.isSuccess) {
      LogUtil.wTag(logTag, '配对准备失败, 无法访问 $targetAddress');
      return OperationResult.failure(PairingMessages.instance.peerUnreachable);
    }

    final data = health.data!;
    if (!data.supportsPairing) {
      LogUtil.wTag(logTag, '$targetAddress 未提供设备身份，无法配对');
      return OperationResult.failure(PairingMessages.instance.peerUnsupported);
    }

    final peerPublicKey = IdentityService.decodePublicKey(data.publicKey);
    if (peerPublicKey == null ||
        !await IdentityService.matchesDeviceId(data.deviceId!, peerPublicKey)) {
      LogUtil.wTag(logTag, '$targetAddress 的设备码与公钥不匹配');
      return OperationResult.failure(PairingMessages.instance.identityMismatch);
    }

    final localDeviceId = await _identityService.getDeviceId();
    if (localDeviceId == data.deviceId) {
      return OperationResult.failure(PairingMessages.instance.cannotPairSelf);
    }

    final sas = await computeSas(
      await _identityService.getPublicKeyBytes(),
      peerPublicKey,
    );

    return OperationResult.success(
      data: PairingHandshake._(
        service: this,
        targetAddress: targetAddress,
        sas: sas,
        peerDeviceId: data.deviceId!,
        peerPublicKey: data.publicKey!,
        peerDeviceName: data.deviceName,
        localDeviceId: localDeviceId,
      ),
    );
  }

  /// Stores a confirmed peer.
  ///
  /// Shared by both sides of the handshake so the trust list is written the
  /// same way whether this device initiated or received.
  Future<bool> trust({
    required String deviceId,
    required String publicKey,
    required String deviceName,
    required String platform,
    String? lastSeenLan,
  }) {
    return _store.upsert(
      PairedDevice(
        deviceId: deviceId,
        publicKey: publicKey,
        deviceName: deviceName,
        platform: platform,
        pairedAt: DateTime.now(),
        lastSeenLan: lastSeenLan,
      ),
    );
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  static int _compareBytes(List<int> a, List<int> b) {
    final shared = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < shared; i++) {
      if (a[i] != b[i]) {
        return a[i] - b[i];
      }
    }
    return a.length - b.length;
  }
}

/// An in-flight LAN pairing, driven by the confirmation dialog.
class PairingHandshake {
  final PairingService _service;

  final String targetAddress;

  /// The six digits the user compares against the peer's screen.
  final String sas;

  final String peerDeviceId;
  final String peerPublicKey;
  final String peerDeviceName;
  final String localDeviceId;

  Future<PairingPeerDecision>? _peerDecision;
  Future<bool>? _completion;
  String _peerPlatform = '';

  PairingHandshake._({
    required PairingService service,
    required this.targetAddress,
    required this.sas,
    required this.peerDeviceId,
    required this.peerPublicKey,
    required this.peerDeviceName,
    required this.localDeviceId,
  }) : _service = service;

  /// Asks the peer to show the same code, and resolves once its user decides.
  ///
  /// Safe to call more than once; the request is only sent on the first call.
  Future<PairingPeerDecision> submit() {
    return _peerDecision ??= _submit();
  }

  /// Commits or abandons the pairing on both devices.
  ///
  /// The peer is told either way so a rejected pairing does not sit in its
  /// pending list until it expires.
  ///
  /// Only the first call has an effect: cancelling while the commit is already
  /// in flight must not send a contradicting decision.
  Future<bool> finish(bool accepted) {
    return _completion ??= _finish(accepted);
  }

  Future<bool> _finish(bool accepted) async {
    final confirmed = await _sendConfirm(accepted);
    if (!accepted) {
      return false;
    }
    if (!confirmed) {
      LogUtil.wTag(
        _service.logTag,
        '对端未能确认配对，跳过本地信任写入以免单边配对',
      );
      return false;
    }

    return _service.trust(
      deviceId: peerDeviceId,
      publicKey: peerPublicKey,
      deviceName: peerDeviceName,
      platform: _peerPlatform,
      lastSeenLan: targetAddress,
    );
  }

  Future<PairingPeerDecision> _submit() async {
    final localName = await NetworkUtil.getDeviceName();
    final body = jsonEncode({
      'protocolVersion': AppConstants.protocolVersion,
      'deviceId': localDeviceId,
      'publicKey': await _service._identityService.getPublicKeyBase64(),
      'deviceName': localName,
      'platform': Platform.operatingSystem,
    });

    final result = await HttpHelper.post(
      NetworkUtil.buildHttpUrl(targetAddress, '/pair/request'),
      headers: const {'Content-Type': 'application/json'},
      body: body,
      timeout: AppConstants.pairingRequestTimeout,
    );

    if (!result.isSuccess) {
      LogUtil.wTag(_service.logTag, '配对请求失败: ${result.errorMessage}');
      return PairingPeerDecision.error;
    }

    final parsed = HttpHelper.parseJsonResponse(result.data!);
    if (!parsed.isSuccess) {
      return PairingPeerDecision.error;
    }

    final json = parsed.data!;
    if (json['accepted'] == true) {
      // Guard against the peer answering with a different key than the one
      // the code was derived from.
      if (json['publicKey'] != peerPublicKey) {
        LogUtil.wTag(_service.logTag, '对端返回的公钥与健康检查不一致，中止配对');
        return PairingPeerDecision.error;
      }
      _peerPlatform = json['platform'] as String? ?? '';
      return PairingPeerDecision.accepted;
    }

    return json['reason'] == 'timeout'
        ? PairingPeerDecision.timeout
        : PairingPeerDecision.rejected;
  }

  Future<bool> _sendConfirm(bool accepted) async {
    final result = await HttpHelper.post(
      NetworkUtil.buildHttpUrl(targetAddress, '/pair/confirm'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'deviceId': localDeviceId, 'accepted': accepted}),
      timeout: AppConstants.pairingConfirmTimeout,
    );

    if (!result.isSuccess) {
      LogUtil.wTag(_service.logTag, '配对确认失败: ${result.errorMessage}');
      return false;
    }

    final parsed = HttpHelper.parseJsonResponse(result.data!);
    return parsed.isSuccess && parsed.data!['ok'] == true;
  }
}
