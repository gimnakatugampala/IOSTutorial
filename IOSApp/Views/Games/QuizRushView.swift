import SwiftUI

struct QuizRushView: View {
    @StateObject private var viewModel = QuizRushViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // 🚨 1. Global Services for Map & Stats
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var locationService: LocationService
    
    @AppStorage("quizRushHighScore") private var highScore = 0
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()
            
            if let feedback = viewModel.answerFeedback {
                (feedback ? Color.green : Color.red).opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left.circle.fill").font(.title).foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Text("QUIZ RUSH").font(.headline).bold().foregroundColor(.purple)
                    Spacer()
                    Image(systemName: "circle").opacity(0)
                }.padding()
                
                switch viewModel.state {
                case .loading:
                    Spacer()
                    ProgressView().scaleEffect(2).tint(.purple)
                    Text("Fetching Live Trivia...").foregroundColor(.white.opacity(0.7)).padding(.top, 20)
                    Spacer()
                    
                case .failed:
                    Spacer()
                    Image(systemName: "wifi.exclamationmark").font(.system(size: 60)).foregroundColor(.red)
                    Text("Network Error").font(.title2).bold().foregroundColor(.white).padding(.top)
                    Text("Could not reach Open Trivia DB.").foregroundColor(.gray)
                    Button { Task { await viewModel.loadQuestions() } } label: {
                        Text("Retry").bold().padding().frame(maxWidth: 200).background(Color.purple).foregroundColor(.white).cornerRadius(12)
                    }.padding(.top, 20)
                    Spacer()
                    
                case .loaded:
                    if viewModel.isGameOver { gameOverView } else { gamePlayView }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            // 🚨 2. Fetch GPS in the background while loading questions
            locationService.fetchLocation()
            await viewModel.loadQuestions()
        }
    }
    
    var gamePlayView: some View {
        VStack(spacing: 25) {
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
            }.padding(.horizontal)
            
            Text("Question \(viewModel.currentIndex + 1) of 10")
                .font(.headline).foregroundColor(.purple).padding(.vertical, 8).padding(.horizontal, 16)
                .background(.ultraThinMaterial).cornerRadius(20)
            
            Spacer()
            
            Text(viewModel.questions[viewModel.currentIndex].text)
                .font(.title2).bold().multilineTextAlignment(.center).foregroundColor(.white)
                .padding().frame(maxWidth: .infinity, minHeight: 150)
                .background(Color.white.opacity(0.05)).cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal)
                .offset(x: viewModel.shakeOffset)
            
            Spacer()
            
            VStack(spacing: 15) {
                ForEach(viewModel.questions[viewModel.currentIndex].answers, id: \.self) { answer in
                    Button { viewModel.checkAnswer(answer) } label: {
                        Text(answer).font(.headline).frame(maxWidth: .infinity).padding()
                            .background(buttonColor(for: answer)).foregroundColor(.white).cornerRadius(15)
                    }
                    .disabled(viewModel.answerFeedback != nil)
                }
            }.padding(.horizontal).padding(.bottom, 30)
        }
    }
    
    var gameOverView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("QUIZ COMPLETE!").font(.system(size: 32, weight: .black, design: .rounded)).foregroundColor(.purple)
            
            if viewModel.score > highScore {
                Text("🏆 New High Score!").foregroundColor(.yellow)
            }
            
            Text("Final Score").foregroundColor(.gray)
            Text("\(viewModel.score)").font(.system(size: 60, weight: .black, design: .rounded)).foregroundColor(.white)
            
            Spacer()
            
            Button {
                Task {
                    locationService.fetchLocation()
                    await viewModel.loadQuestions()
                }
            } label: {
                Text("Play Again").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white).cornerRadius(16)
            }.padding(.horizontal, 40).padding(.bottom, 40)
        }
        .onAppear {
            // 🚨 3. Save Data When Game Over Appears
            if viewModel.score > highScore { highScore = viewModel.score }
            
            statsVM.saveNewSession(
                mode: .quizRush,
                score: viewModel.score,
                lat: locationService.latitude,
                lon: locationService.longitude
            )
        }
    }
    
    func buttonColor(for answer: String) -> Color {
        guard let feedback = viewModel.answerFeedback else { return Color.white.opacity(0.1) }
        let isCorrectAnswer = answer == viewModel.questions[viewModel.currentIndex].correctAnswer
        if isCorrectAnswer { return .green } else if !feedback { return .red.opacity(0.6) }
        return Color.white.opacity(0.1)
    }
}
