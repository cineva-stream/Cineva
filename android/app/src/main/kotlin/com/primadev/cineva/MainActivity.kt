package com.primadev.cineva

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.primadev.cineva/muxer"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "muxToMp4") {
                val videoPath = call.argument<String>("videoPath")
                val audioPath = call.argument<String>("audioPath")
                val outputPath = call.argument<String>("outputPath")

                if (videoPath == null || outputPath == null) {
                    result.error("INVALID_ARGS", "videoPath and outputPath are required", null)
                    return@setMethodCallHandler
                }

                thread {
                    try {
                        val success = muxTsToMp4(videoPath, audioPath, outputPath)
                        runOnUiThread {
                            if (success) {
                                result.success(true)
                            } else {
                                result.error("MUX_FAILED", "MediaMuxer failed to process tracks", null)
                            }
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("MUX_EXCEPTION", e.message, e.stackTraceToString())
                        }
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun muxTsToMp4(videoPath: String, audioPath: String?, outputPath: String): Boolean {
        val videoExtractor = MediaExtractor()
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
            videoExtractor.release()
            return false
        }

        val separateAudioExtractor = if (audioPath != null && File(audioPath).exists()) {
            val ext = MediaExtractor()
            try {
                ext.setDataSource(audioPath)
                ext
            } catch (e: Exception) {
                ext.release()
                null
            }
        } else null

        var separateAudioTrackIndex = -1
        var separateAudioFormat: MediaFormat? = null

        if (separateAudioExtractor != null) {
            for (i in 0 until separateAudioExtractor.trackCount) {
                val format = separateAudioExtractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("audio/")) {
                    separateAudioTrackIndex = i
                    separateAudioFormat = format
                    break
                }
            }
        }

        // Target output file
        val outputFile = File(outputPath)
        if (outputFile.exists()) outputFile.delete()
        outputFile.parentFile?.mkdirs()

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

        // Ensure CSD for video if missing in MediaFormat from MPEG-TS
        ensureVideoCsd(videoExtractor, videoTrackIndex, videoFormat)
        val muxerVideoTrack = muxer.addTrack(videoFormat)

        val activeAudioExtractor: MediaExtractor?
        val activeAudioSourceTrack: Int
        val muxerAudioTrack: Int

        if (separateAudioExtractor != null && separateAudioTrackIndex != -1 && separateAudioFormat != null) {
            activeAudioExtractor = separateAudioExtractor
            activeAudioSourceTrack = separateAudioTrackIndex
            ensureAudioCsd(separateAudioFormat)
            muxerAudioTrack = muxer.addTrack(separateAudioFormat)
        } else if (embeddedAudioTrackIndex != -1 && embeddedAudioFormat != null) {
            activeAudioExtractor = videoExtractor
            activeAudioSourceTrack = embeddedAudioTrackIndex
            ensureAudioCsd(embeddedAudioFormat)
            muxerAudioTrack = muxer.addTrack(embeddedAudioFormat)
        } else {
            activeAudioExtractor = null
            activeAudioSourceTrack = -1
            muxerAudioTrack = -1
        }

        muxer.start()

        videoExtractor.selectTrack(videoTrackIndex)
        activeAudioExtractor?.selectTrack(activeAudioSourceTrack)

        val buffer = ByteBuffer.allocateDirect(2 * 1024 * 1024)
        val bufferInfo = MediaCodec.BufferInfo()

        var hasVideo = true
        var hasAudio = activeAudioExtractor != null

        val vFrameRate = if (videoFormat.containsKey(MediaFormat.KEY_FRAME_RATE)) {
            val r = videoFormat.getInteger(MediaFormat.KEY_FRAME_RATE)
            if (r > 0) r else 24
        } else 24
        val videoStepUs = 1000000L / vFrameRate

        var lastVideoPts = -1L
        var prevRawVideoPts = -1L
        var videoPtsOffset = 0L

        var lastAudioPts = -1L
        var prevRawAudioPts = -1L
        var audioPtsOffset = 0L

        while (hasVideo || hasAudio) {
            val vTime = if (hasVideo) videoExtractor.sampleTime else Long.MAX_VALUE
            val aTime = if (hasAudio && activeAudioExtractor != null) activeAudioExtractor.sampleTime else Long.MAX_VALUE

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
                    videoPtsOffset += (lastVideoPts - rawPts + videoStepUs)
                }
                prevRawVideoPts = rawPts

                var pts = rawPts + videoPtsOffset
                if (pts <= lastVideoPts) {
                    pts = lastVideoPts + 1000L
                }
                lastVideoPts = pts

                bufferInfo.offset = 0
                bufferInfo.size = sampleSize
                bufferInfo.presentationTimeUs = pts
                bufferInfo.flags = if ((videoExtractor.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC) != 0) {
                    MediaCodec.BUFFER_FLAG_KEY_FRAME
                } else {
                    0
                }
                muxer.writeSampleData(muxerVideoTrack, buffer, bufferInfo)
                hasVideo = videoExtractor.advance()
            } else if (hasAudio && activeAudioExtractor != null) {
                val sampleSize = activeAudioExtractor.readSampleData(buffer, 0)
                if (sampleSize <= 0) {
                    hasAudio = activeAudioExtractor.advance()
                    continue
                }
                val rawPts = activeAudioExtractor.sampleTime
                if (prevRawAudioPts != -1L && rawPts < prevRawAudioPts - 500000L) {
                    // Audio segment discontinuity detected
                    audioPtsOffset += (lastAudioPts - rawPts + 21333L)
                }
                prevRawAudioPts = rawPts

                var pts = rawPts + audioPtsOffset
                if (pts <= lastAudioPts) {
                    pts = lastAudioPts + 1000L
                }
                lastAudioPts = pts

                bufferInfo.offset = 0
                bufferInfo.size = sampleSize
                bufferInfo.presentationTimeUs = pts
                bufferInfo.flags = if ((activeAudioExtractor.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC) != 0) {
                    MediaCodec.BUFFER_FLAG_KEY_FRAME
                } else {
                    0
                }
                muxer.writeSampleData(muxerAudioTrack, buffer, bufferInfo)
                hasAudio = activeAudioExtractor.advance()
            }
        }

        try {
            muxer.stop()
        } catch (e: Exception) {}
        muxer.release()

        videoExtractor.release()
        if (separateAudioExtractor != null && separateAudioExtractor != videoExtractor) {
            separateAudioExtractor.release()
        }

        return outputFile.exists() && outputFile.length() > 50000
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

