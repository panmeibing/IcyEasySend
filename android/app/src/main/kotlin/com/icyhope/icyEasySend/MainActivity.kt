package com.icyhope.icyEasySend

import android.content.ClipboardManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.icyhope.icy_easy_send/clipboard"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Clipboard channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getImageFromClipboard" -> {
                    try {
                        val imageData = getImageFromClipboard()
                        if (imageData != null) {
                            result.success(imageData)
                        } else {
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get image from clipboard: ${e.message}", null)
                    }
                }
                "setImageToClipboard" -> {
                    try {
                        val imageData = call.argument<ByteArray>("imageData")
                        val format = call.argument<String>("format") ?: "png"
                        
                        if (imageData != null) {
                            val success = setImageToClipboard(imageData, format)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGUMENT", "Image data is null", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to set image to clipboard: ${e.message}", null)
                    }
                }
                "getTextFromClipboard" -> {
                    try {
                        result.success(getTextFromClipboard())
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get text from clipboard: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getImageFromClipboard(): Map<String, Any>? {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

        if (!clipboard.hasPrimaryClip()) {
            return null
        }

        val clip = clipboard.primaryClip ?: return null
        if (clip.itemCount == 0) {
            return null
        }

        for (index in 0 until clip.itemCount) {
            val item = clip.getItemAt(index)
            val uri = item.uri ?: continue

            try {
                val mimeType = contentResolver.getType(uri)
                if (mimeType == null || !mimeType.startsWith("image/")) {
                    continue
                }

                val bytes = contentResolver.openInputStream(uri)?.use { stream ->
                    stream.readBytes()
                } ?: continue

                if (bytes.isEmpty()) {
                    continue
                }

                val fileName = queryDisplayName(uri) ?: defaultImageFileName(mimeType)
                return mapOf(
                    "imageData" to bytes,
                    "fileName" to fileName,
                    "mimeType" to mimeType,
                    "format" to mimeType.substringAfter('/')
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        return null
    }

    private fun queryDisplayName(uri: android.net.Uri): String? {
        if (uri.scheme != "content") {
            return uri.lastPathSegment
        }

        contentResolver.query(uri, arrayOf(android.provider.OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0 && cursor.moveToFirst()) {
                    return cursor.getString(nameIndex)
                }
            }

        return uri.lastPathSegment
    }

    private fun defaultImageFileName(mimeType: String): String {
        return when {
            mimeType.contains("jpeg") || mimeType.contains("jpg") -> "clipboard_image.jpg"
            mimeType.contains("webp") -> "clipboard_image.webp"
            mimeType.contains("gif") -> "clipboard_image.gif"
            else -> "clipboard_image.png"
        }
    }

    private fun isTextMimeType(mimeType: String): Boolean {
        return mimeType.startsWith("text/") ||
            mimeType == "application/json" ||
            mimeType.endsWith("+json") ||
            mimeType.endsWith("+xml")
    }

    private fun getTextFromClipboard(): String? {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

        if (!clipboard.hasPrimaryClip()) {
            return null
        }

        val clip = clipboard.primaryClip ?: return null
        if (clip.itemCount == 0) {
            return null
        }

        for (index in 0 until clip.itemCount) {
            val item = clip.getItemAt(index)

            val uri = item.uri
            if (uri != null) {
                val mimeType = contentResolver.getType(uri)
                if (mimeType != null && !isTextMimeType(mimeType)) {
                    continue
                }
            }

            try {
                val coerced = item.coerceToText(this)?.toString()?.trim()
                if (!coerced.isNullOrEmpty()) {
                    return coerced
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            try {
                val plain = item.text?.toString()?.trim()
                if (!plain.isNullOrEmpty()) {
                    return plain
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            try {
                val html = item.htmlText?.trim()
                if (!html.isNullOrEmpty()) {
                    return html
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        return null
    }

    private fun setImageToClipboard(imageData: ByteArray, format: String): Boolean {
        return try {
            // Android clipboard doesn't directly support setting images
            // This would require saving to a content provider first
            // For now, return false to indicate not supported
            false
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
