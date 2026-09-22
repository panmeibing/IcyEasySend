import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:io' show Platform;

/// Whether the app is running on OpenHarmony / HarmonyOS NEXT.
///
/// Uses [Platform.operatingSystem] so this compiles with both upstream Flutter
/// and Flutter-OH (which may also expose [Platform.isOhos]).
bool get isOhosPlatform {
  if (kIsWeb) {
    return false;
  }
  return Platform.operatingSystem == 'ohos';
}
