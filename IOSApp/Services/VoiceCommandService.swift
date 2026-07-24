//
//  VoiceCommandService.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-24.
//

import Foundation
import Speech
import AVFoundation
import Combine

final class VoiceCommandService: NSObject, ObservableObject {

    @Published private(set) var isListening = false
    @Published private(set) var liveTranscript = ""

    private let audioEngine = AVAudioEngine()

    private let speechRecognizer =
        SFSpeechRecognizer(
            locale: Locale(identifier: "en-US")
        )

    private var recognitionRequest:
        SFSpeechAudioBufferRecognitionRequest?

    private var recognitionTask:
        SFSpeechRecognitionTask?

    private var initialSpeechTimer: Timer?
    private var silenceTimer: Timer?
    private var maximumDurationWorkItem: DispatchWorkItem?

    private var completion: ((String?) -> Void)?

    private var isStarting = false
    private var tapInstalled = false
    private var didFinish = true
    private var activeSessionID: UUID?

    // Time allowed before the user starts talking.
    private let initialSpeechTimeout: TimeInterval = 5.0

    // Silence allowed after speech begins.
    private let silenceTimeout: TimeInterval = 2.0

    // Absolute maximum listening time.
    private let maximumListenDuration: TimeInterval = 12.0

    // MARK: - Permissions

    static func requestPermissions(
        completion: @escaping (Bool) -> Void
    ) {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
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
        /*
         Do not call completion(nil) when another listening request is
         already starting. Doing that would cause QuizRushView to say
         "Sorry" even though the first request is still listening.
         */
        guard !isStarting, !isListening else {
            print("⚠️ Microphone is already starting or listening.")
            return
        }

        guard Self.hasPermission() else {
            print("❌ Microphone or speech permission is unavailable.")
            completion(nil)
            return
        }

        guard
            let recognizer = speechRecognizer,
            recognizer.isAvailable
        else {
            print("❌ Speech recognizer is unavailable.")
            completion(nil)
            return
        }

        /*
         Remove anything left by an older listening session before marking
         this new session as active.
         */
        invalidateCurrentSession()
        tearDownAudio()

        isStarting = true
        didFinish = false
        liveTranscript = ""
        self.completion = completion

        let sessionID = UUID()
        activeSessionID = sessionID

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [
                    .defaultToSpeaker,
                    .allowBluetooth
                ]
            )

            try audioSession.setActive(
                true,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            failToStart(
                sessionID: sessionID,
                message: "Audio session error: \(error.localizedDescription)"
            )
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .confirmation

        /*
         Do not force requiresOnDeviceRecognition. Allow iOS to select
         whichever recognition method is currently available.
         */
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard
            format.sampleRate > 0,
            format.channelCount > 0
        else {
            failToStart(
                sessionID: sessionID,
                message: "The microphone returned an invalid audio format."
            )
            return
        }

        /*
         There must only ever be one tap on bus 0.
         */
        if tapInstalled {
            inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format
        ) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        tapInstalled = true

        /*
         Start the recognition task before starting the audio engine so the
         first microphone buffers are not missed.
         */
        recognitionTask = recognizer.recognitionTask(
            with: request
        ) { [weak self] result, error in
            DispatchQueue.main.async {
                guard
                    let self,
                    self.activeSessionID == sessionID,
                    !self.didFinish
                else {
                    return
                }

                if let result {
                    let transcript =
                        result.bestTranscription.formattedString

                    self.liveTranscript = transcript

                    print("🎤 Heard: \(transcript)")

                    let trimmed =
                        transcript.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )

                    if !trimmed.isEmpty {
                        /*
                         Speech has started. Stop the initial waiting timer
                         and use the post-speech silence timer instead.
                         */
                        self.initialSpeechTimer?.invalidate()
                        self.initialSpeechTimer = nil
                        self.armSilenceTimer(
                            sessionID: sessionID
                        )
                    }

                    if result.isFinal {
                        self.finish(
                            with: transcript,
                            sessionID: sessionID
                        )
                        return
                    }
                }

                if let error {
                    print(
                        "❌ Speech-recognition error:",
                        error.localizedDescription
                    )

                    /*
                     If partial speech was already received, use it even if
                     the recognizer subsequently reports an error.
                     */
                    self.finish(
                        with: self.liveTranscript.isEmpty
                            ? nil
                            : self.liveTranscript,
                        sessionID: sessionID
                    )
                }
            }
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            failToStart(
                sessionID: sessionID,
                message: "Audio engine error: \(error.localizedDescription)"
            )
            return
        }

