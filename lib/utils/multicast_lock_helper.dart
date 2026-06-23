import 'dart:io';

import 'package:flutter/services.dart';

/// Acquires Android WifiManager multicast lock so the device can receive
/// UDP multicast/broadcast on WiFi.
class MulticastLockHelper {
  static const _channel = MethodChannel('com.icyhope.icy_easy_send/network');

  static Future<void> acquire() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('acquireMulticastLock');
    } catch (_) {
      // Best-effort; unicast fallback still works without the lock.
    }
  }

  static Future<void> release() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('releaseMulticastLock');
    } catch (_) {}
  }
}
