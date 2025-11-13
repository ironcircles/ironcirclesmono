package com.ironcircles.ironcirclesapp

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioManager
import android.media.MediaRecorder
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.io.RandomAccessFile
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.TimeUnit
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.pow
import kotlin.math.sqrt

class VoicePlatformPlugin(private val activity: Activity) : MethodChannel.MethodCallHandler {
    companion object {
        private const val CHANNEL_NAME = "com.ironcircles/voice_channel"
        private const val EVENT_CHANNEL_NAME = "com.ironcircles/voice_events"
        private const val TAG = "VoicePlatformPlugin"
        private const val REQUEST_RECORD_AUDIO = 0x5612
        private const val AMPLITUDE_INTERVAL_MS = 120L
        private const val SILENT_FRAME_THRESHOLD = 28
        private const val SILENT_RMS_THRESHOLD = 0.003
        private const val CLIP_PEAK_THRESHOLD = 0.97
        private const val CLIP_FRACTION_THRESHOLD = 0.28
        private const val CLIP_FRAME_THRESHOLD = 4
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var events: EventChannel.EventSink? = null

    private val sampleRate = 44100
    private val bitsPerSample = 16

    private var audioRecord: AudioRecord? = null
    private var recordingExecutor: ExecutorService? = null
    private var recordingFuture: Future<*>? = null
    private var recordingFile: File? = null
    private var recordingFileHandle: RandomAccessFile? = null
    private var recordingBytes: Long = 0
    @Volatile private var recordingActive = false

    @Volatile private var lastBufferLevel = 0.0
    @Volatile private var lastVuLevel = 0.0
    @Volatile private var lastPeakLevel = 0.0
    private var lastAmplitudeLevel = 0.0

    private var speechRecognizer: SpeechRecognizer? = null
    private var speechIntent: Intent? = null
    private var partialSpeechResult: String = ""
    private var speechActive = false

    private val amplitudeHandler = Handler(Looper.getMainLooper())
    private val amplitudeRunnable = object : Runnable {
        override fun run() {
            val rawLevel = lastBufferLevel.coerceIn(0.0, 1.0)
            val targetDisplay = rmsToVuLevel(rawLevel)
            val mix = if (targetDisplay > lastAmplitudeLevel) 0.6 else 0.3
            lastAmplitudeLevel =
                (targetDisplay * mix) + (lastAmplitudeLevel * (1.0 - mix))
            lastVuLevel = lastAmplitudeLevel.coerceIn(0.0, 1.0)
            val payload = hashMapOf<String, Any?>(
                "level" to lastVuLevel,
                "rms" to rawLevel,
                "peak" to lastPeakLevel
            )
            sendStatus("voiceMemo", "amplitude", payload)
            if (recordingActive) {
                amplitudeHandler.postDelayed(this, AMPLITUDE_INTERVAL_MS)
            }
        }
    }

    private var permissionCallback: ((Boolean) -> Unit)? = null

    private val audioSources: MutableList<Int> = mutableListOf()
    private var currentAudioSourceIndex = 0
    private var silenceFrameCounter = 0
    private var clipFrameCounter = 0

    fun start(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }

        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL_NAME).also { channel ->
            channel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
                    events = eventSink
                    Log.d(TAG, "Event channel listener attached")
                }

