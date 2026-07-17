import SwiftUI

struct QuizRushView: View {
    @StateObject private var viewModel = QuizRushViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // 1. Global Services for Map & Stats
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var locationService: LocationService
    
    @AppStorage("quizRushHighScore") private var highScore = 0

    /// Message handed to the system share sheet from the game-over screen.
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
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left.circle.fill").font(.title).foregroundColor(AppTheme.textPrimary.opacity(0.8))
                    }
                    Spacer()
                    Text("QUIZ RUSH").font(.headline).bold().foregroundColor(AppTheme.quizRush)
                    Spacer()
                    Image(systemName: "circle").opacity(0)
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
        .task {
            // 🚨 2. Fetch GPS in the background while the player picks a genre
            locationService.fetchLocation()
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
            
            Spacer()
            
            Text(viewModel.questions[viewModel.currentIndex].text)
                .font(.title2).bold().multilineTextAlignment(.center).foregroundColor(AppTheme.textPrimary)
                .padding().frame(maxWidth: .infinity, minHeight: 150)
                .background(AppTheme.card).cornerRadius(AppTheme.radiusPill)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusPill).stroke(AppTheme.cardBorder, lineWidth: 1))
                .padding(.horizontal)
                .offset(x: viewModel.shakeOffset)
            
            Spacer()
            
            VStack(spacing: 15) {
                ForEach(viewModel.questions[viewModel.currentIndex].answers, id: \.self) { answer in
                    Button { viewModel.checkAnswer(answer) } label: {
                        Text(answer).font(.headline).frame(maxWidth: .infinity).padding()
                            .background(buttonColor(for: answer)).foregroundColor(.white).cornerRadius(AppTheme.radiusButton - 1)
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(viewModel.answerFeedback != nil)
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
}
