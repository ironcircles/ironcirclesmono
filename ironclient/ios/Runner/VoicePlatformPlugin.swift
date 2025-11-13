import Flutter
import UIKit
import AVFoundation
import Speech

class VoicePlatformPlugin: NSObject, FlutterStreamHandler, SFSpeechRecognizerDelegate {
    private static let channelName = "com.ironcircles/voice_channel"
    private static let eventChannelName = "com.ironcircles/voice_events"
    private static let microphoneAllowedKey = "com.ironcircles.voiceMemo.microphoneAllowed"

    private weak var controller: FlutterViewController?
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    private var audioRecorder: AVAudioRecorder?
    private var recordingStartDate: Date?
    private var outputURL: URL?
    private var meterTimer: Timer?

    // Speech Recognition
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var partialSpeechResult: String = ""
    private var speechActive = false

    private let userDefaults = UserDefaults.standard

    init(controller: FlutterViewController) {
        self.controller = controller
        super.init()
    }

    func start() {
        guard let messenger = controller?.binaryMessenger else {
            NSLog("[VoicePlatformPlugin] Unable to start: binaryMessenger not available")
            return
        }

        methodChannel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
        methodChannel?.setMethodCallHandler(handleMethodCall(_:result:))

        eventChannel = FlutterEventChannel(name: Self.eventChannelName, binaryMessenger: messenger)
        eventChannel?.setStreamHandler(self)

        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self

        NSLog("[VoicePlatformPlugin] Voice platform channel initialised")
    }

    func stop() {
        methodChannel?.setMethodCallHandler(nil)
        methodChannel = nil
        eventChannel?.setStreamHandler(nil)
        eventChannel = nil
        eventSink = nil
        cleanupRecorder()
        cancelSpeechRecognition()
        NSLog("[VoicePlatformPlugin] Voice platform channel disposed")
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: FlutterResult) {
        switch call.method {
        case "startVoiceMemo":
            startVoiceMemo(result: result)
        case "stopVoiceMemo":
            stopVoiceMemo(result: result)
        case "cancelVoiceMemo":
            cancelVoiceMemo(result: result)
        case "startVoiceToText":
            startVoiceToText(result: result)
        case "stopVoiceToText":
            stopVoiceToText(result: result)
        case "checkMicrophone":
            NSLog("[VoicePlatformPlugin] checkMicrophone() requested")
            let args = call.arguments as? [String: Any]
            let forcePrompt = args?["forcePrompt"] as? Bool ?? false
            handleCheckMicrophone(forcePrompt: forcePrompt, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startVoiceMemo(result: FlutterResult) {
        requestMicrophonePermission(forcePrompt: true) { [weak self] granted in
            guard let self = self else { return }
            if !granted {
                result(FlutterError(code: "mic_permission", message: "Microphone permission not granted", details: nil))
                return
            }

            if self.audioRecorder != nil {
                result(FlutterError(code: "already_recording", message: "Voice memo already in progress", details: nil))
                return
            }

            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
                try session.setActive(true)

                let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let fileURL = directory.appendingPathComponent("voice_memo_\(Int(Date().timeIntervalSince1970 * 1000)).m4a")

                let settings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                    AVEncoderBitRateKey: 128000
                ]

                let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
                recorder.isMeteringEnabled = true
                recorder.record()

                self.audioRecorder = recorder
                self.recordingStartDate = Date()
                self.outputURL = fileURL
                self.startMeterUpdates()

                self.sendStatus(type: "voiceMemo", status: "started", payload: ["path": fileURL.path])
                result(["path": fileURL.path])
            } catch {
                NSLog("[VoicePlatformPlugin] Failed to start voice memo: \(error)")
                self.cleanupRecorder(deleteFile: true)
                result(FlutterError(code: "start_failed", message: error.localizedDescription, details: nil))
            }
        }
    }

    private func stopVoiceMemo(result: FlutterResult) {
        guard let recorder = audioRecorder else {
            result(FlutterError(code: "not_recording", message: "No active voice memo", details: nil))
            return
        }

        recorder.stop()
        stopMeterUpdates(sendZero: true)
        let duration = Date().timeIntervalSince(recordingStartDate ?? Date())
        let path = outputURL?.path

        cleanupRecorder(deleteFile: false)

        let response: [String: Any?] = [
            "durationMs": Int(duration * 1000),
            "path": path
        ]

        sendStatus(type: "voiceMemo", status: "stopped", payload: response)
        result(response)
    }

    private func cancelVoiceMemo(result: FlutterResult) {
        cleanupRecorder(deleteFile: true)
        stopMeterUpdates(sendZero: true)
        sendStatus(type: "voiceMemo", status: "cancelled")
        result(nil)
    }

    private func cleanupRecorder(deleteFile: Bool = false) {
        meterTimer?.invalidate()
        meterTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        recordingStartDate = nil

        if deleteFile, let url = outputURL {
            try? FileManager.default.removeItem(at: url)
        }
        outputURL = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            NSLog("[VoicePlatformPlugin] Error deactivating audio session: \(error)")
        }
    }

