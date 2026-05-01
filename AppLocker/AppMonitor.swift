import AppKit

final class AppMonitor {
    private let rules: RulesStore
    private let auth = AuthManager()
    private var allowUntil: [String: Date] = [:] // bundleID -> expiry

    init(rules: RulesStore) {
        self.rules = rules
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appLaunched(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
    }

    @objc private func appLaunched(_ note: Notification) {
        guard let info = note.userInfo,
              let app = info[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }

        guard rules.lockedApps.contains(where: { $0.id == bundleID }) else { return }

        if let expiry = allowUntil[bundleID], expiry > Date() {
            return
        }

        app.terminate()

        auth.authenticate(reason: "Unlock \(app.localizedName ?? "App")") { [weak self] success in
            guard let self else { return }
            if success, let url = app.bundleURL {
                let timeoutMinutes = UserDefaults.standard.integer(forKey: "unlockTimeoutMinutes")
                let minutes = max(timeoutMinutes, 1)
                self.allowUntil[bundleID] = Date().addingTimeInterval(TimeInterval(minutes * 60))
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            }
        }
    }
}
