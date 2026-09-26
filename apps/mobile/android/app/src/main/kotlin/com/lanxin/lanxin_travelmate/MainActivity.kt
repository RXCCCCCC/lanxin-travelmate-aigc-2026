package com.lanxin.lanxin_travelmate

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.speech.RecognizerIntent
import android.speech.tts.TextToSpeech
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val photoChannelName = "lanxin_travelmate/photo_picker"
    private val locationChannelName = "lanxin_travelmate/location"
    private val voiceChannelName = "lanxin_travelmate/voice"
    private val notificationChannelName = "lanxin_travelmate/notifications"
    private val reminderNotificationChannelId = "lanxin_reminders"
    private val galleryRequestCode = 4201
    private val cameraRequestCode = 4202
    private val cameraPermissionRequestCode = 4203
    private val locationPermissionRequestCode = 4301
    private val speechRequestCode = 4401
    private val recordAudioPermissionRequestCode = 4402
    private val notificationPermissionRequestCode = 4501
    private var pendingResult: MethodChannel.Result? = null
    private var pendingCameraUri: Uri? = null
    private var pendingCameraPermissionResult: MethodChannel.Result? = null
    private var pendingLocationResult: MethodChannel.Result? = null
    private var pendingVoiceResult: MethodChannel.Result? = null
    private var pendingNotificationResult: MethodChannel.Result? = null
    private var pendingNotificationPayload: Map<String, String>? = null
    private var pendingLocationListener: LocationListener? = null
    private var pendingLocationTimeout: Runnable? = null
    private var textToSpeech: TextToSpeech? = null
    private var ttsReady = false
    private var nextNotificationId = 5100

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createReminderNotificationChannel()
        textToSpeech = TextToSpeech(this, this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, photoChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFromGallery" -> launchGallery(result)
                "takePhoto" -> launchCamera(result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, locationChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentLocation" -> getCurrentLocation(result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, voiceChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVoiceInput" -> startVoiceInput(result)
                "speakText" -> speakText(call.argument<String>("text") ?: "", result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "showReminderNotification" -> showReminderNotification(
                    call.argument<String>("title") ?: "蓝心同行提醒",
                    call.argument<String>("body") ?: "",
                    result,
                )
                else -> result.notImplemented()
            }
        }
    }

    override fun onInit(status: Int) {
        ttsReady = status == TextToSpeech.SUCCESS
        if (ttsReady) {
            textToSpeech?.language = Locale.CHINESE
        }
    }

    private fun startVoiceInput(result: MethodChannel.Result) {
        if (!hasRecordAudioPermission()) {
            pendingVoiceResult = result
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                recordAudioPermissionRequestCode,
            )
            return
        }
        launchSpeechRecognizer(result)
    }

    private fun hasRecordAudioPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
    }

    private fun launchSpeechRecognizer(result: MethodChannel.Result) {
        if (pendingVoiceResult != null) {
            result.error("voice_busy", "Another voice input request is already running", null)
            return
        }
        pendingVoiceResult = result
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.CHINESE.toLanguageTag())
            putExtra(RecognizerIntent.EXTRA_PROMPT, "请告诉蓝小心你的旅行需求")
        }
        try {
            startActivityForResult(intent, speechRequestCode)
        } catch (_: Exception) {
            pendingVoiceResult = null
            result.error("voice_unavailable", "No speech recognizer can handle voice input", null)
        }
    }

    private fun speakText(text: String, result: MethodChannel.Result) {
        val value = text.trim()
        if (value.isEmpty()) {
            result.success(false)
            return
        }
        if (!ttsReady) {
            result.error("tts_unavailable", "TextToSpeech is not ready", null)
            return
        }
        val status = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            textToSpeech?.speak(value, TextToSpeech.QUEUE_FLUSH, null, "lanxin-tts-${System.currentTimeMillis()}")
        } else {
            @Suppress("DEPRECATION")
            textToSpeech?.speak(value, TextToSpeech.QUEUE_FLUSH, null)
        }
        result.success(status == TextToSpeech.SUCCESS)
    }

    private fun showReminderNotification(title: String, body: String, result: MethodChannel.Result) {
        val payload = mapOf(
            "title" to title.trim().ifEmpty { "蓝心同行提醒" },
            "body" to body.trim(),
        )
        if (payload["body"].isNullOrEmpty()) {
            result.success(false)
            return
        }
        if (needsNotificationPermission()) {
            if (pendingNotificationResult != null) {
                result.error("notification_busy", "Another notification permission request is already running", null)
                return
            }
            pendingNotificationResult = result
            pendingNotificationPayload = payload
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                notificationPermissionRequestCode,
            )
            return
        }
        result.success(deliverReminderNotification(payload))
    }

    private fun needsNotificationPermission(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
    }

    private fun createReminderNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            reminderNotificationChannelId,
            "蓝心同行主动提醒",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "旅行过程中的主动提醒和情境建议"
        }
        manager.createNotificationChannel(channel)
    }

    private fun deliverReminderNotification(payload: Map<String, String>): Boolean {
        return try {
            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            val launchIntent = (packageManager.getLaunchIntentForPackage(packageName) ?: Intent(this, MainActivity::class.java)).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val notification = NotificationCompat.Builder(this, reminderNotificationChannelId)
                .setSmallIcon(applicationInfo.icon)
                .setContentTitle(payload["title"] ?: "蓝心同行提醒")
                .setContentText(payload["body"] ?: "")
                .setStyle(NotificationCompat.BigTextStyle().bigText(payload["body"] ?: ""))
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true)
                .build()
            manager.notify(nextNotificationId++, notification)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun getCurrentLocation(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            pendingLocationResult = result
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                locationPermissionRequestCode,
            )
            return
        }
        resolveCurrentLocation(result)
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
    }

    private fun resolveCurrentLocation(result: MethodChannel.Result) {
        val manager = getSystemService(LOCATION_SERVICE) as LocationManager
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
        val location = providers
            .filter { provider -> manager.isProviderEnabled(provider) }
            .mapNotNull { provider -> latestLocation(manager, provider) }
            .maxByOrNull { it.time }
        if (location == null) {
            requestFreshLocation(manager, providers, result)
            return
        }
        result.success(locationPayload(location))
    }

    private fun requestFreshLocation(
        manager: LocationManager,
        providers: List<String>,
        result: MethodChannel.Result,
    ) {
        if (pendingLocationListener != null) {
            result.error("location_busy", "Another location request is already running", null)
            return
        }
        val provider = providers.firstOrNull { candidate -> manager.isProviderEnabled(candidate) }
        if (provider == null) {
            result.error("location_unavailable", "No location provider is enabled", null)
            return
        }
        val handler = Handler(Looper.getMainLooper())
        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                clearFreshLocationRequest(manager)
                result.success(locationPayload(location))
            }
        }
        val timeout = Runnable {
            clearFreshLocationRequest(manager)
            result.success(null)
        }
        pendingLocationListener = listener
        pendingLocationTimeout = timeout
        try {
            handler.postDelayed(timeout, 8000)
            manager.requestSingleUpdate(provider, listener, Looper.getMainLooper())
        } catch (_: SecurityException) {
            clearFreshLocationRequest(manager)
            result.error("location_permission_denied", "Location permission was denied", null)
        } catch (_: IllegalArgumentException) {
            clearFreshLocationRequest(manager)
            result.error("location_unavailable", "Location provider is unavailable", null)
        }
    }

    private fun clearFreshLocationRequest(manager: LocationManager) {
        pendingLocationTimeout?.let { Handler(Looper.getMainLooper()).removeCallbacks(it) }
        pendingLocationListener?.let { listener ->
            try {
                manager.removeUpdates(listener)
            } catch (_: SecurityException) {
            } catch (_: IllegalArgumentException) {
            }
        }
        pendingLocationListener = null
        pendingLocationTimeout = null
    }

    private fun latestLocation(manager: LocationManager, provider: String): Location? {
        return try {
            if (!hasLocationPermission()) null else manager.getLastKnownLocation(provider)
        } catch (_: SecurityException) {
            null
        } catch (_: IllegalArgumentException) {
            null
        }
    }

    private fun locationPayload(location: Location): Map<String, Any> {
        return mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "accuracyMeters" to location.accuracy,
            "provider" to (location.provider ?: "unknown"),
        )
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
        if (!hasCameraPermission()) {
            pendingCameraPermissionResult = result
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CAMERA),
                cameraPermissionRequestCode,
            )
            return
        }
        if (!claimPendingResult(result)) return
        val cameraIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        if (cameraIntent.resolveActivity(packageManager) == null) {
            clearPendingWithError("camera_unavailable", "No camera app can handle image capture")
            return
        }
        val outputUri = createCameraOutputUri()
        if (outputUri == null) {
            launchCameraWithoutOutput()
            return
        }
        pendingCameraUri = outputUri
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, outputUri)
            clipData = ClipData.newUri(contentResolver, "Lanxin TravelMate photo", outputUri)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        try {
            startActivityForResult(intent, cameraRequestCode)
        } catch (_: Exception) {
            contentResolver.delete(outputUri, null, null)
            pendingCameraUri = null
            launchCameraWithoutOutput()
        }
    }

    private fun launchCameraWithoutOutput() {
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        if (intent.resolveActivity(packageManager) == null) {
            clearPendingWithError("camera_unavailable", "No camera app can handle image capture")
            return
        }
        try {
            startActivityForResult(intent, cameraRequestCode)
        } catch (_: Exception) {
            clearPendingWithError("camera_launch_failed", "Camera app failed to start")
        }
    }

    private fun hasCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
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
            cameraRequestCode -> handleCameraResult(resultCode, data)
            speechRequestCode -> handleSpeechResult(resultCode, data)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            cameraPermissionRequestCode -> {
                val result = pendingCameraPermissionResult ?: return
                pendingCameraPermissionResult = null
                if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
                    launchCamera(result)
                } else {
                    result.error("camera_permission_denied", "Camera permission was denied", null)
                }
            }
            locationPermissionRequestCode -> {
                val result = pendingLocationResult ?: return
                pendingLocationResult = null
                if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
                    resolveCurrentLocation(result)
                } else {
                    result.error("location_permission_denied", "Location permission was denied", null)
                }
            }
            recordAudioPermissionRequestCode -> {
                val result = pendingVoiceResult ?: return
                pendingVoiceResult = null
                if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
                    launchSpeechRecognizer(result)
                } else {
                    result.error("microphone_permission_denied", "Microphone permission was denied", null)
                }
            }
            notificationPermissionRequestCode -> {
                val result = pendingNotificationResult ?: return
                val payload = pendingNotificationPayload
                pendingNotificationResult = null
                pendingNotificationPayload = null
                if (grantResults.any { it == PackageManager.PERMISSION_GRANTED } && payload != null) {
                    result.success(deliverReminderNotification(payload))
                } else {
                    result.error("notification_permission_denied", "Notification permission was denied", null)
                }
            }
        }
    }

    private fun handleSpeechResult(resultCode: Int, data: Intent?) {
        val result = pendingVoiceResult ?: return
        pendingVoiceResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return
        }
        val matches = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
        result.success(matches?.firstOrNull())
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

    private fun handleCameraResult(resultCode: Int, data: Intent?) {
        val result = pendingResult ?: return
        val outputUri = pendingCameraUri
        pendingResult = null
        pendingCameraUri = null
        if (resultCode != Activity.RESULT_OK) {
            outputUri?.let { contentResolver.delete(it, null, null) }
            result.success(null)
            return
        }
        if (outputUri != null) {
            result.success(photoPayload(outputUri, "camera"))
            return
        }
        val thumbnail = data?.extras?.get("data") as? Bitmap
        if (thumbnail == null) {
            result.success(null)
            return
        }
        val savedUri = saveCameraThumbnail(thumbnail)
        if (savedUri == null) {
            result.error("camera_output_unavailable", "Could not save camera thumbnail", null)
            return
        }
        result.success(photoPayload(savedUri, "camera"))
    }

    private fun saveCameraThumbnail(bitmap: Bitmap): Uri? {
        val uri = createCameraOutputUri() ?: return null
        return try {
            contentResolver.openOutputStream(uri)?.use { stream ->
                if (!bitmap.compress(Bitmap.CompressFormat.JPEG, 92, stream)) {
                    contentResolver.delete(uri, null, null)
                    return null
                }
            } ?: run {
                contentResolver.delete(uri, null, null)
                return null
            }
            uri
        } catch (_: Exception) {
            contentResolver.delete(uri, null, null)
            null
        }
    }

    private fun photoPayload(uri: Uri, source: String): Map<String, Any> {
        val payload = mutableMapOf<String, Any>(
            "localUri" to uri.toString(),
            "filename" to displayName(uri),
            "mimeType" to (contentResolver.getType(uri) ?: "image/jpeg"),
            "source" to source,
        )
        previewBytes(uri)?.let { payload["previewBytes"] = it }
        return payload
    }

    private fun previewBytes(uri: Uri): ByteArray? {
        return try {
            val options = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            contentResolver.openInputStream(uri)?.use { stream ->
                BitmapFactory.decodeStream(stream, null, options)
            }
            val longestSide = maxOf(options.outWidth, options.outHeight)
            val sampleSize = when {
                longestSide > 2400 -> 8
                longestSide > 1200 -> 4
                longestSide > 600 -> 2
                else -> 1
            }
            val decodeOptions = BitmapFactory.Options().apply {
                inSampleSize = sampleSize
            }
            val bitmap = contentResolver.openInputStream(uri)?.use { stream ->
                BitmapFactory.decodeStream(stream, null, decodeOptions)
            } ?: return null
            ByteArrayOutputStream().use { output ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 78, output)
                bitmap.recycle()
                output.toByteArray()
            }
        } catch (_: Exception) {
            null
        }
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

    override fun onDestroy() {
        textToSpeech?.shutdown()
        textToSpeech = null
        super.onDestroy()
    }
}
