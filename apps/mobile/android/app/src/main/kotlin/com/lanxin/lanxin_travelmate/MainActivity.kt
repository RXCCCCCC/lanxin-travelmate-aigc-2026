package com.lanxin.lanxin_travelmate

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "lanxin_travelmate/photo_picker"
    private val galleryRequestCode = 4201
    private val cameraRequestCode = 4202
    private var pendingResult: MethodChannel.Result? = null
    private var pendingCameraUri: Uri? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFromGallery" -> launchGallery(result)
                "takePhoto" -> launchCamera(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun launchGallery(result: MethodChannel.Result) {
        if (!claimPendingResult(result)) return
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
        }
        try {
            startActivityForResult(intent, galleryRequestCode)
        } catch (_: Exception) {
            clearPendingWithError("gallery_unavailable", "No gallery app can handle image selection")
        }
    }

    private fun launchCamera(result: MethodChannel.Result) {
        if (!claimPendingResult(result)) return
        val outputUri = createCameraOutputUri()
        if (outputUri == null) {
            clearPendingWithError("camera_output_unavailable", "Could not create camera output uri")
            return
        }
        pendingCameraUri = outputUri
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, outputUri)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        try {
            startActivityForResult(intent, cameraRequestCode)
        } catch (_: Exception) {
            contentResolver.delete(outputUri, null, null)
            pendingCameraUri = null
            clearPendingWithError("camera_unavailable", "No camera app can handle image capture")
        }
    }

    private fun claimPendingResult(result: MethodChannel.Result): Boolean {
        if (pendingResult != null) {
            result.error("picker_busy", "Another photo picker request is already running", null)
            return false
        }
        pendingResult = result
        return true
    }

    private fun createCameraOutputUri(): Uri? {
        val filename = "lanxin-photo-${System.currentTimeMillis()}.jpg"
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, filename)
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/LanxinTravelmate")
            }
        }
        return contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            galleryRequestCode -> handlePickerResult(resultCode, data?.data, "gallery")
            cameraRequestCode -> handlePickerResult(resultCode, pendingCameraUri, "camera")
        }
    }

    private fun handlePickerResult(resultCode: Int, uri: Uri?, source: String) {
        val result = pendingResult ?: return
        pendingResult = null
        pendingCameraUri = null
        if (resultCode != Activity.RESULT_OK || uri == null) {
            if (source == "camera" && uri != null) contentResolver.delete(uri, null, null)
            result.success(null)
            return
        }
        result.success(photoPayload(uri, source))
    }

    private fun photoPayload(uri: Uri, source: String): Map<String, String> {
        return mapOf(
            "localUri" to uri.toString(),
            "filename" to displayName(uri),
            "mimeType" to (contentResolver.getType(uri) ?: "image/jpeg"),
            "source" to source,
        )
    }

    private fun displayName(uri: Uri): String {
        val projection = arrayOf(MediaStore.Images.Media.DISPLAY_NAME)
        contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) {
                val value = cursor.getString(index)
                if (!value.isNullOrBlank()) return value
            }
        }
        return uri.lastPathSegment ?: "selected-photo.jpg"
    }

    private fun clearPendingWithError(code: String, message: String) {
        pendingResult?.error(code, message, null)
        pendingResult = null
    }
}
