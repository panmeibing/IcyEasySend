package com.icyhope.icyEasySend

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/**
 * Fully transparent Activity used only to obtain input focus for clipboard reads
 * when the floating bubble cannot gain focus by itself.
 */
class ClipboardRefreshActivity : Activity() {
    private var finished = false
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Safety timeout if focus never arrives.
        handler.postDelayed({
            if (!finished) readAndFinish()
        }, FOCUS_TIMEOUT_MS)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            handler.postDelayed({ readAndFinish() }, FOCUS_SETTLE_MS)
        }
    }

    private fun readAndFinish() {
        if (finished) return
        finished = true
        handler.removeCallbacksAndMessages(null)

        val payload = NativeClipboardReader.read(this)
        val channel = ClipboardBridge.channel
        if (channel == null) {
            finishQuietly()
            return
        }

        // Notify Dart (null = empty / unreadable) so the overlay can flash feedback.
        try {
            channel.invokeMethod(
                "onNativeClipboardCaptured",
                payload,
                object : MethodChannel.Result {
                    override fun success(result: Any?) = finishQuietly()
                    override fun error(
                        errorCode: String,
                        errorMessage: String?,
                        errorDetails: Any?,
                    ) = finishQuietly()
                    override fun notImplemented() = finishQuietly()
                },
            )
        } catch (_: Exception) {
            finishQuietly()
            return
        }

        // Safety dismiss if Dart never answers.
        handler.postDelayed({ finishQuietly() }, DART_REPLY_TIMEOUT_MS)
    }

    private fun finishQuietly() {
        if (isFinishing || isDestroyed) return
        try {
            finish()
            @Suppress("DEPRECATION")
            overridePendingTransition(0, 0)
        } catch (_: Exception) {
        }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    companion object {
        private const val FOCUS_TIMEOUT_MS = 1500L
        private const val FOCUS_SETTLE_MS = 120L
        private const val DART_REPLY_TIMEOUT_MS = 800L
    }
}
