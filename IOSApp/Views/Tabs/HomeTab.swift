import SwiftUI

struct HomeTab: View {
    // Animation States
    @State private var animateBackground = false
    @State private var floatIcon = false
    @State private var showButtons = false
    
    // High Score Persistence
    @AppStorage("tapFrenzyHighScore") private var tapFrenzyHighScore = 0
    @AppStorage("lightItUpHighScore") private var lightItUpHighScore = 0
    @AppStorage("quizRushHighScore") private var quizRushHighScore = 0
    
    var body: some View {
       
        ZStack {
            Color(red: 0.05, green: 0.02, blue: 0.1)
                .ignoresSafeArea()
                
            // Animated Background
            ZStack {
                Circle().fill(Color.purple.opacity(0.6)).frame(width: 350, height: 350).blur(radius: 120)
                    .offset(x: animateBackground ? 100 : -150, y: animateBackground ? -150 : 100)
                    .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animateBackground)
                    
                Circle().fill(Color.blue.opacity(0.5)).frame(width: 300, height: 300).blur(radius: 100)
                    .offset(x: animateBackground ? -150 : 150, y: animateBackground ? 150 : -150)
                    .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: animateBackground)
            }
            .ignoresSafeArea()
                
            VStack(spacing: 30) {
                // Hero Section
                VStack(spacing: 20) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(LinearGradient(colors: [.cyan, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: .cyan.opacity(0.6), radius: 20, x: 0, y: 10)
                        .offset(y: floatIcon ? -15 : 10)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: floatIcon)
                        
                    Text("Game Center")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 50)
                    
                // High Score Dashboard
                HStack(spacing: 10) {
                    ScoreBadge(title: "Tap", score: tapFrenzyHighScore)
                    ScoreBadge(title: "Light", score: lightItUpHighScore)
                    ScoreBadge(title: "Quiz", score: quizRushHighScore)
                }
                .padding(.horizontal)
                    
                // Game Buttons
                VStack(spacing: 20) {
                    NavigationLink(destination: TapFrenzyView()) { GameMenuButton(title: "Tap Frenzy", icon: "hand.tap.fill", gradientColors: [.blue, .purple]) }
                    NavigationLink(destination: LightItUpView()) { GameMenuButton(title: "Light It Up", icon: "lightbulb.max.fill", gradientColors: [.orange, .red, .pink]) }
                    NavigationLink(destination: QuizRushView()) { GameMenuButton(title: "Quiz Rush", icon: "questionmark.bubble.fill", gradientColors: [.purple, .indigo, .cyan]) }
                }
                .padding(.horizontal, 30)
                .opacity(showButtons ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: showButtons)
                    
                Spacer()
            }
        }
        .onAppear {
            animateBackground = true
            floatIcon = true
            showButtons = true
        }
    }
}
