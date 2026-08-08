package com.icyhope.icyEasySend

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CLIPBOARD_CHANNEL = "com.icyhope.icy_easy_send/clipboard"
        private const val NETWORK_CHANNEL = "com.icyhope.icy_easy_send/network"
    }

    private var multicastLock: WifiManager.MulticastLock? = null
    private var clipboardChannel: MethodChannel? = null
    private var overlayHelper: ClipboardOverlayHelper? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquireMulticastLock" -> {
                        try {
                            acquireMulticastLock()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to acquire multicast lock: ${e.message}", null)
                        }
                    }
                    "releaseMulticastLock" -> {
                        try {
                            releaseMulticastLock()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to release multicast lock: ${e.message}", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CLIPBOARD_CHANNEL,
        )
        clipboardChannel = channel
        ClipboardBridge.channel = channel
        val overlay = ClipboardOverlayHelper(this, channel)
        overlayHelper = overlay

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getImageFromClipboard" -> {
                    try {
                        result.success(getImageFromClipboard())
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get image from clipboard: ${e.message}", null)
                    }
                }
                "setImageToClipboard" -> {
                    // Kept for channel parity with other platforms; Android write uses super_clipboard.
                    result.success(false)
                }
                "getTextFromClipboard" -> {
                    try {
                        result.success(getTextFromClipboard())
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get text from clipboard: ${e.message}", null)
                    }
                }
                "isOverlayPermissionGranted" -> {
                    result.success(overlay.isOverlayPermissionGranted())
                }
                "requestOverlayPermission" -> {
                    try {
                        overlay.requestOverlayPermission()
                        result.success(overlay.isOverlayPermissionGranted())
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to request overlay permission: ${e.message}", null)
                    }
                }
                "showClipboardOverlay" -> {
                    try {
                        result.success(overlay.showOverlay())
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to show overlay: ${e.message}", null)
                    }
                }
                "hideClipboardOverlay" -> {
                    try {
                        overlay.hideOverlay()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to hide overlay: ${e.message}", null)
                    }
                }
                "overlayRefreshResult" -> {
                    try {
                        val success = call.argument<Boolean>("success") ?: false
                        overlay.showRefreshResult(success)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to show overlay result: ${e.message}", null)
                    }
                }
                "startClipboardChangeListening" -> {
                    try {
                        overlay.startClipboardChangeListening()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to start clipboard listening: ${e.message}", null)
                    }
                }
                "stopClipboardChangeListening" -> {
                    try {
                        overlay.stopClipboardChangeListening()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to stop clipboard listening: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        overlayHelper?.dispose()
        overlayHelper = null
        if (ClipboardBridge.channel === clipboardChannel) {
            ClipboardBridge.channel = null
        }
        clipboardChannel = null
        super.onDestroy()
    }

    private fun acquireMulticastLock() {
        if (multicastLock?.isHeld == true) return

        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        multicastLock = wifi.createMulticastLock("icyEasySendMulticast").apply {
            setReferenceCounted(true)
            acquire()
        }
    }

    private fun releaseMulticastLock() {
        multicastLock?.let {
            if (it.isHeld) it.release()
        }
        multicastLock = null
    }

    private fun getImageFromClipboard(): Map<String, Any>? {
        val image = NativeClipboardReader.readImage(this) ?: return null
        val mimeType = image["mimeType"] as? String ?: "image/png"
        return mapOf(
            "imageData" to (image["imageData"] as ByteArray),
            "fileName" to (image["fileName"] as String),
            "mimeType" to mimeType,
            "format" to mimeType.substringAfter('/'),
        )
    }

    private fun getTextFromClipboard(): String? {
        return NativeClipboardReader.readText(this)?.get("textContent") as? String
    }
}
