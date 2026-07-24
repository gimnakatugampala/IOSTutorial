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

@available(iOS 26.0, *)
@MainActor
final class VoiceCommandService: NSObject, ObservableObject {

    @Published private(set) var isListening = false
    @Published private(set) var liveTranscript = ""
    @Published private(set) var isPreparing = false

    private let audioEngine = AVAudioEngine()

    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?

    private var inputContinuation:
        AsyncStream<AnalyzerInput>.Continuation?

    private var resultsTask: Task<Void, Never>?
    private var startupTask: Task<Void, Never>?

    private var audioConverter: SpeechAudioConverter?

    private var initialSpeechTimer: Timer?
    private var silenceTimer: Timer?
    private var maximumDurationWorkItem: DispatchWorkItem?

    private var completion: ((String?) -> Void)?

    private var isStarting = false
    private var tapInstalled = false
    private var didFinish = true
    private var activeSessionID: UUID?

    private let initialSpeechTimeout: TimeInterval = 5.0
    private let silenceTimeout: TimeInterval = 2.0
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

    // MARK: - Public methods

    func listenOnce(
        completion: @escaping (String?) -> Void
    ) {
        guard !isStarting, !isListening else {
            print("⚠️ Speech recognition is already active.")
            return
        }

        guard Self.hasPermission() else {
            print("❌ Microphone or speech permission is unavailable.")
            completion(nil)
            return
        }

        cleanUpCurrentSession()

        let sessionID = UUID()

        activeSessionID = sessionID
        self.completion = completion

        didFinish = false
        isStarting = true
        isPreparing = true
        isListening = false
        liveTranscript = ""

        startupTask = Task { [weak self] in
            guard let self else {
                return
            }

            await self.startSpeechAnalyzer(
                sessionID: sessionID
            )
        }
    }

    func stopListening() {
        startupTask?.cancel()
        startupTask = nil

        guard let sessionID = activeSessionID else {
            cleanUpCurrentSession()
            return
        }

        finish(
            with: nil,
            sessionID: sessionID,
            notifyCaller: false
        )
    }

    // MARK: - SpeechAnalyzer setup

