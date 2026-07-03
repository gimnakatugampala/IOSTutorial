import SwiftUI

struct HomeView: View {
    // Animation States
    @State private var animateBackground = false
    @State private var floatIcon = false
    @State private var showButtons = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Base Dark Color
                Color(red: 0.05, green: 0.02, blue: 0.1)
                    .ignoresSafeArea()
                
                // 2. Animated Aurora / Glowing Orbs Background
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.6))
                        .frame(width: 350, height: 350)
                        .blur(radius: 120)
                        .offset(x: animateBackground ? 100 : -150, y: animateBackground ? -150 : 100)
                        .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animateBackground)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 300, height: 300)
                        .blur(radius: 100)
                        .offset(x: animateBackground ? -150 : 150, y: animateBackground ? 150 : -150)
                        .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: animateBackground)
                    
                    Circle()
                        .fill(Color.pink.opacity(0.4))
                        .frame(width: 250, height: 250)
                        .blur(radius: 100)
                        .offset(x: animateBackground ? 50 : -50, y: animateBackground ? -50 : 50)
                        .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animateBackground)
                }
                .ignoresSafeArea()
                
                // 3. Main Content
                VStack(spacing: 50) {
                    // Hero Section with Floating Animation
                    VStack(spacing: 20) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(colors: [.cyan, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: .cyan.opacity(0.6), radius: 20, x: 0, y: 10)
                            // The floating effect
                            .offset(y: floatIcon ? -15 : 10)
                            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: floatIcon)
                        
                        Text("Game Hub")
                            .font(.system(size: 50, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .purple.opacity(0.5), radius: 15)
                    }
                    .padding(.top, 50)
                    
                    // Game Buttons with Staggered Entrance
                        VStack(spacing: 25) {
                            NavigationLink(destination: ContentView()) {
                                GameMenuButton(
                                    title: "Tap Frenzy",
                                    icon: "hand.tap.fill",
                                    gradientColors: [.blue, .purple]
                                )
                            }
                            .offset(y: showButtons ? 0 : 50)
                            .opacity(showButtons ? 1 : 0)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: showButtons)
                            
                            NavigationLink(destination: LightItUpView()) {
                                GameMenuButton(
                                    title: "Light It Up",
                                    icon: "lightbulb.max.fill",
                                    gradientColors: [.orange, .red, .pink]
                                )
                            }
                            .offset(y: showButtons ? 0 : 50)
                            .opacity(showButtons ? 1 : 0)
                            .animation(.easeOut(duration: 0.8).delay(0.4), value: showButtons)
                            
                            // NEW QUIZ RUSH BUTTON
                            NavigationLink(destination: QuizRushView()) {
                                GameMenuButton(
                                    title: "Quiz Rush",
                                    icon: "questionmark.bubble.fill",
                                    gradientColors: [.purple, .indigo, .cyan]
                                )
                            }
                            .offset(y: showButtons ? 0 : 50)
                            .opacity(showButtons ? 1 : 0)
                            .animation(.easeOut(duration: 0.8).delay(0.6), value: showButtons)
                        }
                        .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
            .onAppear {
                // Trigger all animations when the view loads
                animateBackground = true
                floatIcon = true
                showButtons = true
            }
        }
    }
}

// Custom Button Component
struct GameMenuButton: View {
    let title: String
    let icon: String
    let gradientColors: [Color]
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.5), radius: 5)
            
            Text(title)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right.circle.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .background(
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.35)
        )
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                .opacity(0.8)
        )
        .shadow(color: gradientColors.first!.opacity(0.4), radius: 20, x: 0, y: 15)
    }
}

#Preview {
    HomeView()
}
