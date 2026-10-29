package com.devsinntechnologies.iqraquran

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLExt
import android.opengl.EGLSurface
import android.opengl.GLES20
import android.opengl.GLUtils
import android.os.Handler
import android.os.Looper
import android.view.Surface
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

// Turns still frames, each shown from a given time until the next starts,
// plus an optional recitation into an MP4 (H.264 + AAC) using the device's
// own media encoders. A slow zoom can be applied across the whole video.
class VerseVideoEncoder(private val channel: MethodChannel) : MethodChannel.MethodCallHandler {

    private class Job(
        val frames: List<String>,
        val frameStartsMs: List<Long>,
        val audioPath: String?,
        val durationMs: Long,
        val zoomTo: Float,
        val outputPath: String,
        val width: Int,
        val height: Int,
        val fps: Int,
    )

    private class Sample(val data: ByteArray, val ptsUs: Long, val flags: Int)

    private class Track(val format: MediaFormat, val samples: List<Sample>, val durationUs: Long)

    private val main = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "encode") {
            result.notImplemented()
            return
        }
        val job = Job(
            frames = call.argument<List<String>>("frames")!!,
            frameStartsMs = call.argument<List<Number>>("frameStartsMs")!!.map { it.toLong() },
            audioPath = call.argument<String>("audioPath"),
            durationMs = call.argument<Number>("durationMs")?.toLong() ?: 0L,
            zoomTo = call.argument<Number>("zoomTo")?.toFloat() ?: 1f,
            outputPath = call.argument<String>("outputPath")!!,
            width = call.argument<Int>("width")!!,
            height = call.argument<Int>("height")!!,
            fps = call.argument<Int>("fps")!!,
        )
        Thread {
            try {
                encode(job)
                main.post { result.success(job.outputPath) }
            } catch (e: Exception) {
                main.post { result.error("encode_failed", e.message ?: e.toString(), null) }
            }
        }.start()
    }

    private fun progress(value: Double) = main.post { channel.invokeMethod("progress", value) }

    private fun encode(job: Job) {
        val audio = job.audioPath?.let { transcodeAudio(it) }
        progress(0.15)
        // Hold the last frame briefly after the recitation ends.
        val durationUs = if (audio != null) {
            maxOf(audio.durationUs, job.frameStartsMs.last() * 1000) + 600_000
        } else {
            maxOf(job.durationMs, job.frameStartsMs.last()) * 1000
        }
        val video = encodeVideo(job, durationUs) { progress(0.15 + 0.8 * it) }
        mux(job.outputPath, video, audio)
        progress(1.0)
    }

    // ------------------------------------------------------------------ video

    private fun encodeVideo(job: Job, durationUs: Long, onProgress: (Double) -> Unit): Track {
        val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, job.width, job.height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, 4_000_000)
            setInteger(MediaFormat.KEY_FRAME_RATE, job.fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)
        }
        val codec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val egl = EglSurface(codec.createInputSurface())
        codec.start()
        val renderer = FrameRenderer()

        val samples = mutableListOf<Sample>()
        val info = MediaCodec.BufferInfo()
        var outputFormat: MediaFormat? = null
        try {
            val frameCount = (durationUs * job.fps / 1_000_000).toInt()
            var frame = 0
            var loaded = -1
            for (i in 0 until frameCount) {
                val ptsUs = i * 1_000_000L / job.fps
                while (frame + 1 < job.frameStartsMs.size && job.frameStartsMs[frame + 1] * 1000 <= ptsUs) {
                    frame++
                }
                if (frame != loaded) {
                    val bitmap = BitmapFactory.decodeFile(job.frames[frame])
                        ?: throw IllegalStateException("Could not read frame $frame")
                    renderer.load(bitmap)
                    loaded = frame
                }
                renderer.draw(job.width, job.height, 1f + (job.zoomTo - 1f) * i / frameCount)
                egl.present(ptsUs * 1000)
                outputFormat = drain(codec, info, samples, outputFormat, endOfStream = false)
                if (i % job.fps == 0) onProgress(i.toDouble() / frameCount)
            }
            codec.signalEndOfInputStream()
            outputFormat = drain(codec, info, samples, outputFormat, endOfStream = true)
        } finally {
            renderer.release()
            egl.release()
            codec.stop()
            codec.release()
        }
        return Track(outputFormat ?: throw IllegalStateException("No video produced"), samples, durationUs)
    }

    // Moves finished output to [out]; with [endOfStream], waits until the
    // encoder has emitted everything.
    private fun drain(
        codec: MediaCodec,
        info: MediaCodec.BufferInfo,
        out: MutableList<Sample>,
        format: MediaFormat?,
        endOfStream: Boolean,
    ): MediaFormat? {
        var outputFormat = format
        var idleWaits = 0
        while (true) {
            val index = codec.dequeueOutputBuffer(info, if (endOfStream) 10_000 else 0)
            when {
                index == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) return outputFormat
                    if (++idleWaits > 500) throw IllegalStateException("Encoder did not finish")
                }
                index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> outputFormat = codec.outputFormat
                index >= 0 -> {
                    idleWaits = 0
                    val buffer = codec.getOutputBuffer(index)!!
                    if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0 && info.size > 0) {
                        val bytes = ByteArray(info.size)
                        buffer.position(info.offset)
                        buffer.get(bytes, 0, info.size)
                        out.add(Sample(bytes, info.presentationTimeUs, info.flags))
                    }
                    codec.releaseOutputBuffer(index, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) return outputFormat
                }
            }
        }
    }

    // ------------------------------------------------------------------ audio

    // MP4 needs AAC, and recitations are MP3: decode to PCM, then encode.
    private fun transcodeAudio(path: String): Track {
        val extractor = MediaExtractor()
        extractor.setDataSource(path)
        val trackIndex = (0 until extractor.trackCount).firstOrNull {
            extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
        } ?: throw IllegalStateException("No audio in recitation")
        extractor.selectTrack(trackIndex)
        val inputFormat = extractor.getTrackFormat(trackIndex)
        var sampleRate = inputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        var channels = inputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)

        val pcm = ByteArrayOutputStream()
        val decoder = MediaCodec.createDecoderByType(inputFormat.getString(MediaFormat.KEY_MIME)!!)
        decoder.configure(inputFormat, null, null, 0)
        decoder.start()
        val info = MediaCodec.BufferInfo()
        try {
            var inputDone = false
            while (true) {
                if (!inputDone) {
                    val index = decoder.dequeueInputBuffer(10_000)
                    if (index >= 0) {
                        val size = extractor.readSampleData(decoder.getInputBuffer(index)!!, 0)
                        if (size < 0) {
                            decoder.queueInputBuffer(index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            decoder.queueInputBuffer(index, 0, size, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }
                val index = decoder.dequeueOutputBuffer(info, 10_000)
                if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    val format = decoder.outputFormat
                    sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    if (format.containsKey(MediaFormat.KEY_PCM_ENCODING) &&
                        format.getInteger(MediaFormat.KEY_PCM_ENCODING) != AudioFormat.ENCODING_PCM_16BIT
                    ) {
                        throw IllegalStateException("Unsupported audio sample format")
                    }
                } else if (index >= 0) {
                    val buffer = decoder.getOutputBuffer(index)!!
                    if (info.size > 0) {
                        val bytes = ByteArray(info.size)
                        buffer.position(info.offset)
                        buffer.get(bytes)
                        pcm.write(bytes)
                    }
                    decoder.releaseOutputBuffer(index, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
                }
            }
        } finally {
            decoder.stop()
            decoder.release()
            extractor.release()
        }

        val data = pcm.toByteArray()
        val bytesPerFrame = 2 * channels
        val format = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, sampleRate, channels).apply {
            setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
            setInteger(MediaFormat.KEY_BIT_RATE, 128_000)
            setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16_384)
        }
        val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        encoder.start()
        val samples = mutableListOf<Sample>()
        var outputFormat: MediaFormat? = null
        try {
            var offset = 0
            var inputDone = false
            while (true) {
                if (!inputDone) {
                    val index = encoder.dequeueInputBuffer(10_000)
                    if (index >= 0) {
                        val buffer = encoder.getInputBuffer(index)!!
                        buffer.clear()
                        val chunk = minOf(buffer.capacity() / bytesPerFrame * bytesPerFrame, data.size - offset)
                        val ptsUs = (offset / bytesPerFrame) * 1_000_000L / sampleRate
                        if (chunk <= 0) {
                            encoder.queueInputBuffer(index, 0, 0, ptsUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            buffer.put(data, offset, chunk)
                            encoder.queueInputBuffer(index, 0, chunk, ptsUs, 0)
                            offset += chunk
                        }
                    }
                }
                val index = encoder.dequeueOutputBuffer(info, 10_000)
                if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    outputFormat = encoder.outputFormat
                } else if (index >= 0) {
                    val buffer = encoder.getOutputBuffer(index)!!
                    if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0 && info.size > 0) {
                        val bytes = ByteArray(info.size)
                        buffer.position(info.offset)
                        buffer.get(bytes)
                        samples.add(Sample(bytes, info.presentationTimeUs, info.flags))
                    }
                    encoder.releaseOutputBuffer(index, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
                }
            }
        } finally {
            encoder.stop()
            encoder.release()
        }
        val durationUs = data.size.toLong() / bytesPerFrame * 1_000_000L / sampleRate
        return Track(outputFormat ?: throw IllegalStateException("No audio produced"), samples, durationUs)
    }

    // ------------------------------------------------------------------- mux

    private fun mux(path: String, video: Track, audio: Track?) {
        val muxer = MediaMuxer(path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        try {
            val videoTrack = muxer.addTrack(video.format)
            val audioTrack = audio?.let { muxer.addTrack(it.format) } ?: -1
            val audioSamples = audio?.samples ?: emptyList()
            muxer.start()
            val info = MediaCodec.BufferInfo()
            var v = 0
            var a = 0
            // Interleave by time so players can stream the file.
            while (v < video.samples.size || a < audioSamples.size) {
                val takeVideo = a >= audioSamples.size ||
                    (v < video.samples.size && video.samples[v].ptsUs <= audioSamples[a].ptsUs)
                val sample = if (takeVideo) video.samples[v++] else audioSamples[a++]
                info.set(0, sample.data.size, sample.ptsUs,
                    sample.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM.inv())
                muxer.writeSampleData(if (takeVideo) videoTrack else audioTrack, ByteBuffer.wrap(sample.data), info)
            }
            muxer.stop()
        } finally {
            muxer.release()
        }
    }

    // ------------------------------------------------------------------- GL

    // An EGL context drawing into the encoder's input surface, so each frame
    // can carry its exact presentation time.
    private class EglSurface(private val surface: Surface) {
        private val display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        private val context: EGLContext
        private val eglSurface: EGLSurface

        init {
            val version = IntArray(2)
            check(EGL14.eglInitialize(display, version, 0, version, 1)) { "EGL unavailable" }
            val attributes = intArrayOf(
                EGL14.EGL_RED_SIZE, 8, EGL14.EGL_GREEN_SIZE, 8, EGL14.EGL_BLUE_SIZE, 8,
                EGL14.EGL_ALPHA_SIZE, 8, EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL_RECORDABLE_ANDROID, 1, EGL14.EGL_NONE,
            )
            val configs = arrayOfNulls<EGLConfig>(1)
            val count = IntArray(1)
            check(EGL14.eglChooseConfig(display, attributes, 0, configs, 0, 1, count, 0) && count[0] > 0) {
                "No EGL config for video encoding"
            }
            context = EGL14.eglCreateContext(
                display, configs[0], EGL14.EGL_NO_CONTEXT,
                intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE), 0,
            )
            eglSurface = EGL14.eglCreateWindowSurface(display, configs[0], surface, intArrayOf(EGL14.EGL_NONE), 0)
            check(EGL14.eglMakeCurrent(display, eglSurface, eglSurface, context)) { "EGL makeCurrent failed" }
        }

        fun present(timeNs: Long) {
            EGLExt.eglPresentationTimeANDROID(display, eglSurface, timeNs)
            EGL14.eglSwapBuffers(display, eglSurface)
        }

        // The display is shared with Flutter's renderer, so it is not
        // terminated here.
        fun release() {
            EGL14.eglMakeCurrent(display, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
            EGL14.eglDestroySurface(display, eglSurface)
            EGL14.eglDestroyContext(display, context)
            EGL14.eglReleaseThread()
            surface.release()
        }

        companion object {
            private const val EGL_RECORDABLE_ANDROID = 0x3142
        }
    }

    // Draws one bitmap over the whole frame.
    private class FrameRenderer {
        private val program: Int
        private val texture: Int
        private val position: Int
        private val texCoord: Int
        private val scale: Int

        // x, y, u, v for a full-frame strip; bitmap row 0 is the top.
        private val quad: FloatBuffer = ByteBuffer.allocateDirect(16 * 4)
            .order(ByteOrder.nativeOrder()).asFloatBuffer().apply {
                put(floatArrayOf(-1f, -1f, 0f, 1f, 1f, -1f, 1f, 1f, -1f, 1f, 0f, 0f, 1f, 1f, 1f, 0f))
                position(0)
            }

        init {
            program = GLES20.glCreateProgram()
            GLES20.glAttachShader(program, shader(GLES20.GL_VERTEX_SHADER, VERTEX))
            GLES20.glAttachShader(program, shader(GLES20.GL_FRAGMENT_SHADER, FRAGMENT))
            GLES20.glLinkProgram(program)
            position = GLES20.glGetAttribLocation(program, "aPosition")
            texCoord = GLES20.glGetAttribLocation(program, "aTexCoord")
            scale = GLES20.glGetUniformLocation(program, "uScale")
            val textures = IntArray(1)
            GLES20.glGenTextures(1, textures, 0)
            texture = textures[0]
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        }

        fun load(bitmap: Bitmap) {
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture)
            GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
            bitmap.recycle()
        }

        fun draw(width: Int, height: Int, zoom: Float) {
            GLES20.glViewport(0, 0, width, height)
            GLES20.glClearColor(0f, 0f, 0f, 1f)
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
            GLES20.glUseProgram(program)
            GLES20.glUniform1f(scale, zoom)
            GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture)
            quad.position(0)
            GLES20.glVertexAttribPointer(position, 2, GLES20.GL_FLOAT, false, 16, quad)
            GLES20.glEnableVertexAttribArray(position)
            quad.position(2)
            GLES20.glVertexAttribPointer(texCoord, 2, GLES20.GL_FLOAT, false, 16, quad)
            GLES20.glEnableVertexAttribArray(texCoord)
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        }

        fun release() {
            GLES20.glDeleteTextures(1, intArrayOf(texture), 0)
            GLES20.glDeleteProgram(program)
        }

        private fun shader(type: Int, source: String): Int {
            val shader = GLES20.glCreateShader(type)
            GLES20.glShaderSource(shader, source)
            GLES20.glCompileShader(shader)
            val status = IntArray(1)
            GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, status, 0)
            check(status[0] != 0) { "Shader error: ${GLES20.glGetShaderInfoLog(shader)}" }
            return shader
        }

        companion object {
            private const val VERTEX = """
                attribute vec4 aPosition;
                attribute vec2 aTexCoord;
                uniform float uScale;
                varying vec2 vTexCoord;
                void main() {
                    gl_Position = vec4(aPosition.xy * uScale, 0.0, 1.0);
                    vTexCoord = aTexCoord;
                }
            """
            private const val FRAGMENT = """
                precision mediump float;
                varying vec2 vTexCoord;
                uniform sampler2D uTexture;
                void main() {
                    gl_FragColor = texture2D(uTexture, vTexCoord);
                }
            """
        }
    }

    companion object {
        const val CHANNEL = "com.devsinntechnologies.iqraquran/verse_video"
    }
}
