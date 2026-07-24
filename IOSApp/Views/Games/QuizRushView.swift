import SwiftUI

struct QuizRushView: View {
    /// When true (only ever set by HomeTab's Voice Control launcher), skips
    /// genre selection and jumps straight into an "Any Genre" round — voice
    /// control is meant to be a zero-touch flow from the moment the player
    /// says "Quiz Rush," so making them then tap a genre grid would defeat it.
    var autoStart: Bool = false

    @StateObject private var viewModel = QuizRushViewModel()
    @StateObject private var voice = QuizVoiceService()
    @StateObject private var voiceCommand = VoiceCommandService()
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var locationService: LocationService
    
    @AppStorage("quizRushHighScore") private var highScore = 0

    @AppStorage("quizRushVoiceEnabled") private var voiceEnabled = false
    @AppStorage("quizRushVoiceControlEnabled") private var voiceControlEnabled = false

    /// Counts consecutive failed voice-answer attempts on the current
    /// question, so a noisy room can't leave the player stuck in an
    /// infinite "didn't catch that" loop — after a couple of misses we back
    /// off and let them answer by tapping instead.
    @State private var answerListenAttempts = 0

    private var shareText: String {
        "I scored \(viewModel.score) points in Quiz Rush (\(viewModel.selectedCategory.displayName)) — \(viewModel.correctCount) correct! 🧠 Can you beat that?"
    }
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            if let feedback = viewModel.answerFeedback {
                (feedback ? AppTheme.success : AppTheme.danger).opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            VStack {
                HStack {
                    Button {
                        voice.stop()
                        voiceCommand.stopListening()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left.circle.fill").font(.title).foregroundColor(AppTheme.textPrimary.opacity(0.8))
                    }
                    .accessibilityLabel("Back to main menu")

                    Spacer()
                    Text("QUIZ RUSH").font(.headline).bold().foregroundColor(AppTheme.quizRush)
                    Spacer()

                    if viewModel.state == .loaded && !viewModel.isGameOver && voiceEnabled {
                        Button {
                            let question = viewModel.questions[viewModel.currentIndex]
                            voice.speakQuestion(question.text, answers: question.answers)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(AppTheme.quizRush)
                        }
                        .accessibilityLabel("Read question and answers aloud")
                    } else {
                        Image(systemName: "circle").opacity(0)
                    }
                }.padding()
                
                switch viewModel.state {
                case .selectingCategory:
                    categorySelectionMenu
                    
                case .loading:
                    Spacer()
                    ProgressView().scaleEffect(2).tint(AppTheme.quizRush)
                    Text("Fetching \(viewModel.selectedCategory.displayName) Trivia...").foregroundColor(AppTheme.textSecondary).padding(.top, 20)
                    Spacer()
                    
                case .failed:
                    Spacer()
                    Image(systemName: "wifi.exclamationmark").font(.system(size: 60)).foregroundColor(AppTheme.danger)
                    Text("Network Error").font(.title2).bold().foregroundColor(AppTheme.textPrimary).padding(.top)
                    Text("Could not reach Open Trivia DB, or this genre is out of questions.").multilineTextAlignment(.center).foregroundColor(AppTheme.textSecondary).padding(.horizontal, 40)
                    Button { Task { await viewModel.loadQuestions() } } label: {
                        Text("Retry").bold().padding().frame(maxWidth: 200).background(AppTheme.quizRush).foregroundColor(.white).cornerRadius(AppTheme.radiusButton)
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.top, 20)
                    Button { viewModel.backToCategorySelection() } label: {
                        Text("Choose a Different Genre").foregroundColor(AppTheme.textSecondary)
                    }.padding(.top, 4)
                    Spacer()
                    
                case .loaded:
                    if viewModel.isGameOver { gameOverView } else { gamePlayView }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.state)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if autoStart, viewModel.state == .selectingCategory {
                viewModel.selectCategory(.any)
            }
        }
        .task {
            locationService.fetchLocation()
        }
        .onChange(of: viewModel.state) { newState in
            guard voiceEnabled, newState == .loaded, !viewModel.isGameOver, !viewModel.questions.isEmpty else { return }
            answerListenAttempts = 0
            let question = viewModel.questions[viewModel.currentIndex]
            voice.speakQuestion(question.text, answers: question.answers) {
                listenForAnswer()
            }
        }
        .onChange(of: viewModel.currentIndex) { _ in
            guard voiceEnabled, viewModel.state == .loaded, !viewModel.isGameOver, !viewModel.questions.isEmpty else { return }
            answerListenAttempts = 0
            let question = viewModel.questions[viewModel.currentIndex]
            voice.speakQuestion(question.text, answers: question.answers) {
                listenForAnswer()
            }
        }
        .onChange(of: viewModel.answerFeedback) { feedback in
            guard voiceEnabled, let feedback else { return }
            voiceCommand.stopListening()
            let correctAnswer = viewModel.questions[viewModel.currentIndex].correctAnswer
            voice.speakResult(isCorrect: feedback, correctAnswer: correctAnswer)
        }
        .onDisappear {
            voice.stop()
            voiceCommand.stopListening()
        }
    }
    
