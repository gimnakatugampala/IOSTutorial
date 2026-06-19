import SwiftUI
import Combine

struct ContentView: View {
    // Game state
    @State private var score = 0
    @State private var timeRemaining = 10
    @State private var gameOver = false
    
    // Moving Target
    @State private var buttonPosition = CGPoint(x: 200, y: 400)
    let moveButtonTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    // Shrinking Button
    @State private var buttonSize: CGFloat = 200
    
    // Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Score display
                VStack {
                    Text("Score: \(score)")
                        .font(.largeTitle)
                    Spacer()
                    Text("Time: \(timeRemaining)")
                        .font(.title2)
                }
                .padding()
                
                if !gameOver {
                    Button(action: {
                        score += 1
                        // Shrink button on every tap, minimum size 50
                        withAnimation {
                            if buttonSize > 50 {
                                buttonSize -= 10
                            }
                        }
                    }) {
                        Text("TAP")
                            .font(.title)
                            .bold()
                            .frame(width: buttonSize, height: buttonSize)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .position(buttonPosition)
                } else {
                    VStack(spacing: 20) {
                        Text("Game Over")
                            .font(.largeTitle)
                            .bold()
                        Text("Final Score: \(score)")
                            .font(.title)
                        Button("Play Again") {
                            restartGame(in: geometry)
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                buttonPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .onReceive(timer) { _ in
                guard timeRemaining > 0 else {
                    gameOver = true
                    return
                }
                timeRemaining -= 1
            }
            .onReceive(moveButtonTimer) { _ in
                if !gameOver {
                    let x = CGFloat.random(in: 50...(geometry.size.width - 50))
                    let y = CGFloat.random(in: 150...(geometry.size.height - 150))
                    withAnimation {
                        buttonPosition = CGPoint(x: x, y: y)
                    }
                }
            }
        }
    }
    
    func restartGame(in geometry: GeometryProxy) {
        score = 0
        timeRemaining = 10
        gameOver = false
        buttonSize = 200  // reset size
        buttonPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
}

#Preview {
    ContentView()
}
