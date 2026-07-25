//
//  QuizVoiceService.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-18.
////
//  Lightweight wrapper around AVSpeechSynthesizer so Quiz Rush can read each
//  question and its answer choices aloud — primarily for blind/low-vision
//  players using VoiceOver, but works for anyone with the speaker button.
//
//  No extra Info.plist permission entries are needed for speech synthesis
//  itself: text-to-speech (AVSpeechSynthesizer) is unrestricted, unlike
//  speech RECOGNITION (SFSpeechRecognizer) or the microphone, which the
//  Voice Control feature added in VoiceCommandService does require.
//
//  Now subclasses NSObject + conforms to AVSpeechSynthesizerDelegate so
//  callers can be told exactly when narration finishes — that's what lets
//  Quiz Rush's Voice Control feature start listening for an answer at the
//  right moment instead of guessing with a fixed delay.

import Foundation
import Combine
import AVFoundation

@MainActor
final class QuizVoiceService: NSObject, ObservableObject {

    private let synthesizer = AVSpeechSynthesizer()
    private var lastUtterance: AVSpeechUtterance?
    private var completionHandler: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Reads the question, then each answer choice as "Option 1", "Option 2"…
    /// so a listener can pick one purely by ear. `onFinished` fires once all
    /// of it has been spoken — Quiz Rush's Voice Control uses this to know
    /// when it's safe to start listening for the answer.
    func speakQuestion(_ text: String, answers: [String], onFinished: (() -> Void)? = nil) {
        var utterances = [makeUtterance("Question. \(text)")]
        for (index, answer) in answers.enumerated() {
            utterances.append(makeUtterance("Option \(index + 1). \(answer)."))
        }
        speak(utterances, onFinished: onFinished)
    }

    /// Announces whether the just-submitted answer was correct.
    func speakResult(isCorrect: Bool, correctAnswer: String, onFinished: (() -> Void)? = nil) {
        let text = isCorrect ? "Correct!" : "Not quite. The correct answer was \(correctAnswer)."
        speak([makeUtterance(text)], onFinished: onFinished)
    }

    /// Generic one-off announcement (game-over summary, voice prompts, etc.)
    func announce(_ text: String, onFinished: (() -> Void)? = nil) {
        speak([makeUtterance(text)], onFinished: onFinished)
    }

    func stop() {
        completionHandler = nil
        lastUtterance = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func speak(_ utterances: [AVSpeechUtterance], onFinished: (() -> Void)?) {
        stop()
        configureAudioSessionForPlayback()
        completionHandler = onFinished
        lastUtterance = utterances.last
        for utterance in utterances {
            synthesizer.speak(utterance)
        }
    }

    private func makeUtterance(_ string: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        return utterance
    }

    /// VoiceCommandService leaves the shared audio session in `.record` mode
    /// after listening. Without switching back to `.playback` here, narration
    /// after the first voice answer can silently fail to come out of the
    /// speaker — AVSpeechSynthesizer doesn't error, it just goes quiet.
    private func configureAudioSessionForPlayback() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [
                    .duckOthers,
                    .defaultToSpeaker,
                    .allowBluetooth
                ]
            )

            try session.setActive(true)
        } catch {
            print("Speech playback audio-session error:", error)
        }
    }
}

extension QuizVoiceService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self, utterance === self.lastUtterance else { return }
            let handler = self.completionHandler
            self.completionHandler = nil
            handler?()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler = nil
        }
    }
}
