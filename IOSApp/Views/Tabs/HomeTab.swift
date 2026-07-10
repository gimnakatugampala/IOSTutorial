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
            AppTheme.background
                .ignoresSafeArea()
                
            // Animated Background — anchored to the app's theme + Light It Up accent
            ZStack {
                Circle().fill(AppTheme.brand.opacity(0.55)).frame(width: 350, height: 350).blur(radius: 120)
                    .offset(x: animateBackground ? 100 : -150, y: animateBackground ? -150 : 100)
                    .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animateBackground)
                    
                Circle().fill(AppTheme.lightItUp.opacity(0.45)).frame(width: 300, height: 300).blur(radius: 100)
                    .offset(x: animateBackground ? -150 : 150, y: animateBackground ? 150 : -150)
                    .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: animateBackground)
            }
            .ignoresSafeArea()
                
            VStack(spacing: 30) {
                // Hero Section
                VStack(spacing: 20) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(LinearGradient(colors: [AppTheme.lightItUp, AppTheme.brand, AppTheme.tapFrenzy], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: AppTheme.brand.opacity(0.6), radius: 20, x: 0, y: 10)
                        .offset(y: floatIcon ? -15 : 10)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: floatIcon)
                        
                    Text("Game Center")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(.top, 50)
                    
                // High Score Dashboard — each badge tinted to match its game's identity color
                HStack(spacing: 10) {
                    ScoreBadge(title: "Tap", score: tapFrenzyHighScore, color: AppTheme.tapFrenzy)
                    ScoreBadge(title: "Light", score: lightItUpHighScore, color: AppTheme.lightItUp)
                    ScoreBadge(title: "Quiz", score: quizRushHighScore, color: AppTheme.quizRush)
                }
                .padding(.horizontal)
                    
                // Game Buttons — gradients now pulled from AppTheme instead of ad-hoc system colors
                VStack(spacing: 20) {
                    NavigationLink(destination: TapFrenzyView()) {
                        GameMenuButton(title: "Tap Frenzy", icon: "hand.tap.fill", gradientColors: [AppTheme.tapFrenzy, AppTheme.brand])
                    }
                    NavigationLink(destination: LightItUpView()) {
                        GameMenuButton(title: "Light It Up", icon: "lightbulb.max.fill", gradientColors: [AppTheme.warning, AppTheme.danger, AppTheme.tapFrenzy])
                    }
                    NavigationLink(destination: QuizRushView()) {
                        GameMenuButton(title: "Quiz Rush", icon: "questionmark.bubble.fill", gradientColors: [AppTheme.quizRush, AppTheme.lightItUp])
                    }
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
