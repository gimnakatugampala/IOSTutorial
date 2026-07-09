import SwiftUI

@main
struct IOSAppApp: App {
    // 1. Create a single instance of the ViewModel for the whole app
    @StateObject private var statsVM = StatsVM()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                // 2. Inject it into the environment so every tab can see it
                .environmentObject(statsVM)
        }
    }
}
