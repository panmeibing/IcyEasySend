package com.icyhope.icyEasySend

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.wifi.WifiManager
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val CLIPBOARD_CHANNEL = "com.icyhope.icy_easy_send/clipboard"
        private const val NETWORK_CHANNEL = "com.icyhope.icy_easy_send/network"
        private const val FORM_FACTOR_CHANNEL = "com.icyhope.icy_easy_send/form_factor"
        private const val FILES_CHANNEL = "com.icyhope.icy_easy_send/files"
    }

    private var multicastLock: WifiManager.MulticastLock? = null
    private var clipboardChannel: MethodChannel? = null
    private var overlayHelper: ClipboardOverlayHelper? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FORM_FACTOR_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTelevision" -> result.success(isTelevision())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILES_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openFile" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrEmpty()) {
                            result.error("bad-path", "missing path", null)
                        } else {
                            result.success(openExternalFile(path))
                        }
                    }
                    else -> result.notImplemented()
                }
            }

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

    /// Opens [path] in another app, in its own task.
    ///
    /// A viewer launched into this task takes the app down with it if that
    /// viewer crashes during startup. The TV image player does that.
    /// Returns null on success, or a short error token.
    private fun openExternalFile(path: String): String? {
        val file = File(path)
        if (!file.exists()) return "missing"
        return try {
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileProvider.com.crazecoder.openfile",
                file,
            )
            val mime = MimeTypeMap.getSingleton()
                .getMimeTypeFromExtension(file.extension.lowercase()) ?: "*/*"
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            null
        } catch (_: ActivityNotFoundException) {
            "no-app"
        } catch (e: Exception) {
            e.message ?: "error"
        }
    }

    private fun isTelevision(): Boolean {
        val uiMode = resources.configuration.uiMode and Configuration.UI_MODE_TYPE_MASK
        if (uiMode == Configuration.UI_MODE_TYPE_TELEVISION) return true
        val leanback = packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
        val touch = packageManager.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN)
        return leanback && !touch
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