                override fun onCancel(arguments: Any?) {
                    events = null
                    Log.d(TAG, "Event channel listener detached")
                }
            })
        }

        if (SpeechRecognizer.isRecognitionAvailable(activity)) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(activity)
            speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    sendStatus("voiceToText", "ready")
                }

                override fun onBeginningOfSpeech() {
                    sendStatus("voiceToText", "listening")
                }

                override fun onRmsChanged(rmsdB: Float) {}

                override fun onBufferReceived(buffer: ByteArray?) {}

                override fun onEndOfSpeech() {
                    sendStatus("voiceToText", "processing")
                }

                override fun onError(error: Int) {
                    val message = "speech_error_$error"
                    sendStatus("voiceToText", "error", mapOf("code" to error, "message" to message))
                    speechActive = false
                    sendStatus("voiceToText", "stopped")
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    val results = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    if (!results.isNullOrEmpty()) {
                        partialSpeechResult = results.first()
                        sendStatus(
                            "voiceToText",
                            "partial",
                            mapOf("text" to partialSpeechResult),
                        )
                    }
                }

                override fun onResults(results: Bundle?) {
                    val texts = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val text = texts?.firstOrNull() ?: partialSpeechResult
                    sendStatus(
                        "voiceToText",
                        "final",
                        mapOf("text" to text),
                    )
                    partialSpeechResult = ""
                    speechActive = false
                    sendStatus("voiceToText", "stopped")
                }

                override fun onEvent(eventType: Int, params: Bundle?) {}
            })

            speechIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 2500L)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 2000L)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 3000L)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, false)
                }
            }
        } else {
            Log.w(TAG, "Speech recognition not available on this device")
        }

        audioSources.clear()
        audioSources.add(MediaRecorder.AudioSource.MIC)
        audioSources.add(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (audioManager?.getProperty(AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED) == "true") {
                audioSources.add(MediaRecorder.AudioSource.UNPROCESSED)
            }
        }

        Log.d(TAG, "Voice platform channel initialised")
    }

    fun stop() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        events = null
        stopAmplitudeUpdates()
        cleanupRecordingResources(deleteFile = false)
        speechRecognizer?.destroy()
        speechRecognizer = null
        Log.d(TAG, "Voice platform channel disposed")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startVoiceMemo" -> startVoiceMemo(result)
            "stopVoiceMemo" -> stopVoiceMemo(result)
            "cancelVoiceMemo" -> cancelVoiceMemo(result)
            "startVoiceToText" -> startVoiceToText(result)
            "stopVoiceToText" -> {
                Log.d(TAG, "stopVoiceToText() requested")
                stopVoiceToText(result)
            }
            "checkMicrophone" -> {
                Log.d(TAG, "checkMicrophone() requested")
                val forcePrompt = (call.arguments as? Map<*, *>)?.get("forcePrompt") as? Boolean ?: false
                requestMicrophonePermission(forcePrompt = forcePrompt) { granted ->
                    val payload = mapOf("available" to granted)
                    sendStatus("microphone", "checked", payload)
                    result.success(payload)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun startVoiceMemo(result: MethodChannel.Result) {
        requestMicrophonePermission(forcePrompt = false) { granted ->
            if (!granted) {
                Log.w(TAG, "startVoiceMemo denied: mic permission not granted")
                result.error("mic_permission", "Microphone permission not granted", null)
                return@requestMicrophonePermission
            }

            if (recordingActive) {
                Log.w(TAG, "startVoiceMemo denied: already recording")
                result.error("already_recording", "Voice memo already in progress", null)
                return@requestMicrophonePermission
            }

            try {
                audioSources.clear()
                audioSources.addAll(determineAudioSources())
                currentAudioSourceIndex = 0

                val fileName = "voice_memo_${System.currentTimeMillis()}.wav"
                val outputDirectory = File(activity.cacheDir, "voice_memos").apply {
                    if (!exists()) {
                        Log.d(TAG, "Creating voice memo cache directory: $absolutePath")
                        mkdirs()
                    }
                }
                val file = File(outputDirectory, fileName)
                val handle = RandomAccessFile(file, "rw")
                writeWavHeader(handle, 0, sampleRate, 1, bitsPerSample)
                handle.seek(44)
                Log.d(TAG, "Voice memo file prepared at ${file.absolutePath}")

                val bufferSize = AudioRecord.getMinBufferSize(
                    sampleRate,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT
                ).let { if (it <= 0) sampleRate else it }
                Log.d(TAG, "Calculated buffer size: $bufferSize bytes")

                var recorder = obtainRecorder(bufferSize, skipCurrent = false)
                if (recorder == null) {
                    Log.e(TAG, "Failed to initialise AudioRecord")
                    handle.close()
                    result.error("start_failed", "Unable to initialise audio recorder", null)
                    return@requestMicrophonePermission
                }
                Log.d(TAG, "AudioRecord initialised (state=${recorder.state})")

                recorder.startRecording()
                if (recorder.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
                    Log.e(TAG, "AudioRecord failed to start (state=${recorder.recordingState})")
                    recorder.release()
                    handle.close()
                    result.error("start_failed", "Failed to start audio recording", null)
                    return@requestMicrophonePermission
                }
                Log.d(TAG, "AudioRecord started successfully")

                audioRecord = recorder
                recordingFile = file
                recordingFileHandle = handle
                recordingBytes = 0
                recordingActive = true
                lastBufferLevel = 0.0
                lastVuLevel = 0.0
                lastAmplitudeLevel = 0.0
                resetSilenceCounter()
                resetClipCounter()

                recordingExecutor = Executors.newSingleThreadExecutor()
                recordingFuture = recordingExecutor?.submit {
                    val shortBufferSize = (bufferSize / 2).coerceAtLeast(1024)
                    val shortBuffer = ShortArray(shortBufferSize)
                    val byteBuffer = ByteArray(shortBuffer.size * 2)
                    var zeroReadStreak = 0
                    var workingRecorder: AudioRecord? = recorder
                    android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_AUDIO)
                    Log.d(TAG, "Recording thread started")
                    try {
                        while (recordingActive) {
                            val currentRecorder = workingRecorder ?: break
                            val readSamples = currentRecorder.read(
                                shortBuffer,
                                0,
                                shortBuffer.size,
                                AudioRecord.READ_BLOCKING
                            )
                            if (readSamples <= 0) {
                                lastPeakLevel = 0.0
                                Log.w(TAG, "AudioRecord read returned $readSamples")
                                if (readSamples == AudioRecord.ERROR_BAD_VALUE || readSamples == AudioRecord.ERROR_INVALID_OPERATION) {
                                    Log.e(TAG, "AudioRecord read error: $readSamples")
                                    sendStatus(
                                        "voiceMemo",
                                        "error",
                                        mapOf("code" to "read_error", "value" to readSamples)
                                    )
                                    recordingActive = false
                                    break
                                }
                                if (readSamples == 0) {
                                    zeroReadStreak++
                                    Log.w(TAG, "Zero-read streak = $zeroReadStreak")
                                    if (zeroReadStreak >= 20) {
                                        Log.w(TAG, "Zero-read streak exceeded threshold; attempting re-init")
                                        val replacement = trySwitchRecorder(currentRecorder, bufferSize, "zero")
                                        if (replacement == null) {
                                            workingRecorder = null
                                            break
                                        }
                                        workingRecorder = replacement
                                        zeroReadStreak = 0
                                        resetSilenceCounter()
                                        resetClipCounter()
                                        continue
                                    }
                                }
                                continue
                            }

                            if (zeroReadStreak > 0) {
                                Log.d(TAG, "Recovered from zero-read streak ($zeroReadStreak)")
                            }
                            zeroReadStreak = 0

                            if (recordingActive) {
                                var byteIndex = 0
                                var sum = 0.0
                                var clippedSamples = 0
                                var peak = 0.0
                                for (i in 0 until readSamples) {
                                    val sample = shortBuffer[i]
                                    byteBuffer[byteIndex++] = (sample.toInt() and 0xFF).toByte()
                                    byteBuffer[byteIndex++] = ((sample.toInt() shr 8) and 0xFF).toByte()

                                    val normalized = sample / Short.MAX_VALUE.toDouble()
                                    val absNormalized = kotlin.math.abs(normalized)
                                    if (absNormalized >= CLIP_PEAK_THRESHOLD) {
                                        clippedSamples++
                                    }
                                    if (absNormalized > peak) {
                                        peak = absNormalized
                                    }
                                    sum += normalized * normalized
                                }

                                val bytesWritten = readSamples * 2
                                recordingFileHandle?.write(byteBuffer, 0, bytesWritten)
                                recordingBytes += bytesWritten.toLong()

                                if (readSamples > 0) {
                                    val rms = sqrt(sum / readSamples)
                                    lastBufferLevel = rms
                                    val displayLevel = rmsToVuLevel(rms)
                                    lastVuLevel = displayLevel
                                    lastPeakLevel = peak.coerceIn(0.0, 1.0)

                                    val clippedFraction = clippedSamples.toDouble() / readSamples.toDouble()
                                    if (clippedFraction >= CLIP_FRACTION_THRESHOLD || peak >= CLIP_PEAK_THRESHOLD) {
                                        if (registerClipFrame()) {
                                            Log.w(TAG, "Detected sustained clipping (fraction=$clippedFraction peak=$peak); rotating audio source")
                                            val replacement = trySwitchRecorder(currentRecorder, bufferSize, "clip")
                                            if (replacement == null) {
                                                workingRecorder = null
                                                break
                                            }
                                            workingRecorder = replacement
                                            zeroReadStreak = 0
                                            resetSilenceCounter()
                                            resetClipCounter()
                                            continue
                                        }
                                    } else {
                                        resetClipCounter()
                                    }

                                    if (rms < SILENT_RMS_THRESHOLD) {
                                        if (registerSilenceFrame()) {
                                            Log.w(TAG, "Detected sustained silence; rotating audio source")
                                            val replacement = trySwitchRecorder(currentRecorder, bufferSize, "silent")
                                            if (replacement == null) {
                                                workingRecorder = null
                                                break
                                            }
                                            workingRecorder = replacement
                                            zeroReadStreak = 0
                                            resetSilenceCounter()
                                            resetClipCounter()
                                            continue
                                        }
                                    } else {
                                        resetSilenceCounter()
                                    }
                                } else {
                                    if (registerSilenceFrame()) {
                                        Log.w(TAG, "No samples read; rotating audio source")
                                        val replacement = trySwitchRecorder(currentRecorder, bufferSize, "zero")
                                        if (replacement == null) {
                                            workingRecorder = null
                                            break
                                        }
                                        workingRecorder = replacement
                                        zeroReadStreak = 0
                                        resetSilenceCounter()
                                        resetClipCounter()
                                        continue
                                    }
                                    lastBufferLevel = 0.0
                                    lastVuLevel = 0.0
                                }
                                Log.v(
                                    TAG,
                                    "Recorded $bytesWritten bytes ($readSamples samples), rms=$lastBufferLevel vu=$lastVuLevel " +
                                        "(silentFrames=$silenceFrameCounter clipFrames=$clipFrameCounter)"
                                )
                            }
                        }
                    } catch (ex: IOException) {
                        Log.e(TAG, "Error writing audio data", ex)
                    } finally {
                        Log.d(TAG, "Recording thread shutting down")
                        try {
                            recordingFileHandle?.fd?.sync()
                        } catch (ex: IOException) {
                            Log.w(TAG, "Failed to sync recording file", ex)
                        }
                        try {
                            recordingFileHandle?.close()
                        } catch (ex: IOException) {
                            Log.w(TAG, "Failed to close recording file", ex)
                        }
                        recordingFileHandle = null
                    }
                }

                sendStatus("voiceMemo", "started", mapOf("path" to file.absolutePath))
                startAmplitudeUpdates()
                Log.d(TAG, "Voice memo recording started")
                result.success(mapOf("path" to file.absolutePath))
            } catch (ex: Exception) {
                Log.e(TAG, "Failed to start voice memo", ex)
                stopAmplitudeUpdates()
                cleanupRecordingResources(deleteFile = true)
                result.error("start_failed", ex.message, null)
            }
        }
    }

    private fun createAudioRecord(bufferSize: Int, audioSource: Int): AudioRecord? {
        val internalBufferSize = (bufferSize * 4).coerceAtLeast(bufferSize)
        val audioFormat = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(sampleRate)
            .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
            .build()

        val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val builder = AudioRecord.Builder()
                .setAudioSource(audioSource)
                .setAudioFormat(audioFormat)
                .setBufferSizeInBytes(internalBufferSize)
            builder.build()
        } else {
            AudioRecord(
                audioSource,
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                internalBufferSize
            )
        }

        return if (recorder.state == AudioRecord.STATE_INITIALIZED) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                try {
                    if (android.media.audiofx.AutomaticGainControl.isAvailable()) {
                        android.media.audiofx.AutomaticGainControl.create(recorder.audioSessionId)?.enabled = false
                    }
                    if (android.media.audiofx.NoiseSuppressor.isAvailable()) {
                        android.media.audiofx.NoiseSuppressor.create(recorder.audioSessionId)?.enabled = false
                    }
                } catch (ex: Exception) {
                    Log.w(TAG, "Failed to disable input audio effects", ex)
                }
            }
            Log.d(TAG, "AudioRecord READY with source=$audioSource sessionId=${recorder.audioSessionId}")
            recorder
        } else {
            null
        }
    }

    private fun obtainRecorder(bufferSize: Int, skipCurrent: Boolean): AudioRecord? {
        if (audioSources.isEmpty()) {
            audioSources.add(MediaRecorder.AudioSource.MIC)
        }

        val total = audioSources.size
        var attempts = 0
        if (skipCurrent) {
            currentAudioSourceIndex = (currentAudioSourceIndex + 1) % total
        }

        while (attempts < total) {
            val source = audioSources[currentAudioSourceIndex]
            Log.d(TAG, "Initialising AudioRecord with source=$source (attempt ${attempts + 1}/$total)")
            val recorder = createAudioRecord(bufferSize, source)
            if (recorder != null) {
                return recorder
            }
            Log.w(TAG, "Failed to initialise AudioRecord with source=$source; trying next")
            currentAudioSourceIndex = (currentAudioSourceIndex + 1) % total
            attempts++
            try {
                Thread.sleep(40)
            } catch (_: InterruptedException) {
            }
        }

        return null
    }

    private fun stopVoiceMemo(result: MethodChannel.Result) {
        if (!recordingActive && audioRecord == null) {
            result.error("not_recording", "No active voice memo", null)
            return
        }

        val recordedFile = recordingFile
        val recorder = audioRecord
        recordingActive = false

        try {
            recordingFuture?.get(1, TimeUnit.SECONDS)
        } catch (ex: Exception) {
            Log.w(TAG, "Recording thread did not finish cleanly", ex)
        }
        recordingExecutor?.shutdown()
        recordingExecutor = null
        recordingFuture = null

        try {
            recorder?.stop()
        } catch (ex: Exception) {
            Log.w(TAG, "Error stopping AudioRecord", ex)
        } finally {
            recorder?.release()
            audioRecord = null
        }

        stopAmplitudeUpdates()
                                    lastBufferLevel = 0.0
                                    lastVuLevel = 0.0
                                    lastPeakLevel = 0.0
        lastAmplitudeLevel = 0.0
        sendStatus("voiceMemo", "amplitude", mapOf("level" to 0.0))

        val durationMs = if (recordingBytes > 0) {
            ((recordingBytes / 2.0) / sampleRate * 1000.0).toLong()
        } else {
            0L
        }

        try {
            if (recordedFile != null && recordedFile.exists()) {
                val raf = RandomAccessFile(recordedFile, "rw")
                writeWavHeader(
                    raf,
                    recordingBytes,
                    sampleRate,
                    1,
                    bitsPerSample
                )
                raf.close()
            }
        } catch (ex: Exception) {
            Log.e(TAG, "Failed to finalise WAV header", ex)
        }

        val response = mutableMapOf<String, Any?>()
        response["durationMs"] = durationMs
        response["path"] = recordedFile?.absolutePath

        sendStatus("voiceMemo", "stopped", response)
        result.success(response)

        cleanupRecordingResources(deleteFile = false)
        recordingBytes = 0
        recordingFile = null
    }

    private fun cancelVoiceMemo(result: MethodChannel.Result) {
        stopAmplitudeUpdates()
        cleanupRecordingResources(deleteFile = true)
        sendStatus("voiceMemo", "amplitude", mapOf("level" to 0.0))
        sendStatus("voiceMemo", "cancelled")
        result.success(null)
    }

    private fun startAmplitudeUpdates() {
        amplitudeHandler.removeCallbacks(amplitudeRunnable)
        amplitudeHandler.postDelayed(amplitudeRunnable, AMPLITUDE_INTERVAL_MS)
    }

    private fun stopAmplitudeUpdates() {
        amplitudeHandler.removeCallbacks(amplitudeRunnable)
        lastBufferLevel = 0.0
        lastVuLevel = 0.0
        lastPeakLevel = 0.0
        lastAmplitudeLevel = 0.0
    }

    private fun startVoiceToText(result: MethodChannel.Result) {
        Log.d(TAG, "startVoiceToText() requested")
        requestMicrophonePermission(forcePrompt = false) { granted ->
            if (!granted) {
                result.error("mic_permission", "Microphone permission not granted", null)
                return@requestMicrophonePermission
            }
            val recognizer = speechRecognizer
            val intent = speechIntent
            if (recognizer == null || intent == null) {
                result.error("not_available", "Speech recognition not available", null)
                return@requestMicrophonePermission
            }
            if (speechActive) {
                result.error("already_listening", "Speech recognition already active", null)
                return@requestMicrophonePermission
            }
            try {
                partialSpeechResult = ""
                speechActive = true
                recognizer.startListening(intent)
                sendStatus("voiceToText", "started")
                result.success(null)
            } catch (ex: Exception) {
                Log.e(TAG, "Failed to start voice to text", ex)
                speechActive = false
                result.error("start_failed", ex.message, null)
            }
        }
    }

    private fun stopVoiceToText(result: MethodChannel.Result) {
        val recognizer = speechRecognizer
        if (recognizer == null || !speechActive) {
            result.error("not_listening", "Speech recognition not active", null)
            return
        }

        try {
            recognizer.stopListening()
        } catch (ex: Exception) {
            Log.e(TAG, "Failed to stop speech recognizer", ex)
        } finally {
            speechActive = false
            sendStatus("voiceToText", "stopped")
        }

        result.success(null)
    }

    private fun requestMicrophonePermission(forcePrompt: Boolean, callback: (Boolean) -> Unit) {
        val permission = android.Manifest.permission.RECORD_AUDIO
        val granted = ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED

        if (granted && !forcePrompt) {
            Log.d(TAG, "Microphone permission already granted")
            callback(true)
            return
        }

        permissionCallback?.invoke(false)
        permissionCallback = callback
        ActivityCompat.requestPermissions(activity, arrayOf(permission), REQUEST_RECORD_AUDIO)
    }

    fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (requestCode == REQUEST_RECORD_AUDIO) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            permissionCallback?.invoke(granted)
            permissionCallback = null
        }
    }

    private fun determineAudioSources(): MutableList<Int> {
        val sources = mutableListOf<Int>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            val unprocessedSupported =
                audioManager?.getProperty(AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED)
            if (unprocessedSupported == "true") {
                sources.add(MediaRecorder.AudioSource.UNPROCESSED)
            }
        }
        sources.add(MediaRecorder.AudioSource.MIC)
        sources.add(MediaRecorder.AudioSource.CAMCORDER)
        sources.add(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
        return sources.distinct().toMutableList()
    }

    private fun rmsToVuLevel(rms: Double): Double {
        if (rms <= 1e-6) {
            return 0.0
        }
        val clamped = rms.coerceIn(1e-6, 1.0)
        val decibels = 20.0 * log10(clamped)
        val normalized = ((decibels + 60.0) / 60.0).coerceIn(0.0, 1.0)
        return sqrt(normalized).coerceIn(0.0, 1.0)
    }

    private fun resetSilenceCounter() {
        silenceFrameCounter = 0
    }

    private fun registerSilenceFrame(): Boolean {
        silenceFrameCounter++
        return silenceFrameCounter >= SILENT_FRAME_THRESHOLD
    }

    private fun resetClipCounter() {
        clipFrameCounter = 0
    }

    private fun registerClipFrame(): Boolean {
        clipFrameCounter++
        return clipFrameCounter >= CLIP_FRAME_THRESHOLD
    }

    private fun trySwitchRecorder(
        currentRecorder: AudioRecord,
        bufferSize: Int,
        reason: String
    ): AudioRecord? {
        try {
            currentRecorder.stop()
        } catch (ex: Exception) {
            Log.w(TAG, "Failed stopping AudioRecord during $reason recovery", ex)
        }
        currentRecorder.release()

        val replacement = obtainRecorder(bufferSize, skipCurrent = true)
        if (replacement == null) {
            Log.e(TAG, "Unable to recover from $reason frames; aborting recording")
            sendStatus(
                "voiceMemo",
                "error",
                mapOf("code" to "${reason}_reinit_failed")
            )
            recordingActive = false
            return null
        }
        try {
            replacement.startRecording()
        } catch (ex: Exception) {
            Log.e(TAG, "Failed to start replacement AudioRecord after $reason", ex)
            replacement.release()
            sendStatus(
                "voiceMemo",
                "error",
                mapOf("code" to "${reason}_reinit_start_failed")
            )
            recordingActive = false
            return null
        }
        if (replacement.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
            Log.e(TAG, "Replacement recorder not recording (state=${replacement.recordingState}) during $reason recovery")
            replacement.release()
            sendStatus(
                "voiceMemo",
                "error",
                mapOf("code" to "${reason}_reinit_state_failed")
            )
            recordingActive = false
            return null
        }
        Log.d(TAG, "Switched recorder to source index $currentAudioSourceIndex for $reason recovery")
        audioRecord = replacement
        return replacement
    }

    private fun sendStatus(type: String, status: String, payload: Map<String, Any?>? = null) {
        val event = HashMap<String, Any?>()
        event["type"] = type
        event["status"] = status
        payload?.let { event.putAll(it) }
        events?.success(event)
    }

    private fun cleanupRecordingResources(deleteFile: Boolean) {
        recordingActive = false
        try {
            recordingFuture?.cancel(true)
        } catch (_: Exception) {
        }
        recordingExecutor?.shutdownNow()
        recordingExecutor = null
        recordingFuture = null

        try {
            audioRecord?.stop()
        } catch (_: Exception) {
        }
        audioRecord?.release()
        audioRecord = null

        try {
            recordingFileHandle?.close()
        } catch (_: Exception) {
        }
        recordingFileHandle = null

        if (deleteFile) {
            recordingFile?.let {
                if (it.exists()) {
                    it.delete()
                }
            }
            recordingFile = null
        }

        recordingBytes = 0
        lastBufferLevel = 0.0
        lastVuLevel = 0.0
        lastAmplitudeLevel = 0.0
        lastPeakLevel = 0.0
    }

    private fun writeWavHeader(
        file: RandomAccessFile,
        totalAudioLen: Long,
        sampleRate: Int,
        channels: Int,
        bitsPerSample: Int
    ) {
        val totalDataLen = totalAudioLen + 36
        val byteRate = sampleRate * channels * bitsPerSample / 8

        file.seek(0)
        file.writeBytes("RIFF")
        file.writeIntLE(totalDataLen.toInt())
        file.writeBytes("WAVE")
        file.writeBytes("fmt ")
        file.writeIntLE(16)
        file.writeShortLE(1) // PCM
        file.writeShortLE(channels)
        file.writeIntLE(sampleRate)
        file.writeIntLE(byteRate)
        file.writeShortLE(channels * bitsPerSample / 8)
        file.writeShortLE(bitsPerSample)
        file.writeBytes("data")
        file.writeIntLE(totalAudioLen.toInt())
        file.seek(file.length())
    }

    private fun RandomAccessFile.writeIntLE(value: Int) {
        write(byteArrayOf(
            (value and 0xFF).toByte(),
            ((value shr 8) and 0xFF).toByte(),
            ((value shr 16) and 0xFF).toByte(),
            ((value shr 24) and 0xFF).toByte()
        ))
    }

    private fun RandomAccessFile.writeShortLE(value: Int) {
        write(byteArrayOf(
            (value and 0xFF).toByte(),
            ((value shr 8) and 0xFF).toByte()
        ))
    }
}
