import SwiftUI

struct HomeView: View {
    @State private var isAnimating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated Dark Gradient Background
                LinearGradient(
                    colors: [Color.indigo.opacity(0.8), Color.black, Color.purple.opacity(0.6)],
                    startPoint: isAnimating ? .topLeading : .bottomTrailing,
                    endPoint: isAnimating ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: isAnimating)
                
                VStack(spacing: 50) {
                    // Hero Section
                    VStack(spacing: 15) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom)
                            )
                            .shadow(color: .cyan.opacity(0.5), radius: 10)
                        
                        Text("Game Hub")
                            .font(.system(size: 45, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .purple.opacity(0.5), radius: 10)
                    }
                    .padding(.top, 40)
                    
                    // Game Buttons
                    VStack(spacing: 25) {
                        NavigationLink(destination: ContentView()) {
                            GameMenuButton(
                                title: "Tap Frenzy",
                                icon: "hand.tap.fill",
                                gradientColors: [.blue, .purple]
                            )
                        }
                        
                        NavigationLink(destination: LightItUpView()) {
                            GameMenuButton(
                                title: "Light It Up",
                                icon: "lightbulb.max.fill",
                                gradientColors: [.orange, .red]
                            )
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
            .onAppear {
                isAnimating = true
            }
        }
    }
}

// Custom Button Component for the Home Menu
struct GameMenuButton: View {
    let title: String
    let icon: String
    let gradientColors: [Color]
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
            
            Text(title)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .background(
            LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                .opacity(0.4)
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
        )
        .shadow(color: gradientColors.first!.opacity(0.3), radius: 15, x: 0, y: 10)
    }
}

#Preview {
    HomeView()
}
