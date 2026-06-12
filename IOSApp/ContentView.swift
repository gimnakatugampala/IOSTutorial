import SwiftUI
import Combine

struct ContentView: View {
    // Game state
    @State private var score = 0
    @State private var timeRemaining = 10
    @State private var gameOver = false
    
    // Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
//    everything visible on the screen
    var body: some View {
        VStack(spacing: 40) {
            // Score display
            Text("Score: \(score)")
                .font(.largeTitle)
            
            // Tap button or Game Over screen
            if !gameOver {
                Button(action: {
                    score += 1
                }) {
                    Text("TAP")
                        .font(.title)
                        .bold()
                        .frame(width: 200, height: 200)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            } else {
                VStack(spacing: 20) {
                    Text("Game Over")
                        .font(.largeTitle)
                        .bold()
                   
                    
                    Button("Play Again") {
                        restartGame()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            // Countdown timer
            Text("Time: \(timeRemaining)")
                .font(.title2)
        }
        .onReceive(timer) { _ in
            guard timeRemaining > 0 else {
                gameOver = true
                return
            }
            timeRemaining -= 1
        }
    }
    
    func restartGame() {
        score = 0
        timeRemaining = 10
        gameOver = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
