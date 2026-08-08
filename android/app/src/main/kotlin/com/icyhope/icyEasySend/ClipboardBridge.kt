package com.icyhope.icyEasySend

import io.flutter.plugin.common.MethodChannel

/**
 * Holds the Flutter MethodChannel so transparent Activity / overlay can talk to Dart
 * without bringing MainActivity UI to the foreground.
 */
object ClipboardBridge {
    @Volatile
    var channel: MethodChannel? = null
}
