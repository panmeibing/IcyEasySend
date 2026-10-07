import 'dart:convert';

import '../utils/log_util.dart';
import 'preferences_service.dart';

/// Checks the `X-Secret-Key` a LAN peer presents against this device's key.
///
/// A matching key skips the receive prompt entirely, so it is the one thing
/// standing between a stranger on the network and an unattended write. Each
/// address therefore gets only a handful of wrong guesses before its attempts
/// stop counting for a while.
class SecretKeyVerifier {
  SecretKeyVerifier._({PreferencesService? preferencesService})
    : _preferencesService = preferencesService ?? PreferencesService();

  static final SecretKeyVerifier instance = SecretKeyVerifier._();

  /// Fresh instance with its own failure bookkeeping, for tests.
  factory SecretKeyVerifier.forTesting({
    PreferencesService? preferencesService,
  }) => SecretKeyVerifier._(preferencesService: preferencesService);

  static const int _maxFailures = 5;
  static const Duration _failureWindow = Duration(minutes: 1);
  static const Duration _lockout = Duration(minutes: 5);

  final PreferencesService _preferencesService;
  final Map<String, _FailureRecord> _failures = {};
  final String logTag = LogTags.server;

  /// Whether [presented] is this device's key. [remoteAddress] is the address
  /// the request really came from; without one no lockout can be applied.
  Future<bool> verify(
    String? presented, {
    required String? remoteAddress,
  }) async {
    if (presented == null || presented.isEmpty) {
      return false;
    }

    final now = DateTime.now();
    final key = remoteAddress ?? '';
    final record = _failures[key];
    if (record != null && record.lockedUntil != null) {
      if (now.isBefore(record.lockedUntil!)) {
        LogUtil.wTag(logTag, '秘钥尝试过多，暂时忽略来自 $remoteAddress 的秘钥');
        return false;
      }
      _failures.remove(key);
    }

    final saved = await _preferencesService.getDeviceSecretKey();
    if (saved != null &&
        saved.isNotEmpty &&
        _constantTimeEquals(saved, presented)) {
      _failures.remove(key);
      return true;
    }

    _recordFailure(key, now);
    LogUtil.wTag(logTag, '秘钥验证失败或未设置本机秘钥: $remoteAddress');
    return false;
  }

  void _recordFailure(String key, DateTime now) {
    final record = _failures[key];
    if (record == null || now.difference(record.windowStart) > _failureWindow) {
      _failures[key] = _FailureRecord(windowStart: now, count: 1);
      return;
    }
    record.count++;
    if (record.count >= _maxFailures) {
      record.lockedUntil = now.add(_lockout);
    }
  }

  static bool _constantTimeEquals(String a, String b) {
    final x = utf8.encode(a);
    final y = utf8.encode(b);
    var diff = x.length ^ y.length;
    for (var i = 0; i < x.length && i < y.length; i++) {
      diff |= x[i] ^ y[i];
    }
    return diff == 0;
  }
}

class _FailureRecord {
  _FailureRecord({required this.windowStart, required this.count});

  final DateTime windowStart;
  int count;
  DateTime? lockedUntil;
}
