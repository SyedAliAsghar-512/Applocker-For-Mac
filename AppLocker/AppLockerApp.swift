import SwiftUI

@main
struct AppLockerApp: App {
    @StateObject private var rules = RulesStore()
    private var monitor: AppMonitor?

    init() {
        if UserDefaults.standard.integer(forKey: "unlockTimeoutMinutes") == 0 {
            UserDefaults.standard.set(10, forKey: "unlockTimeoutMinutes")
        }
        monitor = AppMonitor(rules: rules)
    }

    var body: some Scene {
        MenuBarExtra("AppLocker", systemImage: "lock.shield") {
            RulesView()
                .environmentObject(rules)
        }
    }
}
