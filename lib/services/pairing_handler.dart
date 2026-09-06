import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';

import '../utils/constants.dart';
import '../utils/log_util.dart';
import '../utils/network_util.dart';
import 'identity_service.dart';
import 'pairing_prompter.dart';
import 'pairing_service.dart';

/// A pairing the local user has approved but the initiator has not committed.
class _PendingPairing {
  final String deviceId;
  final String publicKey;
  final String deviceName;
  final String platform;
  final String? remoteAddress;
  final Timer expiry;

  _PendingPairing({
    required this.deviceId,
    required this.publicKey,
    required this.deviceName,
    required this.platform,
    required this.remoteAddress,
    required this.expiry,
  });
}

/// Receiver side of LAN pairing.
///
/// `POST /pair/request` shows the pairing code and blocks until the local user
/// decides. `POST /pair/confirm` then commits, once the initiator's user has
/// agreed that both screens showed the same digits.
///
/// The two-step commit exists so a rejection on the initiator's screen does
/// not leave a one-sided trust entry here.
class PairingHandler {
  final BuildContext? Function()? contextGetter;
  final bool Function()? isInBackgroundGetter;

  /// Notified after a pairing is committed, so the settings list can refresh.
  final VoidCallback? onPaired;

  final IdentityService _identityService;
  final PairingService _pairingService;
  final PairingPrompter _prompter;

  final String logTag = LogTags.pairing;

  final Map<String, _PendingPairing> _pending = {};

  /// Device ids with a dialog on screen right now.
  ///
  /// One confirmation at a time keeps the user from being asked to compare
  /// two codes at once, which is exactly the confusion an attacker would want.
  final Set<String> _inFlight = {};

  PairingHandler({
    this.contextGetter,
    this.isInBackgroundGetter,
    this.onPaired,
    IdentityService? identityService,
    PairingService? pairingService,
    PairingPrompter? prompter,
  }) : _identityService = identityService ?? IdentityService.instance,
       _pairingService = pairingService ?? PairingService.instance,
       _prompter = prompter ?? PairingPrompter.instance;

  Future<Response> handlePairRequest(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      if (body is! Map) {
        return _reject('bad_request', status: 400);
      }

      final deviceId = body['deviceId'];
      final publicKeyRaw = body['publicKey'];
      if (deviceId is! String || deviceId.isEmpty || publicKeyRaw is! String) {
        return _reject('bad_request', status: 400);
      }

      final publicKey = IdentityService.decodePublicKey(publicKeyRaw);
      if (publicKey == null ||
          !await IdentityService.matchesDeviceId(deviceId, publicKey)) {
        LogUtil.wTag(logTag, '配对请求的设备码与公钥不匹配: $deviceId');
        return _reject('identity_mismatch');
      }

      if (_inFlight.isNotEmpty) {
        LogUtil.wTag(logTag, '已有配对确认在进行中，拒绝 $deviceId');
        return _reject('busy');
      }

      // Pairing is the one thing that must never be automatic: without a
      // human comparing the digits there is nothing to authenticate against.
      if (!_hasUsableUi()) {
        LogUtil.wTag(logTag, '无可用界面，拒绝配对请求: $deviceId');
        return _reject('no_ui');
      }

      final deviceName = (body['deviceName'] as String?)?.trim();
      final platform = (body['platform'] as String?) ?? '';
      final sas = await PairingService.computeSas(
        publicKey,
        await _identityService.getPublicKeyBytes(),
      );

      final context = contextGetter?.call();
      if (context == null || !context.mounted || !_hasUsableUi()) {
        return _reject('no_ui');
      }

      _inFlight.add(deviceId);
      bool? accepted;
      try {
        accepted = await _prompter.confirmIncoming(
          context,
          peerDeviceName: (deviceName == null || deviceName.isEmpty)
              ? deviceId
              : deviceName,
          sas: sas,
        );
      } finally {
        _inFlight.remove(deviceId);
      }

      if (accepted != true) {
        LogUtil.iTag(logTag, '未接受来自 $deviceId 的配对请求');
        return _reject(accepted == null ? 'timeout' : 'rejected');
      }

      _rememberPending(
        deviceId: deviceId,
        publicKey: publicKeyRaw,
        deviceName: deviceName ?? '',
        platform: platform,
        remoteAddress: _remoteAddress(request),
      );

      return _json({
        'accepted': true,
        'deviceId': await _identityService.getDeviceId(),
        'publicKey': await _identityService.getPublicKeyBase64(),
        'deviceName': await NetworkUtil.getDeviceName(),
        'platform': Platform.operatingSystem,
      });
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '处理配对请求异常: $e', e, stackTrace);
      return _reject('error', status: 500);
    }
  }

  Future<Response> handlePairConfirm(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      if (body is! Map) {
        return _reject('bad_request', status: 400);
      }

      final deviceId = body['deviceId'];
      if (deviceId is! String) {
        return _reject('bad_request', status: 400);
      }

      final pending = _pending.remove(deviceId);
      pending?.expiry.cancel();

      if (body['accepted'] != true) {
        LogUtil.iTag(logTag, '$deviceId 的用户取消了配对');
        return _json({'ok': true, 'paired': false});
      }

      if (pending == null) {
        LogUtil.wTag(logTag, '收到未知或已过期的配对确认: $deviceId');
        return _reject('unknown_pairing', status: 409);
      }

      final stored = await _pairingService.trust(
        deviceId: pending.deviceId,
        publicKey: pending.publicKey,
        deviceName: pending.deviceName,
        platform: pending.platform,
        lastSeenLan: pending.remoteAddress,
      );

      if (stored) {
        LogUtil.iTag(logTag, '已配对设备: ${pending.deviceName} ($deviceId)');
        onPaired?.call();
      }

      return _json({'ok': stored, 'paired': stored});
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '处理配对确认异常: $e', e, stackTrace);
      return _reject('error', status: 500);
    }
  }

  bool _hasUsableUi() {
    if (isInBackgroundGetter?.call() ?? false) {
      return false;
    }
    final context = contextGetter?.call();
    return context != null && context.mounted;
  }

  /// Drops pending pairings; called when the server stops.
  void dispose() {
    for (final pending in _pending.values) {
      pending.expiry.cancel();
    }
    _pending.clear();
    _inFlight.clear();
  }

  void _rememberPending({
    required String deviceId,
    required String publicKey,
    required String deviceName,
    required String platform,
    required String? remoteAddress,
  }) {
    _pending.remove(deviceId)?.expiry.cancel();
    _pending[deviceId] = _PendingPairing(
      deviceId: deviceId,
      publicKey: publicKey,
      deviceName: deviceName,
      platform: platform,
      remoteAddress: remoteAddress,
      expiry: Timer(AppConstants.pairingPendingTtl, () {
        if (_pending.remove(deviceId) != null) {
          LogUtil.iTag(logTag, '配对确认超时，丢弃 $deviceId');
        }
      }),
    );
  }

  String? _remoteAddress(Request request) {
    final connectionInfo =
        request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
    return connectionInfo?.remoteAddress.address;
  }

  Response _json(Map<String, Object?> body) => Response.ok(
    jsonEncode(body),
    headers: {'Content-Type': 'application/json'},
  );

  Response _reject(String reason, {int status = 200}) => Response(
    status,
    body: jsonEncode({'accepted': false, 'ok': false, 'reason': reason}),
    headers: {'Content-Type': 'application/json'},
  );
}
