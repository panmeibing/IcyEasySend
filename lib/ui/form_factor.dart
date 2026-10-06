import 'dart:io';

import 'package:flutter/services.dart';

/// Which shell the running process should show.
///
/// `--dart-define=UI=tv` and `UI=phone` win, so a phone can preview the TV
/// layout. Otherwise Android reports whether this is a television; every
/// other platform keeps the phone shell.
class AppFormFactor {
  static const _override = String.fromEnvironment('UI');
  static const _channel = MethodChannel(
    'com.icyhope.icy_easy_send/form_factor',
  );

  static bool _isTv = _override == 'tv';

  static bool get isTv => _isTv;

  static Future<void> resolve() async {
    if (_override == 'tv') {
      _isTv = true;
      return;
    }
    if (_override == 'phone') {
      _isTv = false;
      return;
    }
    if (!Platform.isAndroid) {
      _isTv = false;
      return;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isTelevision');
      _isTv = result ?? false;
    } catch (_) {
      _isTv = false;
    }
  }
}