        guard activeSessionID == sessionID else {
            tearDownAudio()
            return
        }

        isStarting = false
        isListening = true

        print("🎙️ Microphone started. Waiting for speech.")

        armInitialSpeechTimer(
            sessionID: sessionID
        )

        armMaximumDurationTimer(
            sessionID: sessionID
        )
    }

    func stopListening() {
        guard let sessionID = activeSessionID else {
            tearDownAudio()
            isStarting = false
            isListening = false
            return
        }

        finish(
            with: nil,
            sessionID: sessionID,
            notifyCaller: false
        )
    }

    // MARK: - Timers

    private func armInitialSpeechTimer(
        sessionID: UUID
    ) {
        initialSpeechTimer?.invalidate()

        initialSpeechTimer = Timer.scheduledTimer(
            withTimeInterval: initialSpeechTimeout,
            repeats: false
        ) { [weak self] _ in
            guard
                let self,
                self.activeSessionID == sessionID,
                !self.didFinish
            else {
                return
            }

            print("⚠️ No speech detected before timeout.")

            self.finish(
                with: self.liveTranscript.isEmpty
                    ? nil
                    : self.liveTranscript,
                sessionID: sessionID
            )
        }
    }

    private func armSilenceTimer(
        sessionID: UUID
    ) {
        silenceTimer?.invalidate()

        silenceTimer = Timer.scheduledTimer(
            withTimeInterval: silenceTimeout,
            repeats: false
        ) { [weak self] _ in
            guard
                let self,
                self.activeSessionID == sessionID,
                !self.didFinish
            else {
                return
            }

            print("✅ Speech finished: \(self.liveTranscript)")

            self.finish(
                with: self.liveTranscript,
                sessionID: sessionID
            )
        }
    }

    private func armMaximumDurationTimer(
        sessionID: UUID
    ) {
        maximumDurationWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard
                let self,
                self.activeSessionID == sessionID,
                !self.didFinish
            else {
                return
            }

            print("⚠️ Maximum listening duration reached.")

            self.finish(
                with: self.liveTranscript.isEmpty
                    ? nil
                    : self.liveTranscript,
                sessionID: sessionID
            )
        }

        maximumDurationWorkItem = workItem

        DispatchQueue.main.asyncAfter(
            deadline: .now() + maximumListenDuration,
            execute: workItem
        )
    }

    // MARK: - Finish

    private func finish(
        with transcript: String?,
        sessionID: UUID,
        notifyCaller: Bool = true
    ) {
        guard
            activeSessionID == sessionID,
            !didFinish
        else {
            return
        }

        didFinish = true

        /*
         Invalidate the session before cancelling recognition. Cancellation
         can invoke the recognition callback again, but that callback will
         now see that its session is no longer active.
         */
        activeSessionID = nil

        initialSpeechTimer?.invalidate()
        initialSpeechTimer = nil

        silenceTimer?.invalidate()
        silenceTimer = nil

        maximumDurationWorkItem?.cancel()
        maximumDurationWorkItem = nil

        let handler = completion
        completion = nil

        tearDownAudio()

        isStarting = false
        isListening = false

        guard notifyCaller else {
            return
        }

        let trimmed = transcript?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()

        if let trimmed, !trimmed.isEmpty {
            print("✅ Final transcript: \(trimmed)")
            handler?(trimmed)
        } else {
            print("⚠️ No transcript was received.")
            handler?(nil)
        }
    }

    // MARK: - Failure

    private func failToStart(
        sessionID: UUID,
        message: String
    ) {
        guard activeSessionID == sessionID else {
            return
        }

        print("❌ \(message)")

        didFinish = true
        activeSessionID = nil

        initialSpeechTimer?.invalidate()
        initialSpeechTimer = nil

        silenceTimer?.invalidate()
        silenceTimer = nil

        maximumDurationWorkItem?.cancel()
        maximumDurationWorkItem = nil

        let handler = completion
        completion = nil

        tearDownAudio()

        isStarting = false
        isListening = false

        handler?(nil)
    }

    // MARK: - Cleanup

    private func invalidateCurrentSession() {
        activeSessionID = nil
        didFinish = true

        initialSpeechTimer?.invalidate()
        initialSpeechTimer = nil

        silenceTimer?.invalidate()
        silenceTimer = nil

        maximumDurationWorkItem?.cancel()
        maximumDurationWorkItem = nil

        completion = nil
    }

    private func tearDownAudio() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }

        audioEngine.reset()
    }
}
