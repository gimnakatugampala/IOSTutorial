import SwiftUI
import Combine

// MARK: - Models
struct TriviaResponse: Codable {
    let response_code: Int? // Added this just to be safe
    let results: [TriviaResult]
}

struct TriviaResult: Codable {
    let question: String
    let correct_answer: String
    let incorrect_answers: [String]
}

// A mapped model specifically for the UI so answers are pre-shuffled
struct QuizQuestion: Identifiable {
    let id = UUID()
    let text: String
    let correctAnswer: String
    let answers: [String]
    
    init(from apiResult: TriviaResult) {
        // Decode the Base64 strings sent by the API
        self.text = apiResult.question.base64Decoded
        self.correctAnswer = apiResult.correct_answer.base64Decoded
        
        var allAnswers = apiResult.incorrect_answers.map { $0.base64Decoded }
        allAnswers.append(self.correctAnswer)
        self.answers = allAnswers.shuffled() // 4 shuffled answer buttons per question
    }
}

// NEW HELPER: Fast Base64 decoding (Avoids the Simulator freezing bug)
extension String {
    var base64Decoded: String {
        guard let data = Data(base64Encoded: self),
              let decodedString = String(data: data, encoding: .utf8) else {
            return self
        }
        return decodedString
    }
}

// MARK: - ViewModel
enum ViewState {
    case loading, loaded, failed
}

@MainActor
class QuizRushViewModel: ObservableObject {
    @Published var state: ViewState = .loading
    @Published var questions: [QuizQuestion] = []
    @Published var currentIndex = 0
    @Published var score = 0
    @Published var streak = 0
    @Published var isGameOver = false
    
    // Polish states
    @Published var answerFeedback: Bool? = nil // true = correct, false = wrong
    @Published var shakeOffset: CGFloat = 0
    
    // Use async/await and URLSession to pull questions
    func loadQuestions() async {
        state = .loading
        do {
            // UPDATED URL: Using Base64 encoding to avoid HTML formatting bugs
            let url = URL(string: "https://opentdb.com/api.php?amount=10&type=multiple&encode=base64")!
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decodedResponse = try JSONDecoder().decode(TriviaResponse.self, from: data)
            
            // Handle API rate limits (returns 0 questions if requested too fast)
            if decodedResponse.results.isEmpty {
                print("API returned 0 questions. Rate limited.")
                self.state = .failed
                return
            }
            
            self.questions = decodedResponse.results.map { QuizQuestion(from: $0) }
            self.resetGameStats()
            self.state = .loaded
            
        } catch {
            print("❌ Failed to load or decode questions: \(error)")
            self.state = .failed
        }
    }
    
    func resetGameStats() {
        currentIndex = 0
        score = 0
        streak = 0
        isGameOver = false
        answerFeedback = nil
    }
    
    func checkAnswer(_ answer: String) {
        guard currentIndex < questions.count, answerFeedback == nil else { return }
        let isCorrect = answer == questions[currentIndex].correctAnswer
        
        if isCorrect {
            // Correct tap -> score + advance
            // Streak tracked - consecutive correct answers give bonus points
            score += 10 + (streak * 5)
            streak += 1
            answerFeedback = true
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            // Wrong tap -> small penalty, still advances
            score = max(0, score - 5)
            streak = 0
            answerFeedback = false
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            // Red shake on wrong
            withAnimation(.linear(duration: 0.1)) { self.shakeOffset = 10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.linear(duration: 0.1)) { self.shakeOffset = -10 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.linear(duration: 0.1)) { self.shakeOffset = 0 }
            }
        }
        
        // Pause briefly to show the green flash/red shake, then advance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.answerFeedback = nil
            if self.currentIndex < self.questions.count - 1 {
                self.currentIndex += 1
            } else {
                self.isGameOver = true
            }
        }
    }
}

// MARK: - View
struct QuizRushView: View {
    @StateObject private var viewModel = QuizRushViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("quizRushHighScore") private var highScore = 0
    
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.05, green: 0.05, blue: 0.1)
                .ignoresSafeArea()
            
            // Background flash on answer
            if let feedback = viewModel.answerFeedback {
                (feedback ? Color.green : Color.red).opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            VStack {
                // Top Navigation Bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Text("QUIZ RUSH")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.purple)
                    Spacer()
                    Image(systemName: "circle").opacity(0)
                }
                .padding()
                
                // Content based on ViewState
                switch viewModel.state {
                case .loading: // Loading state during fetch
                    Spacer()
                    ProgressView()
                        .scaleEffect(2)
                        .tint(.purple)
                    Text("Fetching Live Trivia...")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 20)
                    Spacer()
                    
                case .failed: // Graceful error state on network failure
                    Spacer()
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    Text("Network Error")
                        .font(.title2).bold().foregroundColor(.white)
                        .padding(.top)
                    Text("Could not reach Open Trivia DB.")
                        .foregroundColor(.gray)
                    
                    Button {
                        Task { await viewModel.loadQuestions() }
                    } label: {
                        Text("Retry")
                            .bold()
                            .padding()
                            .frame(maxWidth: 200)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                    Spacer()
                    
                case .loaded:
                    if viewModel.isGameOver {
                        gameOverView
                    } else {
                        gamePlayView
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadQuestions()
        }
    }
    
    // MARK: - GamePlay View
    var gamePlayView: some View {
        VStack(spacing: 25) {
            // Stats Row
            HStack {
                VStack(alignment: .leading) {
                    Text("SCORE").font(.caption).foregroundColor(.gray)
                    Text("\(viewModel.score)").font(.title2).bold().foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("STREAK").font(.caption).foregroundColor(.orange)
                    Text("\(viewModel.streak) 🔥").font(.title2).bold().foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            
            // Progress Indicator
            Text("Question \(viewModel.currentIndex + 1) of 10")
                .font(.headline)
                .foregroundColor(.purple)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            
            Spacer()
            
            // Question Card
            Text(viewModel.questions[viewModel.currentIndex].text)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 150)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal)
                .offset(x: viewModel.shakeOffset) // Shake animation modifier
            
            Spacer()
            
            // 4 Answer Buttons
            VStack(spacing: 15) {
                ForEach(viewModel.questions[viewModel.currentIndex].answers, id: \.self) { answer in
                    Button {
                        viewModel.checkAnswer(answer)
                    } label: {
                        Text(answer)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(buttonColor(for: answer))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .disabled(viewModel.answerFeedback != nil) // Prevent multi-tapping
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Game Over View
    var gameOverView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("QUIZ COMPLETE!")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.purple)
            
            if viewModel.score > highScore {
                    let _ = DispatchQueue.main.async { highScore = viewModel.score }
                    Text("🏆 New High Score!").foregroundColor(.yellow)
                }
            
            Text("Final Score")
                .foregroundColor(.gray)
            Text("\(viewModel.score)")
                .font(.system(size: 60, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                Task { await viewModel.loadQuestions() }
            } label: {
                Text("Play Again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // Logic to highlight buttons during feedback delay
    func buttonColor(for answer: String) -> Color {
        guard let feedback = viewModel.answerFeedback else {
            return Color.white.opacity(0.1) // Default state
        }
        
        let isCorrectAnswer = answer == viewModel.questions[viewModel.currentIndex].correctAnswer
        
        if isCorrectAnswer {
            return .green // Green flash on correct
        } else if !feedback {
            return .red.opacity(0.6) // Red on wrong
        }
        
        return Color.white.opacity(0.1)
    }
}

#Preview {
    NavigationStack {
        QuizRushView()
    }
}
