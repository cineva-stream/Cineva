package com.primadev.cineva

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.primadev.cineva/muxer"
    private val TAG = "CinevaMuxer"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }

        // Request POST_NOTIFICATIONS permission on Android 13+ (API 33+) so background notifications can appear
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) !=
                android.content.pm.PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1002)
            }
        }

        try {
            UpdateCheckWorker.schedule(applicationContext)
        } catch (t: Throwable) {
            Log.w(TAG, "Non-fatal: Failed to schedule update check in onCreate: ${t.message}")
        }
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

        val brightnessChannel = "com.primadev.cineva/brightness"
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

        val updaterChannel = "com.primadev.cineva/updater"
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
                        UpdateCheckWorker.showNotification(
                            context = applicationContext,
                            version = version,
                            title = title,
                            body = body
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to show update notification: ${e.message}", e)
                        result.error("NOTIFICATION_ERROR", e.message, null)
                    }
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
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                        // Attempt 1: preserve true presentation timestamps (correct for B-frames).
                        // Attempt 2: force monotonic timestamps in case MPEG4Writer rejects
                        // out-of-order frames.
                        var success = false
                        var lastError: String? = null
                        for (monotonic in booleanArrayOf(false, true)) {
                            try {
                                success = muxTsToMp4(
                                    videoPath, audioPath, outputPath, expectedDurationUs, monotonic
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
            if (file.exists() && file.length() > 50000) {
                // If the file exists and is substantial, treat it as playable rather than deleting it
                mapOf(
                    "durationMs" to 0L,
                    "hasVideo" to true,
                    "hasAudio" to true,
                    "fileSizeBytes" to file.length()
                )
            } else {
                null
            }
        } finally {
            try { extractor.release() } catch (_: Exception) {}
        }
    }

    private fun muxTsToMp4(
        videoPath: String,
        audioPath: String?,
        outputPath: String,
        expectedDurationUs: Long?,
        monotonicPts: Boolean
    ): Boolean {
        val outputFile = File(outputPath)
        if (outputFile.exists()) outputFile.delete()
        outputFile.parentFile?.mkdirs()

        var videoExtractor: MediaExtractor? = null
        var audioExtractor: MediaExtractor? = null
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

            var audioTrackIndex = -1
            var audioFormat: MediaFormat? = null

            if (audioPath != null && File(audioPath).exists()) {
                val ext = MediaExtractor()
                try {
                    ext.setDataSource(audioPath)
                    for (i in 0 until ext.trackCount) {
                        val format = ext.getTrackFormat(i)
                        val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                        if (mime.startsWith("audio/")) {
                            audioTrackIndex = i
                            audioFormat = format
                            break
                        }
                    }
                    if (audioFormat != null) audioExtractor = ext else ext.release()
                } catch (e: Exception) {
                    Log.w(TAG, "Separate audio unreadable: ${e.message}")
                    ext.release()
                }
            }

            // Audio muxed inside the video TS: use a dedicated extractor so video and
            // audio samples are never read from the same cursor.
            if (audioExtractor == null && embeddedAudioTrackIndex != -1 && embeddedAudioFormat != null) {
                val ext = MediaExtractor()
                ext.setDataSource(videoPath)
                audioExtractor = ext
                audioTrackIndex = embeddedAudioTrackIndex
                audioFormat = embeddedAudioFormat
            }

            // Ensure CSD for video if missing in MediaFormat from MPEG-TS
            ensureVideoCsd(videoExtractor, videoTrackIndex, videoFormat)

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val muxerVideoTrack = muxer.addTrack(videoFormat)
            var muxerAudioTrack = -1
            if (audioExtractor != null && audioFormat != null) {
                ensureAudioCsd(audioFormat)
                muxerAudioTrack = muxer.addTrack(audioFormat)
            }

            muxer.start()
            muxerStarted = true

            videoExtractor.selectTrack(videoTrackIndex)
            audioExtractor?.selectTrack(audioTrackIndex)

            // Normalise timestamps so the MP4 starts at 0 (TS PTS usually starts at ~1.4s or 10s).
            val firstVideoPts = videoExtractor.sampleTime
            val firstAudioPts = audioExtractor?.sampleTime ?: -1L
            val candidates = listOf(firstVideoPts, firstAudioPts).filter { it >= 0L }
            val basePts = candidates.minOrNull() ?: 0L

            val buffer = ByteBuffer.allocateDirect(8 * 1024 * 1024)
            val bufferInfo = MediaCodec.BufferInfo()

            var hasVideo = true
            var hasAudio = audioExtractor != null

            val vFrameRate = if (videoFormat.containsKey(MediaFormat.KEY_FRAME_RATE)) {
                val r = videoFormat.getInteger(MediaFormat.KEY_FRAME_RATE)
                if (r > 0) r else 24
            } else 24
            val videoStepUs = 1000000L / vFrameRate

            var maxVideoPts = -1L
            var prevRawVideoPts = -1L
            var videoPtsOffset = 0L
            var videoSamples = 0

            var lastAudioPts = -1L
            var prevRawAudioPts = -1L
            var audioPtsOffset = 0L

            while (hasVideo || hasAudio) {
                val vTime = if (hasVideo) videoExtractor.sampleTime else Long.MAX_VALUE
                val aTime = if (hasAudio && audioExtractor != null) audioExtractor.sampleTime else Long.MAX_VALUE

                if (vTime < 0L) hasVideo = false
                if (aTime < 0L) hasAudio = false
                if (!hasVideo && !hasAudio) break

                if (hasVideo && (!hasAudio || vTime <= aTime)) {
                    val sampleSize = videoExtractor.readSampleData(buffer, 0)
                    if (sampleSize <= 0) {
                        hasVideo = videoExtractor.advance()
                        continue
                    }
                    val rawPts = videoExtractor.sampleTime
                    if (prevRawVideoPts != -1L && rawPts < prevRawVideoPts - 500000L) {
                        // Segment discontinuity/reset detected
                        videoPtsOffset += (maxVideoPts - (rawPts - basePts + videoPtsOffset) + videoStepUs)
                    }
                    prevRawVideoPts = rawPts

                    var pts = (rawPts - basePts + videoPtsOffset).coerceAtLeast(0L)
                    if (monotonicPts && pts <= maxVideoPts) {
                        pts = maxVideoPts + 1000L
                    }
                    if (pts > maxVideoPts) maxVideoPts = pts

                    bufferInfo.offset = 0
                    bufferInfo.size = sampleSize
                    bufferInfo.presentationTimeUs = pts
                    bufferInfo.flags = if ((videoExtractor.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC) != 0) {
                        MediaCodec.BUFFER_FLAG_KEY_FRAME
                    } else {
                        0
                    }
                    muxer.writeSampleData(muxerVideoTrack, buffer, bufferInfo)
                    videoSamples++
                    hasVideo = videoExtractor.advance()
                } else if (hasAudio && audioExtractor != null) {
                    val sampleSize = audioExtractor.readSampleData(buffer, 0)
                    if (sampleSize <= 0) {
                        hasAudio = audioExtractor.advance()
                        continue
                    }
                    val rawPts = audioExtractor.sampleTime
                    if (prevRawAudioPts != -1L && rawPts < prevRawAudioPts - 500000L) {
                        // Audio segment discontinuity detected
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
                    bufferInfo.flags = if ((audioExtractor.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC) != 0) {
                        MediaCodec.BUFFER_FLAG_KEY_FRAME
                    } else {
                        0
                    }
                    muxer.writeSampleData(muxerAudioTrack, buffer, bufferInfo)
                    hasAudio = audioExtractor.advance()
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
        } finally {
            if (muxerStarted) {
                try { muxer?.stop() } catch (_: Exception) {}
            }
            try { muxer?.release() } catch (_: Exception) {}
            try { videoExtractor?.release() } catch (_: Exception) {}
            try { audioExtractor?.release() } catch (_: Exception) {}
            if (!ok) {
                try { outputFile.delete() } catch (_: Exception) {}
            }
        }

        // Validate the produced MP4 by re-opening it.
        if (!outputFile.exists() || outputFile.length() <= 50000) {
            Log.w(TAG, "Validation failed: output file missing or smaller than 50KB (${outputFile.length()} bytes)")
            try { outputFile.delete() } catch (_: Exception) {}
            return false
        }
        val info = probeMedia(outputPath)
        val hasVideoTrack = (info?.get("hasVideo") as? Boolean) ?: false
        if (!hasVideoTrack) {
            Log.w(TAG, "Validation failed: no video track detected in output MP4")
            try { outputFile.delete() } catch (_: Exception) {}
            return false
        }
        val durationMs = (info["durationMs"] as? Long) ?: 0L
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
