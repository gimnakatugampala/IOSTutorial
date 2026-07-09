import SwiftUI

@main
struct IOSAppApp: App {
    @StateObject private var statsVM = StatsVM()
    // 1. Initialize the new location service
    @StateObject private var locationService = LocationService()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(statsVM)
                // 2. Inject it so your games can access it
                .environmentObject(locationService)
                // 3. Ask for permission as soon as the app opens
                .onAppear {
                    locationService.requestPermission()
                }
        }
    }
}