    private func startSpeechAnalyzer(
        sessionID: UUID
    ) async {
        do {
            guard
                activeSessionID == sessionID,
                !Task.isCancelled
            else {
                return
            }

            guard let supportedLocale =
                    await SpeechTranscriber.supportedLocale(
                        equivalentTo: Locale(
                            identifier: "en-US"
                        )
                    )
            else {
                failToStart(
                    sessionID: sessionID,
                    message: "SpeechAnalyzer does not support en-US."
                )
                return
            }

            print(
                "✅ Supported locale:",
                supportedLocale.identifier
            )

            /*
             Reserve the locale before requesting the asset download.
             Without this, AssetInventory can report that the app isn't
             subscribed to transcription.en.
             */
            let wasReserved =
                try await AssetInventory.reserve(
                    locale: supportedLocale
                )

            if wasReserved {
                print(
                    "✅ Reserved speech locale:",
                    supportedLocale.identifier
                )
            } else {
                print(
                    "✅ Speech locale was already reserved:",
                    supportedLocale.identifier
                )
            }

            guard
                activeSessionID == sessionID,
                !Task.isCancelled
            else {
                return
            }

            let transcriber = SpeechTranscriber(
                locale: supportedLocale,
                transcriptionOptions: [],
                reportingOptions: [.volatileResults],
                attributeOptions: []
            )

            print("⏳ Checking SpeechAnalyzer assets...")

            let assetStatus =
                await AssetInventory.status(
                    forModules: [transcriber]
                )

            print("Speech asset status:", assetStatus)

            switch assetStatus {
            case .installed:
                print(
                    "✅ SpeechAnalyzer assets already installed."
                )

            case .supported, .downloading:
                if let installationRequest =
                    try await AssetInventory
                        .assetInstallationRequest(
                            supporting: [transcriber]
                        ) {
                    print(
                        "⬇️ Downloading SpeechAnalyzer assets..."
                    )

                    try await installationRequest
                        .downloadAndInstall()

                    print(
                        "✅ SpeechAnalyzer assets installed."
                    )
                }

            case .unsupported:
                failToStart(
                    sessionID: sessionID,
                    message: "English SpeechAnalyzer assets are unsupported."
                )
                return

            @unknown default:
                failToStart(
                    sessionID: sessionID,
                    message: "Unknown SpeechAnalyzer asset status."
                )
                return
            }

            guard
                activeSessionID == sessionID,
                !Task.isCancelled
            else {
                return
            }

            guard let analyzerFormat =
                    await SpeechAnalyzer
                        .bestAvailableAudioFormat(
                            compatibleWith: [transcriber]
                        )
            else {
                failToStart(
                    sessionID: sessionID,
                    message: "No compatible SpeechAnalyzer audio format."
                )
                return
            }

            print(
                "✅ Analyzer format:",
                analyzerFormat.sampleRate,
                "Hz,",
                analyzerFormat.channelCount,
                "channel(s)"
            )

            let analyzer = SpeechAnalyzer(
                modules: [transcriber]
            )

            let stream =
                AsyncStream.makeStream(
                    of: AnalyzerInput.self
                )

            let inputSequence = stream.stream
            let inputContinuation = stream.continuation

            self.transcriber = transcriber
            self.analyzer = analyzer
            self.inputContinuation = inputContinuation

            startReadingResults(
                from: transcriber,
                sessionID: sessionID
            )

            try configureAudioSession()

            let inputNode = audioEngine.inputNode

            let microphoneFormat =
                inputNode.outputFormat(forBus: 0)

            guard
                microphoneFormat.sampleRate > 0,
                microphoneFormat.channelCount > 0
            else {
                failToStart(
                    sessionID: sessionID,
                    message: "The microphone returned an invalid audio format."
                )
                return
            }

            let converter = try SpeechAudioConverter(
                inputFormat: microphoneFormat,
                outputFormat: analyzerFormat
            )

            audioConverter = converter

            if tapInstalled {
                inputNode.removeTap(onBus: 0)
                tapInstalled = false
            }

            /*
             Install exactly one microphone tap.
             AsyncStream.Continuation is a struct, so it is captured strongly.
             */
            inputNode.installTap(
                onBus: 0,
                bufferSize: 1024,
                format: microphoneFormat
            ) { buffer, _ in
                do {
                    let convertedBuffer =
                        try converter.convert(buffer)

                    inputContinuation.yield(
                        AnalyzerInput(
                            buffer: convertedBuffer
                        )
                    )
                } catch {
                    print(
                        "❌ Audio conversion failed:",
                        error.localizedDescription
                    )
                }
            }

            tapInstalled = true

            /*
             Initialize the analyzer before starting the audio engine.
             */
            try await analyzer.start(
                inputSequence: inputSequence
            )

            guard
                activeSessionID == sessionID,
                !Task.isCancelled
            else {
                await analyzer.cancelAndFinishNow()
                return
            }

            audioEngine.prepare()
            try audioEngine.start()

            guard activeSessionID == sessionID else {
                await analyzer.cancelAndFinishNow()
                return
            }

            isStarting = false
            isPreparing = false
            isListening = true

            print("🎙️ SpeechAnalyzer is listening.")

            armInitialSpeechTimer(
                sessionID: sessionID
            )

            armMaximumDurationTimer(
                sessionID: sessionID
            )
        } catch {
            let nsError = error as NSError

            print("❌ SpeechAnalyzer startup error")
            print("Domain:", nsError.domain)
            print("Code:", nsError.code)
            print(
                "Description:",
                nsError.localizedDescription
            )
            print("Details:", nsError.userInfo)

            failToStart(
                sessionID: sessionID,
                message: nsError.localizedDescription
            )
        }
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [
                .defaultToSpeaker,
                .allowBluetooth
            ]
        )

