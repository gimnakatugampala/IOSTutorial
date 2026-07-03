import SwiftUI
import Combine

struct ContentView: View {

    @State private var score = 0
    @State private var timeRemaining = 10
    @State private var gameOver = false

    @State private var buttonPosition = CGPoint(x: 200, y: 400)
    @State private var buttonSize: CGFloat = 200
    
    // High Score Persistence
    @AppStorage("tapFrenzyHighScore") private var highScore = 0
    @Environment(\.dismiss) private var dismiss

    let moveButtonTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color.purple.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack {
                    HStack(spacing: 15) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.8), .ultraThinMaterial)
                        }
                        
                        statCard(icon: "trophy.fill", title: "SCORE", value: "\(score)", color: .orange)
                        statCard(icon: "timer", title: "TIME", value: "\(timeRemaining)", color: .cyan)
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                .padding(.top)

                if !gameOver {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        score += 1
                        
                        withAnimation(.spring()) {
                            if buttonSize > 50 { buttonSize -= 10 }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(RadialGradient(gradient: Gradient(colors: [.pink, .red.opacity(0.8)]), center: .topLeading, startRadius: 10, endRadius: buttonSize))
                            Circle()
                                .strokeBorder(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4)
                            Text("TAP")
                                .font(.system(size: buttonSize * 0.25, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
                        }
                        .frame(width: buttonSize, height: buttonSize)
                        .shadow(color: .red.opacity(0.6), radius: 20, y: 10)
                    }
                    .position(buttonPosition)

                } else {
                    gameOverMenu(in: geometry)
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                buttonPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .onReceive(timer) { _ in
                guard timeRemaining > 0 else {
                    // Update High Score on Game Over
                    if score > highScore { highScore = score }
                    gameOver = true
                    return
                }
                timeRemaining -= 1
                withAnimation(.easeInOut(duration: 1.0)) {
                    buttonSize = 50 + CGFloat(timeRemaining) * 15
                }
            }
            .onReceive(moveButtonTimer) { _ in
                if !gameOver {
                    let x = CGFloat.random(in: 60...(geometry.size.width - 60))
                    let y = CGFloat.random(in: 180...(geometry.size.height - 150))
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        buttonPosition = CGPoint(x: x, y: y)
                    }
                }
            }
        }
    }

    func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.6))
                Text(value).font(.system(size: 20, weight: .black, design: .rounded)).foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 1))
    }
    
    @ViewBuilder
    func gameOverMenu(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 25) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 70))
                .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                .shadow(color: .orange.opacity(0.5), radius: 10)

            Text("GAME OVER")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 5) {
                Text("Final Score").font(.subheadline).foregroundColor(.white.opacity(0.7))
                Text("\(score)").font(.system(size: 60, weight: .black, design: .rounded)).foregroundColor(.white)
            }
            
            Text(score >= highScore ? "🏆 New High Score!" : "Best: \(highScore)")
                .font(.headline)
                .foregroundColor(score >= highScore ? .yellow : .white.opacity(0.5))

            VStack(spacing: 15) {
                Button {
                    // Update High Score before restarting
                    if score > highScore { highScore = score }
                    restartGame(in: geometry)
                } label: {
                    Text("Play Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                
                Button { dismiss() } label: {
                    Text("Main Menu")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 1))
                }
            }
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.4))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 30)
    }

    func restartGame(in geometry: GeometryProxy) {
        score = 0
        timeRemaining = 10
        gameOver = false
        buttonSize = 200
        buttonPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
}
