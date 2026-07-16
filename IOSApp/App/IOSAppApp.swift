import SwiftUI
import UserNotifications

@main
struct IOSAppApp: App {
    @StateObject private var statsVM = StatsVM()
    @StateObject private var locationService = LocationService()
    @StateObject private var themeManager = ThemeManager()

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environmentObject(statsVM)
                    .environmentObject(locationService)
                    .environmentObject(themeManager)
                    .tint(themeManager.accent.color)
                    // Forces the whole tab hierarchy to rebuild the instant the
                    // accent changes, so every screen picks up the new
                    // AppTheme.brand immediately.
                    .id(themeManager.accent)
                    .onAppear {
                        locationService.requestPermission()
                        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
                    }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // Splash holds for long enough to read + enjoy the animation,
                // then fades to reveal the app underneath, which has already
                // been sitting ready this whole time — no extra load delay.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
