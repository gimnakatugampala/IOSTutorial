import SwiftUI
import Combine

struct TapFrenzyView: View {
    // 1. Connect to our ViewModels
    @StateObject private var vm = TapFrenzyVM()
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var locationService: LocationService

    // UI States
    @State private var buttonPosition = CGPoint(x: 200, y: 400)
    @State private var buttonSize: CGFloat = 200
    
    // High Score Persistence (Local for the UI)
    @AppStorage("tapFrenzyHighScore") private var highScore = 0
    @Environment(\.dismiss) private var dismiss

    // We only need the move timer now, the VM handles the game timer!
    let moveButtonTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

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
                        
                        // Use vm.score and vm.timeRemaining
                        statCard(icon: "trophy.fill", title: "SCORE", value: "\(vm.score)", color: .orange)
                        statCard(icon: "timer", title: "TIME", value: "\(vm.timeRemaining)", color: .cyan)
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                .padding(.top)

                if !vm.isGameOver {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        // Tell the VM a tap happened
                        vm.tapRegistered()
                        
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
                    .onReceive(moveButtonTimer) { _ in
                        let x = CGFloat.random(in: 60...(geometry.size.width - 60))
                        let y = CGFloat.random(in: 180...(geometry.size.height - 150))
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            buttonPosition = CGPoint(x: x, y: y)
                        }
                    }
                } else {
                    gameOverMenu(in: geometry)
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                buttonPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Start fetching GPS immediately when view loads!
                locationService.fetchLocation()
                
                // Start the game via the ViewModel
                vm.startGame()
                }
            // Listen to the ViewModel's timer to shrink the button
            .onChange(of: vm.timeRemaining) { newValue in
                withAnimation(.easeInOut(duration: 1.0)) {
                    buttonSize = 50 + CGFloat(newValue) * 15
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
                Text("\(vm.score)").font(.system(size: 60, weight: .black, design: .rounded)).foregroundColor(.white)
            }
            
            Text(vm.score >= highScore ? "🏆 New High Score!" : "Best: \(highScore)")
                .font(.headline)
                .foregroundColor(vm.score >= highScore ? .yellow : .white.opacity(0.5))

            VStack(spacing: 15) {
                Button {
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
        .onAppear {
            if vm.score > highScore { highScore = vm.score }
            buttonPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
           
            statsVM.saveNewSession(
                mode: .tapFrenzy,
                score: vm.score,
                lat: locationService.latitude,
                lon: locationService.longitude
            )
        }
    }

    func restartGame(in geometry: GeometryProxy) {
        buttonSize = 200
        buttonPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        vm.startGame()
    }
}
