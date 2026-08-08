package com.icyhope.icyEasySend

import android.annotation.SuppressLint
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

/**
 * Native floating bubble + clipboard change listener for cache refresh.
 *
 * Tap strategy:
 * 1) Temporarily make the bubble focusable and read clipboard natively.
 * 2) If that fails, launch a transparent [ClipboardRefreshActivity].
 */
class ClipboardOverlayHelper(
    private val context: Context,
    private val channel: MethodChannel,
) {
    private val appContext = context.applicationContext
    private val windowManager =
        appContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val clipboardManager =
        appContext.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

    private var overlayView: View? = null
    private var layoutParams: WindowManager.LayoutParams? = null
    private var clipListener: ClipboardManager.OnPrimaryClipChangedListener? = null
    private var listening = false
    private var refreshInFlight = false

    fun isOverlayPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(appContext)
        } else {
            true
        }
    }

    fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${appContext.packageName}"),
        ).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        appContext.startActivity(intent)
    }

    @SuppressLint("ClickableViewAccessibility")
    fun showOverlay(): Boolean {
        if (!isOverlayPermissionGranted()) return false
        if (overlayView != null) return true

        val density = appContext.resources.displayMetrics.density
        val sizePx = (BUBBLE_SIZE_DP * density).toInt()
        val bubble = TextView(appContext).apply {
            text = "📋"
            textSize = 22f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(COLOR_IDLE)
            }
            elevation = 8f
        }

        val container = FrameLayout(appContext).apply {
            layoutParams = FrameLayout.LayoutParams(sizePx, sizePx)
            addView(bubble, FrameLayout.LayoutParams(sizePx, sizePx))
        }

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            sizePx,
            sizePx,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = (appContext.resources.displayMetrics.widthPixels - sizePx - (24 * density).toInt())
            y = appContext.resources.displayMetrics.heightPixels / 3
        }

        var lastX = 0
        var lastY = 0
        var startX = 0
        var startY = 0
        var moved = false

        container.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    lastX = params.x
                    lastY = params.y
                    startX = event.rawX.toInt()
                    startY = event.rawY.toInt()
                    moved = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX.toInt() - startX
                    val dy = event.rawY.toInt() - startY
                    if (abs(dx) > TOUCH_SLOP_PX || abs(dy) > TOUCH_SLOP_PX) {
                        moved = true
                    }
                    params.x = lastX + dx
                    params.y = lastY + dy
                    try {
                        windowManager.updateViewLayout(container, params)
                    } catch (_: Exception) {
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!moved) {
                        onBubbleTapped(bubble)
                    }
                    true
                }
                else -> false
            }
        }

        return try {
            windowManager.addView(container, params)
            overlayView = container
            layoutParams = params
            true
        } catch (e: Exception) {
            e.printStackTrace()
            overlayView = null
            layoutParams = null
            false
        }
    }

    fun hideOverlay() {
        overlayView?.let {
            try {
                windowManager.removeView(it)
            } catch (_: Exception) {
            }
        }
        overlayView = null
        layoutParams = null
    }

    fun showRefreshResult(success: Boolean) {
        val view = overlayView ?: return
        val bubble = (view as? FrameLayout)?.getChildAt(0) as? TextView ?: return
        val bg = bubble.background as? GradientDrawable ?: return
        bg.setColor(if (success) COLOR_SUCCESS else COLOR_ERROR)
        bubble.postDelayed({
            bg.setColor(COLOR_IDLE)
        }, RESULT_FLASH_MS)
    }

    fun startClipboardChangeListening() {
        if (listening) return
        val listener = ClipboardManager.OnPrimaryClipChangedListener {
            try {
                channel.invokeMethod("onClipboardChanged", null)
            } catch (_: Exception) {
            }
        }
        clipboardManager.addPrimaryClipChangedListener(listener)
        clipListener = listener
        listening = true
    }

    fun stopClipboardChangeListening() {
        clipListener?.let {
            try {
                clipboardManager.removePrimaryClipChangedListener(it)
            } catch (_: Exception) {
            }
        }
        clipListener = null
        listening = false
    }

    fun dispose() {
        stopClipboardChangeListening()
        hideOverlay()
    }

    private fun onBubbleTapped(bubble: TextView) {
        if (refreshInFlight) return
        refreshInFlight = true

        val bg = bubble.background as? GradientDrawable
        bg?.setColor(COLOR_PRESSED)

        tryFocusAndRead { focusPathSettled ->
            if (focusPathSettled) {
                refreshInFlight = false
                return@tryFocusAndRead
            }

            bg?.setColor(COLOR_IDLE)
            try {
                launchTransparentRefreshActivity()
            } catch (e: Exception) {
                e.printStackTrace()
                showRefreshResult(false)
            } finally {
                refreshInFlight = false
            }
        }
    }

    /**
     * Temporarily make the overlay focusable, read clipboard, then restore flags.
     *
     * [onDone] receives `true` when the focus path settled (native read succeeded or
     * Dart was already invoked), so callers should not fall back. Receives `false`
     * only when clipboard could not be read and a transparent Activity fallback is needed.
     */
    private fun tryFocusAndRead(onDone: (Boolean) -> Unit) {
        val view = overlayView
        val params = layoutParams
        if (view == null || params == null) {
            onDone(false)
            return
        }

        val originalFlags = params.flags
        params.flags = originalFlags and WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE.inv()

        try {
            windowManager.updateViewLayout(view, params)
        } catch (e: Exception) {
            e.printStackTrace()
            onDone(false)
            return
        }

        view.isFocusable = true
        view.isFocusableInTouchMode = true
        view.requestFocus()

        view.postDelayed({
            val payload = NativeClipboardReader.read(appContext)
            restoreNonFocusable(view, params, originalFlags)

            if (payload == null) {
                onDone(false)
                return@postDelayed
            }

            // Native read succeeded; never fall back even if Dart rejects the payload.
            var settled = false
            fun settle() {
                if (settled) return
                settled = true
                onDone(true)
            }

            try {
                channel.invokeMethod(
                    "onNativeClipboardCaptured",
                    payload,
                    object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            // Bubble color is updated by Dart via overlayRefreshResult.
                            settle()
                        }

                        override fun error(
                            errorCode: String,
                            errorMessage: String?,
                            errorDetails: Any?,
                        ) {
                            showRefreshResult(false)
                            settle()
                        }

                        override fun notImplemented() {
                            showRefreshResult(false)
                            settle()
                        }
                    },
                )
            } catch (e: Exception) {
                e.printStackTrace()
                showRefreshResult(false)
                settle()
                return@postDelayed
            }

            // If Dart never answers, unlock the bubble without falling back.
            view.postDelayed({ settle() }, DART_REPLY_TIMEOUT_MS)
        }, FOCUS_SETTLE_MS)
    }

    private fun restoreNonFocusable(
        view: View,
        params: WindowManager.LayoutParams,
        originalFlags: Int,
    ) {
        params.flags = originalFlags
        try {
            windowManager.updateViewLayout(view, params)
        } catch (_: Exception) {
        }
        view.clearFocus()
        view.isFocusable = false
        view.isFocusableInTouchMode = false
    }

    private fun launchTransparentRefreshActivity() {
        val intent = Intent(appContext, ClipboardRefreshActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_NO_ANIMATION or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS,
            )
        }
        appContext.startActivity(intent)
    }

    companion object {
        private const val BUBBLE_SIZE_DP = 56
        private const val TOUCH_SLOP_PX = 8
        private const val FOCUS_SETTLE_MS = 160L
        private const val DART_REPLY_TIMEOUT_MS = 1200L
        private const val RESULT_FLASH_MS = 900L

        private val COLOR_IDLE = Color.parseColor("#2196F3")
        private val COLOR_PRESSED = Color.parseColor("#1976D2")
        private val COLOR_SUCCESS = Color.parseColor("#43A047")
        private val COLOR_ERROR = Color.parseColor("#E53935")
    }
}