        try session.setActive(
            true,
            options: .notifyOthersOnDeactivation
        )
    }

    // MARK: - Results

    private func startReadingResults(
        from transcriber: SpeechTranscriber,
        sessionID: UUID
    ) {
        resultsTask?.cancel()

        resultsTask = Task { [weak self] in
            do {
                for try await result in transcriber.results {
                    guard !Task.isCancelled else {
                        return
                    }

                    guard let self else {
                        return
                    }

                    guard
                        self.activeSessionID == sessionID,
                        !self.didFinish
                    else {
                        return
                    }

                    let transcript =
                        String(result.text.characters)
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )

                    guard !transcript.isEmpty else {
                        continue
                    }

                    self.liveTranscript = transcript

                    print("🎤 Heard:", transcript)

                    self.initialSpeechTimer?.invalidate()
                    self.initialSpeechTimer = nil

                    self.armSilenceTimer(
                        sessionID: sessionID
                    )

                    if result.isFinal {
                        self.finish(
                            with: transcript,
                            sessionID: sessionID
                        )
                        return
                    }
                }
            } catch {
                guard let self else {
                    return
                }

                guard
                    self.activeSessionID == sessionID,
                    !self.didFinish
                else {
                    return
                }

                let nsError = error as NSError

                print("❌ SpeechAnalyzer result error")
                print("Domain:", nsError.domain)
                print("Code:", nsError.code)
                print(
                    "Description:",
                    nsError.localizedDescription
                )

                self.finish(
                    with: self.liveTranscript.isEmpty
                        ? nil
                        : self.liveTranscript,
                    sessionID: sessionID
                )
            }
        }
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
            guard let self else {
                return
            }

            guard
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
            guard let self else {
                return
            }

            guard
                self.activeSessionID == sessionID,
                !self.didFinish
            else {
                return
            }

            print(
                "✅ Speech finished:",
                self.liveTranscript
            )

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
            guard let self else {
                return
            }

            guard
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
        activeSessionID = nil

        initialSpeechTimer?.invalidate()
        initialSpeechTimer = nil

        silenceTimer?.invalidate()
        silenceTimer = nil

        maximumDurationWorkItem?.cancel()
        maximumDurationWorkItem = nil

        startupTask?.cancel()
        startupTask = nil

        let handler = completion
        completion = nil

        stopAudioEngine()

        inputContinuation?.finish()
        inputContinuation = nil

        resultsTask?.cancel()
        resultsTask = nil

        cancelAnalyzer()

        analyzer = nil
        transcriber = nil
        audioConverter = nil

        isStarting = false
        isPreparing = false
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
            print("✅ Final transcript:", trimmed)
            handler?(trimmed)
        } else {
            print("⚠️ No transcript received.")
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

        startupTask?.cancel()
        startupTask = nil

        let handler = completion
        completion = nil

        stopAudioEngine()

        inputContinuation?.finish()
        inputContinuation = nil

        resultsTask?.cancel()
        resultsTask = nil

        cancelAnalyzer()

        analyzer = nil
        transcriber = nil
        audioConverter = nil

        isStarting = false
        isPreparing = false
        isListening = false

        handler?(nil)
    }

    // MARK: - Cleanup

    private func cleanUpCurrentSession() {
        activeSessionID = nil
        didFinish = true

        startupTask?.cancel()
        startupTask = nil

        initialSpeechTimer?.invalidate()
        initialSpeechTimer = nil

        silenceTimer?.invalidate()
        silenceTimer = nil

        maximumDurationWorkItem?.cancel()
        maximumDurationWorkItem = nil

        inputContinuation?.finish()
        inputContinuation = nil

        resultsTask?.cancel()
        resultsTask = nil

        cancelAnalyzer()

        analyzer = nil
        transcriber = nil
        audioConverter = nil
        completion = nil

        stopAudioEngine()

        isStarting = false
        isPreparing = false
        isListening = false
    }

    private func cancelAnalyzer() {
        guard let analyzer else {
            return
        }

        Task {
            await analyzer.cancelAndFinishNow()
        }
    }

    private func stopAudioEngine() {
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

// MARK: - Audio converter

private final class SpeechAudioConverter:
    @unchecked Sendable {

    private let converter: AVAudioConverter
    private let outputFormat: AVAudioFormat
    private let lock = NSLock()

    init(
        inputFormat: AVAudioFormat,
        outputFormat: AVAudioFormat
    ) throws {
        guard let converter = AVAudioConverter(
            from: inputFormat,
            to: outputFormat
        ) else {
            throw SpeechAnalyzerServiceError
                .converterCreationFailed
        }

        converter.primeMethod = .none

        self.converter = converter
        self.outputFormat = outputFormat
    }

    func convert(
        _ inputBuffer: AVAudioPCMBuffer
    ) throws -> AVAudioPCMBuffer {
        lock.lock()
        defer {
            lock.unlock()
        }

        if inputBuffer.format == outputFormat {
            return inputBuffer
        }

        let ratio =
            outputFormat.sampleRate /
            inputBuffer.format.sampleRate

        let expectedFrames =
            Double(inputBuffer.frameLength) * ratio

        let outputCapacity =
            AVAudioFrameCount(
                expectedFrames.rounded(.up)
            ) + 1024

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: outputCapacity
        ) else {
            throw SpeechAnalyzerServiceError
                .outputBufferCreationFailed
        }

        var suppliedInput = false
        var conversionError: NSError?

        let status = converter.convert(
            to: outputBuffer,
            error: &conversionError
        ) { _, inputStatus in
            if suppliedInput {
                inputStatus.pointee = .noDataNow
                return nil
            }

            suppliedInput = true
            inputStatus.pointee = .haveData

            return inputBuffer
        }

        if let conversionError {
            throw conversionError
        }

        guard status != .error else {
            throw SpeechAnalyzerServiceError
                .conversionFailed
        }

        return outputBuffer
    }
}

// MARK: - Errors

private enum SpeechAnalyzerServiceError:
    LocalizedError {

    case converterCreationFailed
    case outputBufferCreationFailed
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .converterCreationFailed:
            return "Unable to create the audio converter."

        case .outputBufferCreationFailed:
            return "Unable to create the converted audio buffer."

        case .conversionFailed:
            return "The microphone audio could not be converted."
        }
    }
}
