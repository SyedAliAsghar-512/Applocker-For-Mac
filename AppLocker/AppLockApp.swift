import SwiftUI

@main
struct AppLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Hidden settings window — opened via status bar menu
        Settings {
            SettingsView()
                .environmentObject(LockManager.shared)
                .environmentObject(LicenseManager.shared)
                .frame(width: 520, height: 600)
        }
    }
}
