package com.cinevagroup.cinevastream

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.Rational
import android.view.WindowManager
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.core.content.FileProvider
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.cinevagroup.cinevastream/muxer"
    private val TAG = "CinevaMuxer"
    private var isPlayerActiveForPip: Boolean = false
    private var pipMethodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }

        // Request POST_NOTIFICATIONS permission on Android 13+ (API 33+) so background notifications can appear.
        // Specifically exclude Android TV devices as TV Leanback does not support mobile runtime notification dialogs.
        if (!isTelevisionDevice() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) !=
                    android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1002)
                }
            } catch (t: Throwable) {
                Log.w(TAG, "Non-fatal: Failed to request notification permission: ${t.message}")
            }
        }

        // On Android TV, TV boxes (720p, 1080p, 4K), or Tablets (smallestScreenWidthDp >= 600),
        // lock to landscape immediately upon launch
        if (isTelevisionDevice() || isTabletDevice()) {
            try {
                requestedOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
            } catch (t: Throwable) {
                Log.w(TAG, "Non-fatal: Failed to set landscape orientation: ${t.message}")
            }
        }

        try {
            UpdateCheckWorker.schedule(applicationContext)
        } catch (t: Throwable) {
            Log.w(TAG, "Non-fatal: Failed to schedule update check in onCreate: ${t.message}")
        }
    }

    private fun isTelevisionDevice(): Boolean {
        try {
            // 1. UiModeManager TV mode
            val uiModeManager = getSystemService(android.content.Context.UI_MODE_SERVICE) as? android.app.UiModeManager
            if (uiModeManager?.currentModeType == android.content.res.Configuration.UI_MODE_TYPE_TELEVISION) {
                return true
            }

            // 2. Leanback and TV system features
            val pm = packageManager
            if (pm.hasSystemFeature(android.content.pm.PackageManager.FEATURE_LEANBACK) ||
                pm.hasSystemFeature("android.hardware.type.television") ||
                pm.hasSystemFeature("android.software.leanback_only") ||
                pm.hasSystemFeature("amazon.hardware.fire_tv")) {
                return true
            }

            // 3. Android TV / STB without touchscreen and without telephony
            val hasTouch = pm.hasSystemFeature(android.content.pm.PackageManager.FEATURE_TOUCHSCREEN)
            val hasTelephony = pm.hasSystemFeature(android.content.pm.PackageManager.FEATURE_TELEPHONY)
            if (!hasTouch && !hasTelephony) {
                return true
            }

            // 4. Non-touch device in landscape orientation (e.g. 720p Android TV emulator or box)
            val config = resources.configuration
            if (!hasTouch && config.orientation == android.content.res.Configuration.ORIENTATION_LANDSCAPE) {
                return true
            }
        } catch (t: Throwable) {
            Log.w(TAG, "Error detecting TV device: ${t.message}")
        }
        return false
    }

    private fun isTabletDevice(): Boolean {
        return try {
            !isTelevisionDevice() && resources.configuration.smallestScreenWidthDp >= 600
        } catch (t: Throwable) {
            false
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isPlayerActiveForPip && Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            tryEnterPipMode()
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        try {
            pipMethodChannel?.invokeMethod("onPipChanged", isInPictureInPictureMode)
        } catch (t: Throwable) {
            Log.w(TAG, "Failed to notify Flutter of PiP change: ${t.message}")
        }
    }

    private fun tryEnterPipMode(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !isTelevisionDevice()) {
            try {
                if (packageManager.hasSystemFeature(android.content.pm.PackageManager.FEATURE_PICTURE_IN_PICTURE)) {
                    val params = PictureInPictureParams.Builder()
                        .setAspectRatio(Rational(16, 9))
                        .build()
                    return enterPictureInPictureMode(params)
                }
            } catch (t: Throwable) {
                Log.w(TAG, "enterPictureInPictureMode failed: ${t.message}")
            }
        }
        return false
    }

    override fun onStop() {
        super.onStop()
        try {
            // Re-arm background periodic & fast one-time checks when the app is backgrounded or closed
            UpdateCheckWorker.schedule(applicationContext)
        } catch (t: Throwable) {
            Log.w(TAG, "Non-fatal: Failed to schedule update check in onStop: ${t.message}")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val deviceChannel = "com.cinevagroup.cinevastream/device"
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "isTelevision" -> {
                    result.success(isTelevisionDevice())
                }
                "isTablet" -> {
                    result.success(isTabletDevice())
                }
                else -> result.notImplemented()
            }
        }

        val pipChannel = "com.cinevagroup.cinevastream/pip"
        pipMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, pipChannel)
        pipMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPipSupported" -> {
                    val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                        packageManager.hasSystemFeature(android.content.pm.PackageManager.FEATURE_PICTURE_IN_PICTURE) &&
                        !isTelevisionDevice()
                    result.success(supported)
                }
                "setAutoPipEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    isPlayerActiveForPip = enabled
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !isTelevisionDevice()) {
                        try {
                            val params = PictureInPictureParams.Builder()
                                .setAspectRatio(Rational(16, 9))
                                .setAutoEnterEnabled(enabled)
                                .build()
                            setPictureInPictureParams(params)
                        } catch (t: Throwable) {
                            Log.w(TAG, "Failed to set auto PiP params: ${t.message}")
                        }
                    }
                    result.success(true)
                }
                "enterPip" -> {
                    val entered = tryEnterPipMode()
                    result.success(entered)
                }
                else -> result.notImplemented()
            }
        }

        val brightnessChannel = "com.cinevagroup.cinevastream/brightness"
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, brightnessChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "setBrightness" -> {
                    val brightness = (call.argument<Double>("brightness") ?: 1.0).toFloat()
                    val lp = window.attributes
                    lp.screenBrightness = brightness.coerceIn(0.01f, 1.0f)
                    window.attributes = lp
                    result.success(null)
                }
                "resetBrightness" -> {
                    val lp = window.attributes
                    lp.screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                    window.attributes = lp
                    result.success(null)
                }
                "getBrightness" -> {
                    val current = window.attributes.screenBrightness
                    result.success(if (current < 0) null else current.toDouble())
                }
                else -> result.notImplemented()
            }
        }

        val shareChannel = "com.cinevagroup.cinevastream/share"
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareImageWithText" -> {
                    val filePath = call.argument<String>("filePath")
                    val text = call.argument<String>("text") ?: ""
                    val title = call.argument<String>("title") ?: "Share Cineva Card"
                    if (filePath == null) {
                        result.error("INVALID_ARGS", "filePath is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "File does not exist at $filePath", null)
                            return@setMethodCallHandler
                        }
                        val uri = FileProvider.getUriForFile(
                            this,
                            "$packageName.fileprovider",
                            file
                        )
                        val mimeType = if (
                            file.name.endsWith(".jpg", ignoreCase = true) ||
                            file.name.endsWith(".jpeg", ignoreCase = true)
                        ) {
                            "image/jpeg"
                        } else {
                            "image/png"
                        }
                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                            type = mimeType
                            putExtra(Intent.EXTRA_STREAM, uri)
                            putExtra(Intent.EXTRA_TEXT, text)
                            clipData = android.content.ClipData.newRawUri("", uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        val chooser = Intent.createChooser(shareIntent, title).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to share image with text: ${e.message}", e)
                        result.error("SHARE_ERROR", e.message, null)
                    }
                }
                "shareText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val title = call.argument<String>("title") ?: "Share via Cineva"
                    try {
                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                        }
                        val chooser = Intent.createChooser(shareIntent, title).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to share text: ${e.message}", e)
                        result.error("SHARE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        val updaterChannel = "com.cinevagroup.cinevastream/updater"
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, updaterChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "canRequestPackageInstalls" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }
                "openInstallSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to open install settings: ${e.message}", e)
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("INVALID_ARGS", "filePath is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "APK file does not exist at $filePath", null)
                            return@setMethodCallHandler
                        }

                        val uri = FileProvider.getUriForFile(
                            this,
                            "$packageName.fileprovider",
                            file
                        )

                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }

                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to launch package installer: ${e.message}", e)
                        result.error("INSTALL_ERROR", e.message, null)
                    }
                }
                "scheduleBackgroundUpdateCheck" -> {
                    try {
                        UpdateCheckWorker.schedule(applicationContext)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to schedule background update: ${e.message}", e)
                        result.error("SCHEDULE_ERROR", e.message, null)
                    }
                }
                "checkUpdateNow" -> {
                    try {
                        UpdateCheckWorker.checkNow(applicationContext)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to trigger update check now: ${e.message}", e)
                        result.error("TRIGGER_ERROR", e.message, null)
                    }
                }
                "showUpdateNotification" -> {
                    try {
                        val version = call.argument<String>("version") ?: ""
                        val title = call.argument<String>("title") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        val shown = UpdateCheckWorker.showNotification(
                            context = applicationContext,
                            version = version,
                            title = title,
                            body = body
                        )
                        result.success(shown)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to show update notification: ${e.message}", e)
                        result.error("NOTIFICATION_ERROR", e.message, null)
                    }
                }
                "isUpdateNotified" -> {
                    val version = call.argument<String>("version") ?: ""
                    val isNotified = UpdateCheckWorker.isVersionNotified(applicationContext, version)
                    result.success(isNotified)
                }
                "hasNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                                android.content.pm.PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    } else {
                        val manager = androidx.core.app.NotificationManagerCompat.from(this)
                        result.success(manager.areNotificationsEnabled())
                    }
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1002)
                    }
                    result.success(true)
                }
                "getSupportedAbis" -> {
                    val abis = if (Build.SUPPORTED_ABIS.isNotEmpty()) {
                        Build.SUPPORTED_ABIS.toList()
                    } else {
                        @Suppress("DEPRECATION")
                        listOfNotNull(Build.CPU_ABI, Build.CPU_ABI2)
                    }
                    result.success(abis)
                }
                "isPackageInstalled" -> {
                    val targetPackage = call.argument<String>("packageName") ?: ""
                    if (targetPackage.isEmpty()) {
                        result.success(false)
                    } else {
                        try {
                            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                packageManager.getPackageInfo(
                                    targetPackage,
                                    android.content.pm.PackageManager.PackageInfoFlags.of(0)
                                )
                            } else {
                                @Suppress("DEPRECATION")
                                packageManager.getPackageInfo(targetPackage, 0)
                            }
                            result.success(info != null)
                        } catch (e: android.content.pm.PackageManager.NameNotFoundException) {
                            result.success(false)
                        } catch (t: Throwable) {
                            result.success(false)
                        }
                    }
                }
                "openPackage" -> {
                    val targetPackage = call.argument<String>("packageName") ?: ""
                    if (targetPackage.isEmpty()) {
                        result.success(false)
                    } else {
                        try {
                            val launchIntent = packageManager.getLaunchIntentForPackage(targetPackage)
                            if (launchIntent != null) {
                                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(launchIntent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (t: Throwable) {
                            Log.e(TAG, "Failed to open package $targetPackage: ${t.message}")
                            result.success(false)
                        }
                    }
                }
                "uninstallPackage" -> {
                    val targetPackage = call.argument<String>("packageName") ?: ""
                    if (targetPackage.isEmpty()) {
                        result.success(false)
                    } else {
                        try {
                            val intent = Intent(Intent.ACTION_DELETE).apply {
                                data = Uri.fromParts("package", targetPackage, null)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (t: Throwable) {
                            try {
                                @Suppress("DEPRECATION")
                                val fallbackIntent = Intent(Intent.ACTION_UNINSTALL_PACKAGE).apply {
                                    data = Uri.parse("package:$targetPackage")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(fallbackIntent)
                                result.success(true)
                            } catch (e: Throwable) {
                                Log.e(TAG, "Failed to launch uninstall intent: ${e.message}", e)
                                result.error("UNINSTALL_ERROR", e.message, null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        val muxerMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        muxerMethodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "muxToMp4" -> {
                    val videoPath = call.argument<String>("videoPath")
                    val audioPath = call.argument<String>("audioPath")
                    val outputPath = call.argument<String>("outputPath")
                    val expectedDurationUs = call.argument<Number>("expectedDurationUs")?.toLong()

                    if (videoPath == null || outputPath == null) {
                        result.error("INVALID_ARGS", "videoPath and outputPath are required", null)
                        return@setMethodCallHandler
                    }

                    thread {
                        var success = false
                        var lastError: String? = null
                        for (monotonic in booleanArrayOf(false, true)) {
                            try {
                                success = muxTsToMp4(
                                    videoPath = videoPath,
                                    audioPath = audioPath,
                                    outputPath = outputPath,
                                    expectedDurationUs = expectedDurationUs,
                                    monotonicPts = monotonic,
                                    onProgress = { progress ->
                                        runOnUiThread {
                                            try {
                                                muxerMethodChannel.invokeMethod(
                                                    "onMuxProgress",
                                                    mapOf("progress" to progress)
                                                )
                                            } catch (_: Throwable) {}
                                        }
                                    }
                                )
                            } catch (e: Throwable) {
                                Log.w(TAG, "Mux attempt (monotonic=$monotonic) failed: ${e.message}", e)
                                lastError = e.message
                                success = false
                            }
                            if (success) break
                        }
                        runOnUiThread {
                            if (success) {
                                result.success(true)
                            } else {
                                result.error("MUX_FAILED", lastError ?: "MediaMuxer output failed validation", null)
                            }
                        }
                    }
                }
                "probeMedia" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("INVALID_ARGS", "path is required", null)
                        return@setMethodCallHandler
                    }
                    thread {
                        val info = probeMedia(path)
                        runOnUiThread {
                            if (info != null) {
                                result.success(info)
                            } else {
                                result.error("PROBE_FAILED", "Unable to parse media file", null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Opens [path] with MediaExtractor and reports duration and track kinds, or null if unreadable. */
    private fun probeMedia(path: String): Map<String, Any>? {
        val file = File(path)
        if (!file.exists() || file.length() < 1000) return null
        val extractor = MediaExtractor()
        return try {
            extractor.setDataSource(path)
            var hasVideo = false
            var hasAudio = false
            var durationUs = 0L
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("video/")) hasVideo = true
                if (mime.startsWith("audio/")) hasAudio = true
                if (format.containsKey(MediaFormat.KEY_DURATION)) {
                    val d = format.getLong(MediaFormat.KEY_DURATION)
                    if (d > durationUs) durationUs = d
                }
            }
            mapOf(
                "durationMs" to (durationUs / 1000L),
                "hasVideo" to hasVideo,
                "hasAudio" to hasAudio,
                "fileSizeBytes" to file.length()
            )
        } catch (e: Exception) {
            Log.w(TAG, "probeMedia exception for $path: ${e.message}")
            null
        } finally {
            try { extractor.release() } catch (_: Exception) {}
        }
    }

    private fun muxTsToMp4(
        videoPath: String,
        audioPath: String?,
        outputPath: String,
        expectedDurationUs: Long?,
        monotonicPts: Boolean,
        onProgress: ((Double) -> Unit)? = null
    ): Boolean {
        val outputFile = File(outputPath)
        if (outputFile.exists()) outputFile.delete()
        outputFile.parentFile?.mkdirs()

        var videoExtractor: MediaExtractor? = null
        var separateAudioExtractor: MediaExtractor? = null
        var muxer: MediaMuxer? = null
        var muxerStarted = false
        var ok = false

        try {
            videoExtractor = MediaExtractor()
            videoExtractor.setDataSource(videoPath)

            var videoTrackIndex = -1
            var videoFormat: MediaFormat? = null
            var embeddedAudioTrackIndex = -1
            var embeddedAudioFormat: MediaFormat? = null

            for (i in 0 until videoExtractor.trackCount) {
                val format = videoExtractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("video/") && videoTrackIndex == -1) {
                    videoTrackIndex = i
                    videoFormat = format
                } else if (mime.startsWith("audio/") && embeddedAudioTrackIndex == -1) {
                    embeddedAudioTrackIndex = i
                    embeddedAudioFormat = format
                }
            }

            if (videoTrackIndex == -1 || videoFormat == null) {
                Log.w(TAG, "No video track found in $videoPath")
                return false
            }

            var separateAudioTrackIndex = -1
            var audioFormat: MediaFormat? = null

            if (audioPath != null && File(audioPath).exists()) {
                val ext = MediaExtractor()
                try {
                    ext.setDataSource(audioPath)
                    for (i in 0 until ext.trackCount) {
                        val format = ext.getTrackFormat(i)
                        val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                        if (mime.startsWith("audio/")) {
                            separateAudioTrackIndex = i
                            audioFormat = format
                            break
                        }
                    }
                    if (audioFormat != null) separateAudioExtractor = ext else ext.release()
                } catch (e: Exception) {
                    Log.w(TAG, "Separate audio unreadable: ${e.message}")
                    ext.release()
                }
            }

            // When audio is embedded inside videoPath, select BOTH tracks on the single videoExtractor
            // so the 1.5 GB MPEG-TS file is demuxed in a single sequential pass instead of read twice!
            val useEmbeddedAudio = separateAudioExtractor == null &&
                embeddedAudioTrackIndex != -1 &&
                embeddedAudioFormat != null
            if (useEmbeddedAudio) {
                audioFormat = embeddedAudioFormat
            }

            // Ensure CSD for video if missing in MediaFormat from MPEG-TS
            ensureVideoCsd(videoExtractor, videoTrackIndex, videoFormat)

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val muxerVideoTrack = muxer.addTrack(videoFormat)
            var muxerAudioTrack = -1
            if (audioFormat != null && (separateAudioExtractor != null || useEmbeddedAudio)) {
                ensureAudioCsd(audioFormat)
                muxerAudioTrack = muxer.addTrack(audioFormat)
            }

            muxer.start()
            muxerStarted = true

            videoExtractor.selectTrack(videoTrackIndex)
            if (useEmbeddedAudio) {
                videoExtractor.selectTrack(embeddedAudioTrackIndex)
            }
            separateAudioExtractor?.selectTrack(separateAudioTrackIndex)

            val firstPrimaryPts = videoExtractor.sampleTime
            val firstSepAudioPts = separateAudioExtractor?.sampleTime ?: -1L
            val candidates = listOf(firstPrimaryPts, firstSepAudioPts).filter { it >= 0L }
            val basePts = candidates.minOrNull() ?: 0L

            // 2 MB cache-friendly direct buffer (plenty for compressed 1080p/4K H.264/HEVC frames)
            val buffer = ByteBuffer.allocateDirect(2 * 1024 * 1024)
            val bufferInfo = MediaCodec.BufferInfo()

            var hasPrimary = true
            var hasSepAudio = separateAudioExtractor != null

            val vFrameRate = if (videoFormat.containsKey(MediaFormat.KEY_FRAME_RATE)) {
                val r = videoFormat.getInteger(MediaFormat.KEY_FRAME_RATE)
                if (r > 0) r else 24
            } else 24
            val videoStepUs = 1000000L / vFrameRate

            var maxVideoPts = -1L
            var lastWrittenVideoPts = -1L
            var prevRawVideoPts = -1L
            var videoPtsOffset = 0L
            var videoSamples = 0

            var lastAudioPts = -1L
            var prevRawAudioPts = -1L
            var audioPtsOffset = 0L

            var lastProgressEmitMs = 0L
            val totalInputBytes = (File(videoPath).length() + (if (audioPath != null) File(audioPath).length() else 0L)).coerceAtLeast(1L)
            var totalBytesWritten = 0L

            fun emitProgressIfNeeded() {
                if (onProgress == null) return
                val now = System.currentTimeMillis()
                if (now - lastProgressEmitMs < 200L) return
                lastProgressEmitMs = now
                val ratio = if (expectedDurationUs != null && expectedDurationUs > 0L && maxVideoPts > 0L) {
                    (maxVideoPts.toDouble() / expectedDurationUs.toDouble()).coerceIn(0.0, 0.99)
                } else {
                    (totalBytesWritten.toDouble() / totalInputBytes.toDouble()).coerceIn(0.0, 0.99)
                }
                onProgress.invoke(ratio)
            }

            fun writeAudioSample(ext: MediaExtractor) {
                val sampleSize = ext.readSampleData(buffer, 0)
                if (sampleSize <= 0) return
                val rawPts = ext.sampleTime
                if (prevRawAudioPts != -1L &&
                    (rawPts < prevRawAudioPts - 200000L || rawPts > prevRawAudioPts + 15000000L)
                ) {
                    // Audio segment discontinuity/reset detected
                    audioPtsOffset += (lastAudioPts - (rawPts - basePts + audioPtsOffset) + 21333L)
                }
                prevRawAudioPts = rawPts

                var pts = (rawPts - basePts + audioPtsOffset).coerceAtLeast(0L)
                if (pts <= lastAudioPts) {
                    pts = lastAudioPts + 1000L
                }
                lastAudioPts = pts

                bufferInfo.offset = 0
                bufferInfo.size = sampleSize
                bufferInfo.presentationTimeUs = pts
                bufferInfo.flags = if ((ext.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC) != 0) {
                    MediaCodec.BUFFER_FLAG_KEY_FRAME
                } else {
                    0
                }
                muxer.writeSampleData(muxerAudioTrack, buffer, bufferInfo)
                totalBytesWritten += sampleSize
            }

            fun writeVideoSample(ext: MediaExtractor) {
                val sampleSize = ext.readSampleData(buffer, 0)
                if (sampleSize <= 0) return
                val rawPts = ext.sampleTime
                val isSyncFrame = (ext.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC) != 0

                if (prevRawVideoPts != -1L) {
                    val delta = rawPts - prevRawVideoPts
                    val candidatePts = rawPts - basePts + videoPtsOffset
                    // Detect segment timestamp reset/discontinuity:
                    // 1) Large backward jump (> 300ms) or huge forward jump (> 15s), OR
                    // 2) An IDR keyframe (new GOP) whose PTS is <= maxVideoPts from the previous GOP.
                    if (delta < -300000L || delta > 15000000L || (isSyncFrame && maxVideoPts >= 0L && candidatePts <= maxVideoPts)) {
                        videoPtsOffset += (maxVideoPts - candidatePts + videoStepUs)
                    }
                }
                prevRawVideoPts = rawPts

                var pts = (rawPts - basePts + videoPtsOffset).coerceAtLeast(0L)
                if (monotonicPts && pts <= maxVideoPts) {
                    pts = maxVideoPts + 1000L
                } else if (pts == lastWrittenVideoPts) {
                    // Prevent duplicate PTS rejection in MPEG4Writer while keeping B-frame order
                    pts += 100L
                }
                lastWrittenVideoPts = pts
                if (pts > maxVideoPts) maxVideoPts = pts

                bufferInfo.offset = 0
                bufferInfo.size = sampleSize
                bufferInfo.presentationTimeUs = pts
                bufferInfo.flags = if (isSyncFrame) {
                    MediaCodec.BUFFER_FLAG_KEY_FRAME
                } else {
                    0
                }
                muxer.writeSampleData(muxerVideoTrack, buffer, bufferInfo)
                videoSamples++
                totalBytesWritten += sampleSize
            }

            while (hasPrimary || hasSepAudio) {
                val pTime = if (hasPrimary) videoExtractor.sampleTime else Long.MAX_VALUE
                val aTime = if (hasSepAudio && separateAudioExtractor != null) separateAudioExtractor.sampleTime else Long.MAX_VALUE

                if (pTime < 0L) hasPrimary = false
                if (aTime < 0L) hasSepAudio = false
                if (!hasPrimary && !hasSepAudio) break

                if (hasPrimary && (!hasSepAudio || pTime <= aTime)) {
                    val trackIdx = videoExtractor.sampleTrackIndex
                    if (useEmbeddedAudio && trackIdx == embeddedAudioTrackIndex && muxerAudioTrack != -1) {
                        writeAudioSample(videoExtractor)
                    } else if (trackIdx == videoTrackIndex) {
                        writeVideoSample(videoExtractor)
                    }
                    hasPrimary = videoExtractor.advance()
                    emitProgressIfNeeded()
                } else if (hasSepAudio && separateAudioExtractor != null) {
                    writeAudioSample(separateAudioExtractor)
                    hasSepAudio = separateAudioExtractor.advance()
                    emitProgressIfNeeded()
                }
            }

            if (videoSamples == 0) {
                Log.w(TAG, "No video samples were written")
                return false
            }

            // Do NOT swallow stop() failures: a failed stop means no valid moov atom.
            muxer.stop()
            muxerStarted = false
            ok = true
            onProgress?.invoke(1.0)
        } finally {
            if (muxerStarted) {
                try { muxer?.stop() } catch (_: Exception) {}
            }
            try { muxer?.release() } catch (_: Exception) {}
            try { videoExtractor?.release() } catch (_: Exception) {}
            try { separateAudioExtractor?.release() } catch (_: Exception) {}
            if (!ok) {
                try { outputFile.delete() } catch (_: Exception) {}
            }
        }

        // Validate the produced MP4 by re-opening it once natively.
        if (!outputFile.exists() || outputFile.length() <= 50000) {
            Log.w(TAG, "Validation failed: output file missing or smaller than 50KB (${outputFile.length()} bytes)")
            try { outputFile.delete() } catch (_: Exception) {}
            return false
        }
        val info = probeMedia(outputPath)
        val hasVideoTrack = (info?.get("hasVideo") as? Boolean) ?: false
        val durationMs = (info?.get("durationMs") as? Long) ?: 0L
        if (!hasVideoTrack || durationMs <= 0L) {
            Log.w(TAG, "Validation failed: invalid video track or duration ($durationMs ms) in output MP4")
            try { outputFile.delete() } catch (_: Exception) {}
            return false
        }
        if (expectedDurationUs != null && expectedDurationUs > 0L) {
            val actualUs = durationMs * 1000L
            if (actualUs < (expectedDurationUs * 0.9).toLong()) {
                Log.w(TAG, "Validation failed: actual duration ${actualUs}us < 90% of expected ${expectedDurationUs}us")
                try { outputFile.delete() } catch (_: Exception) {}
                return false
            }
        }
        Log.i(TAG, "Mux validation passed! Size: ${outputFile.length()} bytes, duration: ${durationMs}ms, hasVideo: $hasVideoTrack")
        return true
    }

    private fun ensureVideoCsd(extractor: MediaExtractor, trackIndex: Int, format: MediaFormat) {
        if (!format.containsKey("csd-0") || format.getByteBuffer("csd-0") == null ||
            !format.containsKey("csd-1") || format.getByteBuffer("csd-1") == null) {
            try {
                extractor.selectTrack(trackIndex)
                val testBuf = ByteBuffer.allocateDirect(1024 * 1024)
                var spsFound = format.containsKey("csd-0") && format.getByteBuffer("csd-0") != null
                var ppsFound = format.containsKey("csd-1") && format.getByteBuffer("csd-1") != null

                var samplesChecked = 0
                while ((!spsFound || !ppsFound) && samplesChecked < 100) {
                    val size = extractor.readSampleData(testBuf, 0)
                    if (size <= 0) break

                    val bytes = ByteArray(size)
                    testBuf.get(bytes)
                    testBuf.clear()

                    var i = 0
                    while (i < bytes.size - 4) {
                        val is4Byte = bytes[i] == 0.toByte() && bytes[i + 1] == 0.toByte() &&
                                bytes[i + 2] == 0.toByte() && bytes[i + 3] == 1.toByte()
                        val is3Byte = bytes[i] == 0.toByte() && bytes[i + 1] == 0.toByte() &&
                                bytes[i + 2] == 1.toByte()

                        if (is4Byte || is3Byte) {
                            val startCodeLen = if (is4Byte) 4 else 3
                            val nalType = (bytes[i + startCodeLen].toInt() and 0x1F)

                            var nextStart = bytes.size
                            for (j in (i + startCodeLen) until bytes.size - 3) {
                                if ((bytes[j] == 0.toByte() && bytes[j + 1] == 0.toByte() && bytes[j + 2] == 1.toByte()) ||
                                    (bytes[j] == 0.toByte() && bytes[j + 1] == 0.toByte() && bytes[j + 2] == 0.toByte() && bytes[j + 3] == 1.toByte())) {
                                    nextStart = j
                                    break
                                }
                            }

                            if (nalType == 7 && !spsFound) {
                                val sps = bytes.copyOfRange(i, nextStart)
                                format.setByteBuffer("csd-0", ByteBuffer.wrap(sps))
                                spsFound = true
                            } else if (nalType == 8 && !ppsFound) {
                                val pps = bytes.copyOfRange(i, nextStart)
                                format.setByteBuffer("csd-1", ByteBuffer.wrap(pps))
                                ppsFound = true
                            }
                            i = nextStart
                        } else {
                            i++
                        }
                    }
                    samplesChecked++
                    extractor.advance()
                }
                extractor.seekTo(0, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
            } catch (e: Exception) {}
        }
    }

    private fun ensureAudioCsd(format: MediaFormat) {
        if (!format.containsKey("csd-0") || format.getByteBuffer("csd-0") == null) {
            try {
                val sampleRate = if (format.containsKey(MediaFormat.KEY_SAMPLE_RATE)) {
                    format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                } else 44100
                val channels = if (format.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) {
                    format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                } else 2

                val freqIdx = when (sampleRate) {
                    96000 -> 0
                    88200 -> 1
                    64000 -> 2
                    48000 -> 3
                    44100 -> 4
                    32000 -> 5
                    24000 -> 6
                    22050 -> 7
                    16000 -> 8
                    12000 -> 9
                    11025 -> 10
                    8000 -> 11
                    7350 -> 12
                    else -> 4
                }
                val asc = ByteArray(2)
                asc[0] = ((2 shl 3) or (freqIdx shr 1)).toByte()
                asc[1] = (((freqIdx and 1) shl 7) or (channels shl 3)).toByte()
                format.setByteBuffer("csd-0", ByteBuffer.wrap(asc))
            } catch (e: Exception) {}
        }
    }
}
