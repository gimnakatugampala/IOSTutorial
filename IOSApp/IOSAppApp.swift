import SwiftUI


@main
struct IOSAppApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView() // Ensure this is HomeView, not ContentView
        }
    }
}