    var categorySelectionMenu: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Choose a Genre")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Questions are pulled live from Open Trivia DB")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textMuted)
                }
                .padding(.top, 10)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(QuizCategory.allCases) { category in
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            viewModel.selectCategory(category)
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                VStack(spacing: 10) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 26))
                                    Text(category.displayName)
                                        .font(.subheadline).bold()
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                }
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .padding(.horizontal, 8)
                                .background(category.color.opacity(0.22))
                                .cornerRadius(AppTheme.radiusCard)
                                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusCard).stroke(category.color.opacity(0.7), lineWidth: 1.5))
                                
                                if category == .any {
                                    Text("PICK FOR ME")
                                        .font(.system(size: 9, weight: .black))
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(category.color)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        .padding(8)
                                }
                            }
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel(category == .any ? "\(category.displayName), pick for me" : category.displayName)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }

    var gamePlayView: some View {
        VStack(spacing: 25) {
            HStack {
                VStack(alignment: .leading) {
                    Text("SCORE").font(.caption).foregroundColor(AppTheme.textMuted)
                    Text("\(viewModel.score)").font(.title2).bold().foregroundColor(AppTheme.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("STREAK").font(.caption).foregroundColor(AppTheme.warning)
                    Text("\(viewModel.streak) 🔥").font(.title2).bold().foregroundColor(AppTheme.warning)
                }
            }.padding(.horizontal)
            
            HStack(spacing: 8) {
                Text("Question \(viewModel.currentIndex + 1) of 10")
                    .font(.headline).foregroundColor(AppTheme.quizRush)
                
                Text("•").foregroundColor(AppTheme.textMuted)
                
                Label(viewModel.selectedCategory.displayName, systemImage: viewModel.selectedCategory.icon)
                    .font(.caption).bold()
                    .foregroundColor(viewModel.selectedCategory.color)
            }
            .padding(.vertical, 8).padding(.horizontal, 16)
            .background(.ultraThinMaterial).cornerRadius(AppTheme.radiusPill)

            if voiceControlEnabled && voiceCommand.isListening {
                Label("Listening for your answer…", systemImage: "waveform")
                    .font(.caption).bold()
                    .foregroundColor(AppTheme.quizRush)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(AppTheme.quizRush.opacity(0.15))
                    .clipShape(Capsule())
                    .accessibilityLabel("Listening for your answer")
                    .transition(.opacity)
            }
            
            Spacer()
            
            Text(viewModel.questions[viewModel.currentIndex].text)
                .font(.title2).bold().multilineTextAlignment(.center).foregroundColor(AppTheme.textPrimary)
                .padding().frame(maxWidth: .infinity, minHeight: 150)
                .background(AppTheme.card).cornerRadius(AppTheme.radiusPill)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusPill).stroke(AppTheme.cardBorder, lineWidth: 1))
                .padding(.horizontal)
                .offset(x: viewModel.shakeOffset)
                .accessibilityLabel("Question \(viewModel.currentIndex + 1) of 10. \(viewModel.questions[viewModel.currentIndex].text)")
            
            Spacer()
            
            VStack(spacing: 15) {
                ForEach(Array(viewModel.questions[viewModel.currentIndex].answers.enumerated()), id: \.offset) { index, answer in
                    Button {
                        voiceCommand.stopListening()
                        viewModel.checkAnswer(answer)
                    } label: {
                        Text(answer).font(.headline).frame(maxWidth: .infinity).padding()
                            .background(buttonColor(for: answer)).foregroundColor(.white).cornerRadius(AppTheme.radiusButton - 1)
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(viewModel.answerFeedback != nil)
                    .accessibilityLabel("Option \(index + 1): \(answer)")
                    .accessibilityHint("Double tap to select this answer")
                }
            }.padding(.horizontal).padding(.bottom, 30)
        }
    }
    
    var gameOverView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient(colors: [AppTheme.warning, AppTheme.tapFrenzy.opacity(0.6)], startPoint: .top, endPoint: .bottom))
            
            Text("QUIZ COMPLETE!").font(.system(size: 32, weight: .black, design: .rounded)).foregroundColor(AppTheme.quizRush)
            
            if viewModel.score > highScore {
                Text("🏆 New High Score!").foregroundColor(AppTheme.warning)
            }
            
            Text("Final Score").foregroundColor(AppTheme.textSecondary)
            Text("\(viewModel.score)").font(.system(size: 60, weight: .black, design: .rounded)).foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    voiceCommand.stopListening()
                    Task {
                        locationService.fetchLocation()
                        await viewModel.loadQuestions()
                    }
                } label: {
                    Text("Play Again — \(viewModel.selectedCategory.displayName)").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(LinearGradient(colors: [AppTheme.quizRush, AppTheme.quizRush.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white).cornerRadius(AppTheme.radiusButton)
                }
                .buttonStyle(PressableStyle())

                ShareScoreButton(shareText: shareText, tint: AppTheme.quizRush)
                
                Button {
                    voiceCommand.stopListening()
                    viewModel.backToCategorySelection()
                } label: {
                    Text("Choose a Different Genre").font(.subheadline).bold().frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .foregroundColor(AppTheme.textPrimary).cornerRadius(AppTheme.radiusButton)
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusButton).stroke(AppTheme.cardBorderStrong, lineWidth: 1))
                }
                .buttonStyle(PressableStyle())
            }.padding(.horizontal, 40).padding(.bottom, 40)
        }
        .onAppear {
            if viewModel.score > highScore { highScore = viewModel.score }

            if voiceEnabled {
                let summary = "Quiz complete! Final score: \(viewModel.score) points. \(viewModel.correctCount) correct, \(viewModel.incorrectCount) incorrect."
                if voiceControlEnabled {
                    voice.announce(summary) {
                        listenForPostGameCommand()
                    }
                } else {
                    voice.announce(summary)
                }
            }

            locationService.awaitLocation { lat, lon in
                Task {
                    await statsVM.saveNewSession(
                        mode: .quizRush,
                        score: viewModel.score,
                        lat: lat,
                        lon: lon,
                        correctAnswers: viewModel.correctCount,
                        incorrectAnswers: viewModel.incorrectCount,
                        genre: viewModel.selectedCategory.displayName
                    )
                }
            }
        }
    }
    
    func buttonColor(for answer: String) -> Color {
        guard let feedback = viewModel.answerFeedback else { return AppTheme.card }
        let isCorrectAnswer = answer == viewModel.questions[viewModel.currentIndex].correctAnswer
        if isCorrectAnswer { return AppTheme.success } else if !feedback { return AppTheme.danger.opacity(0.6) }
        return AppTheme.card
    }

    // MARK: - Voice Control

    /// Starts listening right after a question finishes being read, matches
    /// what's heard to one of the four on-screen options, and submits it —
    /// the same code path a manual tap goes through.
    private func listenForAnswer() {
        guard voiceControlEnabled, viewModel.state == .loaded, !viewModel.isGameOver,
              viewModel.currentIndex < viewModel.questions.count else { return }
        let options = viewModel.questions[viewModel.currentIndex].answers

        voiceCommand.listenOnce { heard in
            guard let heard, let matched = matchSpokenAnswer(heard, options: options) else {
                retryListeningForAnswer(options: options)
                return
            }
            answerListenAttempts = 0
            viewModel.checkAnswer(matched)
        }
    }

    private func retryListeningForAnswer(options: [String]) {
        answerListenAttempts += 1
        guard answerListenAttempts <= 2 else {
            answerListenAttempts = 0
            voice.announce("You can also tap an answer on screen.")
            return
        }
        voice.announce("Sorry, I didn't catch that. Please say the option number.") {
            listenForAnswer()
        }
    }

    /// Once the round is over, offers a hands-free way to keep going — "play
    /// again" restarts the same genre, "menu" goes back to genre selection.
    private func listenForPostGameCommand() {
        voice.announce("Say play again, or say menu to choose a different genre.") {
            voiceCommand.listenOnce { heard in
                guard let heard else { return }
                if heard.contains("again") || heard.contains("replay") {
                    Task {
                        locationService.fetchLocation()
                        await viewModel.loadQuestions()
                    }
                } else if heard.contains("menu") || heard.contains("genre") {
                    viewModel.backToCategorySelection()
                }
            }
        }
    }

    /// Turns a messy spoken transcript into one of the four answer strings.
    /// Tries, in order: "option 2" / "number two" / a bare digit or number
    /// word (treated as a 1-based index), then falls back to fuzzy text
    /// matching against the actual answer content so saying the answer
    /// itself ("paris") works just as well as saying its option number.
    private func matchSpokenAnswer(_ transcript: String, options: [String]) -> String? {
        let cleaned = transcript.lowercased()

        let numberWords: [String: Int] = [
            "one": 1, "two": 2, "three": 3, "four": 4, "to": 2, "for": 4
        ]
        for (word, number) in numberWords where cleaned.contains(word) {
            if number - 1 < options.count { return options[number - 1] }
        }
        // A short transcript that's basically just a digit — avoids
        // mis-firing on a spoken answer that happens to contain a number,
        // e.g. "nineteen sixty nine."
        if cleaned.count <= 12, let digit = cleaned.compactMap({ $0.wholeNumberValue }).first,
           digit >= 1, digit - 1 < options.count {
            return options[digit - 1]
        }

        for option in options {
            let optionLower = option.lowercased()
            if cleaned == optionLower || cleaned.contains(optionLower) || optionLower.contains(cleaned) {
                return option
            }
        }
        return nil
    }
}
