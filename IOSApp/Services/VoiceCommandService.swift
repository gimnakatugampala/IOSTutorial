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
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private var completion: ((String?) -> Void)?
    private var didFinish = false

    private let silenceTimeout: TimeInterval = 1.3
    private let maxListenDuration: TimeInterval = 8.0

    // MARK: - Permissions

    static func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            guard speechStatus == .authorized else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            AVAudioApplication.requestRecordPermission { micGranted in
                DispatchQueue.main.async { completion(micGranted) }
            }
        }
    }

    static func hasPermission() -> Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized &&
            AVAudioApplication.shared.recordPermission == .granted
    }

    // MARK: - Listening

    func listenOnce(completion: @escaping (String?) -> Void) {
        guard !isListening else { completion(nil); return }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            completion(nil)
            return
        }

        // Defensively tear down any leftover tap/engine state from a
        // previous run before touching the session again — installing a
        // tap on a node that still thinks it has one from earlier is
        // another path to a degenerate/mismatched format.
        cleanUpAudio()

        let session = AVAudioSession.sharedInstance()
        do {
            // .playAndRecord (not .record) is what makes .duckOthers valid,
            // and it's also the category QuizVoiceService now uses for
            // playback — so listening no longer requires a category switch.
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.duckOthers, .defaultToSpeaker, .allowBluetooth]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            completion(nil)
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request
        self.completion = completion
        didFinish = false
        liveTranscript = ""

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Guard against exactly the crash you hit: if the session handed us
        // a degenerate format, bail out cleanly instead of letting
        // installTap crash the app.
        guard format.sampleRate > 0, format.channelCount > 0 else {
            cleanUpAudio()
            completion(nil)
            return
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            cleanUpAudio()
            completion(nil)
            return
        }

        isListening = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let result {
                    self.liveTranscript = result.bestTranscription.formattedString
                    self.armSilenceTimer()
                    if result.isFinal {
                        self.finish(with: self.liveTranscript)
                    }
                }
                if error != nil {
                    self.finish(with: self.liveTranscript.isEmpty ? nil : self.liveTranscript)
                }
            }
        }

        armSilenceTimer()
        DispatchQueue.main.asyncAfter(deadline: .now() + maxListenDuration) { [weak self] in
            guard let self else { return }
            self.finish(with: self.liveTranscript.isEmpty ? nil : self.liveTranscript)
        }
    }

    func stopListening() {
        finish(with: nil, notifyCaller: false)
    }

    // MARK: - Private

    private func armSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.finish(with: self.liveTranscript)
        }
    }

    private func finish(with transcript: String?, notifyCaller: Bool = true) {
        guard !didFinish else { return }
        didFinish = true

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
        let trimmed = transcript?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        handler?((trimmed?.isEmpty ?? true) ? nil : trimmed)
    }

    private func cleanUpAudio() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.reset()
    }
}
