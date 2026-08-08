package com.icyhope.icyEasySend

import android.content.ClipboardManager
import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns

/**
 * Shared clipboard reader used by overlay focus path and transparent Activity.
 */
object NativeClipboardReader {
    /**
     * Returns a Flutter-friendly map:
     * - text: `{ type: "text", textContent: String }`
     * - image: `{ type: "image", imageData: ByteArray, fileName, mimeType }`
     * or null when empty / inaccessible.
     */
    fun read(context: Context): Map<String, Any>? {
        return readImage(context) ?: readText(context)
    }

    fun readImage(context: Context): Map<String, Any>? {
        val clip = primaryClip(context) ?: return null

        for (index in 0 until clip.itemCount) {
            val uri = clip.getItemAt(index).uri ?: continue
            try {
                val mimeType = context.contentResolver.getType(uri)
                if (mimeType == null || !mimeType.startsWith("image/")) continue

                val bytes = context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                if (bytes == null || bytes.isEmpty()) continue

                val fileName = queryDisplayName(context, uri) ?: defaultImageFileName(mimeType)
                return mapOf(
                    "type" to "image",
                    "imageData" to bytes,
                    "fileName" to fileName,
                    "mimeType" to mimeType,
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        return null
    }

    fun readText(context: Context): Map<String, Any>? {
        val clip = primaryClip(context) ?: return null

        for (index in 0 until clip.itemCount) {
            val item = clip.getItemAt(index)

            val uri = item.uri
            if (uri != null) {
                val mimeType = context.contentResolver.getType(uri)
                if (mimeType != null && !isTextMimeType(mimeType)) continue
            }

            try {
                val coerced = item.coerceToText(context)?.toString()?.trim()
                if (!coerced.isNullOrEmpty()) {
                    return mapOf("type" to "text", "textContent" to coerced)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            try {
                val plain = item.text?.toString()?.trim()
                if (!plain.isNullOrEmpty()) {
                    return mapOf("type" to "text", "textContent" to plain)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            try {
                val html = item.htmlText?.trim()
                if (!html.isNullOrEmpty()) {
                    return mapOf("type" to "text", "textContent" to html)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        return null
    }

    private fun primaryClip(context: Context): android.content.ClipData? {
        val clipboard =
            context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        if (!clipboard.hasPrimaryClip()) return null
        val clip = clipboard.primaryClip ?: return null
        if (clip.itemCount == 0) return null
        return clip
    }

    private fun isTextMimeType(mimeType: String): Boolean {
        return mimeType.startsWith("text/") ||
            mimeType == "application/json" ||
            mimeType.endsWith("+json") ||
            mimeType.endsWith("+xml")
    }

    private fun queryDisplayName(context: Context, uri: Uri): String? {
        if (uri.scheme != "content") return uri.lastPathSegment

        context.contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
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
}
