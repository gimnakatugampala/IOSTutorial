//
//  VoiceCommandService.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-24.
//
///
//  VoiceCommandService.swift
//  IOSApp
//
//  Speech-to-text wrapper for the Quiz Rush voice-control feature. Turns a
//  single short burst of speech into text.
//
//  Deliberately "listen once" rather than continuous background listening —
//  see the note in listenOnce() for why.
//
//  IMPORTANT: uses .playAndRecord for the session category (not .record).
//  QuizVoiceService (text-to-speech) and this class (speech-to-text) used
//  to configure two DIFFERENT categories and swap between them every turn,
//  which is a known source of "IsFormatSampleRateAndChannelCountValid"
//  crashes — repeatedly changing category mid-session can leave the input
//  node's format temporarily invalid (0 Hz / 0 channels). Standardizing
//  both services on .playAndRecord means the category itself never has to
//  change between speaking and listening, only who's "active" does.
import Foundation
import Speech
import AVFoundation
import Combine

final class VoiceCommandService: NSObject, ObservableObject {

    @Published private(set) var isListening = false
    @Published private(set) var liveTranscript = ""

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer =
        SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private var recognitionRequest:
        SFSpeechAudioBufferRecognitionRequest?

    private var recognitionTask: SFSpeechRecognitionTask?
    private var initialSpeechTimer: Timer?
    private var silenceTimer: Timer?
    private var completion: ((String?) -> Void)?
    private var didFinish = false

    // Give the user enough time to begin speaking.
    private let initialSpeechTimeout: TimeInterval = 4.0

    // Stop after the user has finished speaking.
    private let silenceTimeout: TimeInterval = 2.0

    // Absolute maximum listening duration.
    private let maxListenDuration: TimeInterval = 10.0

    // MARK: - Permissions

    static func requestPermissions(
        completion: @escaping (Bool) -> Void
    ) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            guard speechStatus == .authorized else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            AVAudioApplication.requestRecordPermission { micGranted in
                DispatchQueue.main.async {
                    completion(micGranted)
                }
            }
        }
    }

    static func hasPermission() -> Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized &&
        AVAudioApplication.shared.recordPermission == .granted
    }

    // MARK: - Listening

    func listenOnce(
        completion: @escaping (String?) -> Void
    ) {
        guard !isListening else {
            completion(nil)
            return
        }

        guard
            let recognizer = speechRecognizer,
            recognizer.isAvailable
        else {
            completion(nil)
            return
        }

        cleanUpAudio()

        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [
                    .duckOthers,
                    .defaultToSpeaker,
                    .allowBluetooth
                ]
            )

            try session.setActive(
                true,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            print("Audio session error:", error)
            completion(nil)
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        // Do not force on-device recognition. Let iOS select the
        // most reliable available recognition method.
        recognitionRequest = request
        self.completion = completion
        didFinish = false
        liveTranscript = ""

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard
            format.sampleRate > 0,
            format.channelCount > 0
        else {
            cleanUpAudio()
            completion(nil)
            return
        }

        inputNode.removeTap(onBus: 0)

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format
        ) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("Audio engine error:", error)
            cleanUpAudio()
            completion(nil)
            return
        }

        isListening = true

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format
        ) { buffer, _ in
            request.append(buffer)
        }

        recognitionTask = recognizer.recognitionTask(
            with: request
        ) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let result {
                    let transcript =
                        result.bestTranscription.formattedString

                    print("🎤 Heard:", transcript)

                    self.liveTranscript = transcript

                    let trimmed = transcript.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    if !trimmed.isEmpty {
                        self.initialSpeechTimer?.invalidate()
                        self.initialSpeechTimer = nil
                        self.armSilenceTimer()
                    }

                    if result.isFinal {
                        self.finish(with: transcript)
                        return
                    }
                }

                if let error {
                    print("❌ Speech recognition error:", error.localizedDescription)

                    self.finish(
                        with: self.liveTranscript.isEmpty
                            ? nil
                            : self.liveTranscript
                    )
                }
            }
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isListening = true
            print("🎙️ Microphone started")
        } catch {
            print("❌ Audio engine error:", error.localizedDescription)
            cleanUpAudio()
            completion(nil)
            return
        }

        armInitialSpeechTimer()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + maxListenDuration
        ) { [weak self] in
            guard let self else { return }

            self.finish(
                with: self.liveTranscript.isEmpty
                    ? nil
                    : self.liveTranscript
            )
        }
    }

    func stopListening() {
        finish(with: nil, notifyCaller: false)
    }

    // MARK: - Timers

    private func armInitialSpeechTimer() {
        initialSpeechTimer?.invalidate()

        initialSpeechTimer = Timer.scheduledTimer(
            withTimeInterval: initialSpeechTimeout,
            repeats: false
        ) { [weak self] _ in
            guard let self else { return }

            self.finish(
                with: self.liveTranscript.isEmpty
                    ? nil
                    : self.liveTranscript
            )
        }
    }

    private func armSilenceTimer() {
        silenceTimer?.invalidate()

        silenceTimer = Timer.scheduledTimer(
            withTimeInterval: silenceTimeout,
            repeats: false
        ) { [weak self] _ in
            guard let self else { return }

            self.finish(with: self.liveTranscript)
        }
    }

    // MARK: - Finish and cleanup

    private func finish(
        with transcript: String?,
        notifyCaller: Bool = true
    ) {
        guard !didFinish else { return }
        didFinish = true

        initialSpeechTimer?.invalidate()
        initialSpeechTimer = nil

        silenceTimer?.invalidate()
        silenceTimer = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        cleanUpAudio()
        isListening = false

        let handler = completion
        completion = nil

        guard notifyCaller else { return }

        let trimmed = transcript?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if trimmed?.isEmpty ?? true {
            handler?(nil)
        } else {
            handler?(trimmed)
        }
    }

    private func cleanUpAudio() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.reset()
    }
}
