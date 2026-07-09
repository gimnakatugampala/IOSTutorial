import SwiftUI

struct LightItUpView: View {
    // 1. MVVM Connection
    @StateObject private var vm = LightItUpVM()
    
    // 2. Global Services for Map & Stats
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var locationService: LocationService

    @AppStorage("lightItUpHighScore") private var highScore = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea()
                
                // Panic Mode Background
                if vm.level == .overdrive {
                    Color.red.opacity(vm.pulseBackground ? 0.3 : 0.05)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.3).repeatForever(), value: vm.pulseBackground)
                        .onAppear { vm.pulseBackground = true }
                }
                
                // Level Up Flash
                if vm.showLevelFlash {
                    vm.level.glowColor.opacity(0.4)
                        .ignoresSafeArea()
                        .zIndex(10)
                        .transition(.opacity)
                }

                if vm.gameOver {
                    gameOverMenu
                } else {
                    VStack(spacing: 20) {
                        hudView
                        
                        // Level Indicator
                        Text(vm.level == .overdrive ? "⚠️ OVERDRIVE ⚠️" : "LEVEL \(levelLabel)")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(vm.level.glowColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: vm.level.columns), spacing: 15) {
                            ForEach(vm.cards) { card in
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(card.isLit ? .white : Color.white.opacity(0.05))
                                    .frame(height: 110)
                                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(card.isLit ? vm.level.glowColor : .white.opacity(0.1), lineWidth: card.isLit ? 4 : 1))
                                    .shadow(color: card.isLit ? vm.level.glowColor : .clear, radius: card.isLit ? 15 : 0)
                                    .scaleEffect(card.isLit ? 1.05 : (vm.level == .overdrive ? 0.9 : 1.0))
                                    .onTapGesture {
                                        vm.handleTap(card: card)
                                    }
                            }
                        }
                        .padding(.horizontal, 25)
                        Spacer()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Start game and fetch GPS immediately!
            vm.startGame()
            locationService.fetchLocation()
        }
        // UI Haptics when in overdrive
        .onChange(of: vm.timeRemaining) { newValue in
            if newValue <= 10 && vm.level == .overdrive {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
    }
    
    var hudView: some View {
        HStack {
            Button { dismiss() } label: { Image(systemName: "chevron.left.circle.fill").font(.title).foregroundColor(.white.opacity(0.6)) }
            Spacer()
            VStack { Text("SCORE").font(.system(size: 10, weight: .bold)); Text("\(vm.score)").font(.title2).bold() }
            Spacer()
            HStack(spacing: 4) { ForEach(0..<3, id: \.self) { i in Image(systemName: "heart.fill").foregroundColor(i < vm.lives ? .red : .gray) } }
            Spacer()
            VStack { Text("TIME").font(.system(size: 10, weight: .bold)); Text("\(vm.timeRemaining)").font(.title2).bold() }
        }.padding(.horizontal, 20)
    }

    var gameOverMenu: some View {
        VStack(spacing: 20) {
            Text(vm.lives <= 0 ? "GAME OVER" : "TIME'S UP").font(.largeTitle).bold()
            Text("Score: \(vm.score)").font(.title)
            
            Text(vm.score >= highScore ? "🏆 New High Score!" : "Best: \(highScore)")
                .font(.headline)
                .foregroundColor(vm.score >= highScore ? .yellow : .white.opacity(0.5))

            Button("Play Again") {
                vm.startGame()
                locationService.fetchLocation()
            }
            .padding().background(Color.blue).cornerRadius(10)
            
            Button("Main Menu") { dismiss() }
            .padding().background(Color.gray).cornerRadius(10)
        }
        .onAppear {
            // 🚨 SAVE TO STATS AND MAP WHEN GAME ENDS
            if vm.score > highScore { highScore = vm.score }
            
            statsVM.saveNewSession(
                mode: .lightItUp,
                score: vm.score,
                lat: locationService.latitude,
                lon: locationService.longitude
            )
        }
    }

    var levelLabel: String {
        switch vm.level {
        case .l1: return "1"; case .l2: return "2"; case .l3: return "3"; case .l4: return "4"; case .overdrive: return "MAX"
        }
    }
}
