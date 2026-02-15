package com.icyhope.icyEasySend

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.icyhope.icy_easy_send/clipboard"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
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
        
        val item = clip.getItemAt(0)
        val uri = item.uri
        
        if (uri != null) {
            try {
                val inputStream = contentResolver.openInputStream(uri)
                val bitmap = BitmapFactory.decodeStream(inputStream)
                inputStream?.close()
                
                if (bitmap != null) {
                    val outputStream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                    val imageBytes = outputStream.toByteArray()
                    bitmap.recycle()
                    
                    return mapOf(
                        "imageData" to imageBytes,
                        "format" to "png"
                    )
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
