//
//  QuizVoiceService.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-18.
//
//
//  QuizVoiceService.swift
//  IOSApp
//
//  Lightweight wrapper around AVSpeechSynthesizer so Quiz Rush can read each
//  question and its answer choices aloud — primarily for blind/low-vision
//  players using VoiceOver, but works for anyone with the speaker button.
//
//  No extra Info.plist permission entries are needed for this: text-to-speech
//  (AVSpeechSynthesizer) is unrestricted, unlike speech RECOGNITION
//  (SFSpeechRecognizer) or the microphone, which do require usage-description
//  keys and a runtime permission prompt.
//

import Foundation
import Combine
import AVFoundation

@MainActor
final class QuizVoiceService: ObservableObject {

    private let synthesizer = AVSpeechSynthesizer()

    /// Reads the question, then each answer choice as "Option 1", "Option 2"…
    /// so a listener can pick one purely by ear, without needing to see the
    /// screen. Utterances queue automatically — calling this again (e.g. for
    /// the next question) cuts off whatever was still playing first.
    func speakQuestion(_ text: String, answers: [String]) {
        stop()
        speak("Question. \(text)")
        for (index, answer) in answers.enumerated() {
            speak("Option \(index + 1). \(answer).")
        }
    }

    /// Announces whether the just-submitted answer was correct, and if not,
    /// what the correct one was.
    func speakResult(isCorrect: Bool, correctAnswer: String) {
        stop()
        speak(isCorrect ? "Correct!" : "Not quite. The correct answer was \(correctAnswer).")
    }

    /// Generic one-off announcement (used for the game-over summary).
    func announce(_ text: String) {
        stop()
        speak(text)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func speak(_ string: String) {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        synthesizer.speak(utterance)
    }
}
