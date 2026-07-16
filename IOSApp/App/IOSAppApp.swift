import SwiftUI
import UserNotifications

@main
struct IOSAppApp: App {
    @StateObject private var statsVM = StatsVM()
    @StateObject private var locationService = LocationService()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(statsVM)
                .environmentObject(locationService)
                .environmentObject(themeManager)
                .tint(themeManager.accent.color)
                // Forces the whole tab hierarchy to rebuild the instant the
                // accent changes, so every screen picks up the new
                // AppTheme.brand immediately instead of waiting for an
                // unrelated redraw.
                .id(themeManager.accent)
                .onAppear {
                    locationService.requestPermission()
                    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
                }
        }
    }
}
