import SwiftUI

struct ContentView: View {
    // Game state
    @State private var score = 0
    @State private var timeRemaining = 10
    @State private var gameOver = false
    
    // Button properties for challenges
    @State private var buttonSize: CGFloat = 150
    @State private var buttonPosition = CGPoint(x: UIScreen.main.bounds.width / 2,
                                                y: UIScreen.main.bounds.height / 2)
    
    // Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let moveButtonTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect() // Moving Target
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.1).ignoresSafeArea()
            
            if gameOver {
                VStack(spacing: 20) {
                    Text("Game Over")
                        .font(.largeTitle)
                        .bold()
                    Text("Final Score: \(score)")
                        .font(.title)
                    Button("Play Again") {
                        restartGame()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                VStack(spacing: 50) {
                    Text("Score: \(score)")
                        .font(.title)
                    
                    Spacer()
                    
                    Button(action: {
                        score += 1
                        // Optional: shrink button with each tap
                        if buttonSize > 50 {
                            buttonSize -= 5
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
                    
                    Spacer()
                    
                    Text("Time: \(timeRemaining)")
                        .font(.title2)
                }
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                gameOver = true
            }
        }
        .onReceive(moveButtonTimer) { _ in
            if !gameOver {
                // Move button to random position
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                let x = CGFloat.random(in: 50...(screenWidth - 50))
                let y = CGFloat.random(in: 150...(screenHeight - 150))
                withAnimation {
                    buttonPosition = CGPoint(x: x, y: y)
                }
            }
        }
    }
    
    func restartGame() {
        score = 0
        timeRemaining = 10
        buttonSize = 150
        gameOver = false
        buttonPosition = CGPoint(x: UIScreen.main.bounds.width / 2,
                                 y: UIScreen.main.bounds.height / 2)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
