import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("🎮 Choose a Game")
                    .font(.largeTitle).bold()

                NavigationLink(destination: ContentView()) {
                    GameModeButton(title: "Tap Frenzy", subtitle: "Tap as fast as you can!", color: .red)
                }

                NavigationLink(destination: LightItUpView()) {
                    GameModeButton(title: "Light It Up", subtitle: "Tap the lit card before it goes dark", color: .blue)
                }
            }
            .padding()
            .navigationTitle("Mini Games")
        }
    }
}

struct GameModeButton: View {
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.title).bold().foregroundColor(.white)
            Text(subtitle)
                .font(.subheadline).foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(color)
        .cornerRadius(16)
    }
}

@main
struct IOSAppApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
