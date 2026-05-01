import AppKit

/// Detects app switches and optionally locks.
class AppMonitor {
    static let shared = AppMonitor()
    private init() {}

    private var observer: Any?

    func start() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleActivation(notification)
        }
    }

    func stop() {
        if let obs = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
    }

    private func handleActivation(_ note: Notification) {
        let mgr = LockManager.shared
        guard mgr.lockOnAppSwitch, !mgr.isLocked else { return }

        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }

        let selfBundle = Bundle.main.bundleIdentifier ?? ""
        let allowlist: Set<String> = [selfBundle, "com.apple.loginwindow"]
        guard !allowlist.contains(bundleID) else { return }

        mgr.lock(reason: .appSwitch)
    }
}
