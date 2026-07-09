import SwiftUI

@main
struct IOSAppApp: App {
    var body: some Scene {
        WindowGroup {
            // Boot the app directly into the Tab Bar shell
            MainTabView()
        }
    }
}
