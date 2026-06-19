import SwiftUI
import Combine

struct ContentView: View {

    @State private var score = 0
    @State private var timeRemaining = 10
    @State private var gameOver = false

    @State private var buttonPosition = CGPoint(x: 200, y: 400)
    @State private var buttonSize: CGFloat = 200

    let moveButtonTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {

                // Background
                LinearGradient(
                    colors: [
                        Color.blue,
                        Color.purple,
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack {

                    HStack(spacing: 15) {

                        statCard(
                            title: "SCORE",
                            value: "\(score)",
                            color: .orange
                        )

                        statCard(
                            title: "TIME",
                            value: "\(timeRemaining)",
                            color: .cyan
                        )
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top)

                if !gameOver {

                    Button {
                        score += 1

                        withAnimation(.spring()) {
                            if buttonSize > 50 {
                                buttonSize -= 10
                            }
                        }
                    } label: {

                        ZStack {

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Circle()
                                .stroke(
                                    Color.white.opacity(0.5),
                                    lineWidth: 4
                                )

                            Text("TAP")
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                        }
                        .frame(
                            width: buttonSize,
                            height: buttonSize
                        )
                        .shadow(
                            color: .red.opacity(0.8),
                            radius: 25
                        )
                    }
                    .position(buttonPosition)

                } else {

                    VStack(spacing: 20) {

                        Image(systemName: "trophy.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.yellow)

                        Text("GAME OVER")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(.white)

                        Text("Final Score")
                            .foregroundColor(.white.opacity(0.7))

                        Text("\(score)")
                            .font(.system(size: 60))
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Button {
                            restartGame(in: geometry)
                        } label: {

                            Text("Play Again")
                                .font(.headline)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .cornerRadius(30)
                    .shadow(radius: 20)
                }
            }
            .onAppear {
                buttonPosition = CGPoint(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
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

                    let x = CGFloat.random(
                        in: 50...(geometry.size.width - 50)
                    )

                    let y = CGFloat.random(
                        in: 150...(geometry.size.height - 150)
                    )

                    withAnimation(.spring()) {
                        buttonPosition = CGPoint(x: x, y: y)
                    }
                }
            }
        }
    }

    func statCard(
        title: String,
        value: String,
        color: Color
    ) -> some View {

        VStack(spacing: 8) {

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    func restartGame(in geometry: GeometryProxy) {

        score = 0
        timeRemaining = 10
        gameOver = false
        buttonSize = 200

        buttonPosition = CGPoint(
            x: geometry.size.width / 2,
            y: geometry.size.height / 2
        )
    }
}

#Preview {
    ContentView()
}