    private func startMeterUpdates() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()
            let level = self.normalizedPower(recorder.averagePower(forChannel: 0))
            self.sendStatus(type: "voiceMemo", status: "amplitude", payload: ["level": level])
        }
    }

    private func stopMeterUpdates(sendZero: Bool = false) {
        meterTimer?.invalidate()
        meterTimer = nil
        if sendZero {
            sendStatus(type: "voiceMemo", status: "amplitude", payload: ["level": 0.0])
        }
    }

    private func normalizedPower(_ power: Float) -> Double {
        guard power.isFinite else { return 0.0 }
        let minDb: Float = -55.0
        let clamped = max(power, minDb)
        let scaled = (clamped - minDb) / abs(minDb)
        return max(0.0, min(1.0, Double(scaled)))
    }

    private func beginSpeechRecognition(result: FlutterResult) {
        cancelSpeechRecognition()

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            result(FlutterError(code: "not_available", message: "Speech recognition not available", details: nil))
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            result(FlutterError(code: "session_failed", message: error.localizedDescription, details: nil))
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            result(FlutterError(code: "request_failed", message: "Unable to create recognition request", details: nil))
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            result(FlutterError(code: "engine_start_failed", message: error.localizedDescription, details: nil))
            return
        }

        speechActive = true
        sendStatus(type: "voiceToText", status: "started")

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                let payload: [String: Any] = [
                    "text": text,
                    "isFinal": result.isFinal
                ]
                self.sendStatus(type: "voiceToText", status: result.isFinal ? "final" : "partial", payload: payload)

                if result.isFinal {
                    self.stopSpeechRecognitionSession()
                }
            }

            if let error = error {
                self.sendStatus(type: "voiceToText", status: "error", payload: ["message": error.localizedDescription])
                self.stopSpeechRecognitionSession()
            }
        }

        result(nil)
    }

    private func stopVoiceToText(result: FlutterResult) {
        if !speechActive {
            result(FlutterError(code: "not_listening", message: "Speech recognition not active", details: nil))
            return
        }

        stopSpeechRecognitionSession()
        result(nil)
    }

    private func stopSpeechRecognitionSession() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            NSLog("[VoicePlatformPlugin] Error stopping audio session: \(error)")
        }

        speechActive = false
        sendStatus(type: "voiceToText", status: "stopped")
    }

    private func cancelSpeechRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    private func handleCheckMicrophone(forcePrompt: Bool, result: FlutterResult) {
        if forcePrompt {
            requestMicrophonePermission(forcePrompt: true) { granted in
                let payload: [String: Any] = ["available": granted]
                self.sendStatus(type: "microphone", status: "checked", payload: payload)
                result(payload)
            }
        } else {
            let granted = isMicrophonePermissionGranted()
            let payload: [String: Any] = ["available": granted]
            sendStatus(type: "microphone", status: "checked", payload: payload)
            result(payload)
        }
    }

    private func requestMicrophonePermission(forcePrompt: Bool, completion: @escaping (Bool) -> Void) {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            completion(true)
        case .denied:
            if forcePrompt {
                session.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            } else {
                completion(false)
            }
        case .undetermined:
            session.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }

    private func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }

    private func isMicrophonePermissionGranted() -> Bool {
        return AVAudioSession.sharedInstance().recordPermission == .granted
    }

    private func sendStatus(type: String, status: String, payload: [String: Any?]? = nil) {
        var event: [String: Any?] = [
            "type": type,
            "status": status
        ]
        if let payload = payload {
            event.merge(payload) { _, new in new }
        }
        eventSink?(event)
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        NSLog("[VoicePlatformPlugin] Event listener attached")
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        NSLog("[VoicePlatformPlugin] Event listener detached")
        return nil
    }
}
