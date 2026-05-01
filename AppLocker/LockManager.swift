import Foundation
import AppKit
import Combine

/// Central lock state machine. All locking/unlocking flows through here.
class LockManager: ObservableObject {
    static let shared = LockManager()

    // MARK: - Published State
    @Published var isLocked: Bool = false
    @Published var lockOnAppSwitch: Bool = false
    @Published var autoLockOnIdle: Bool = true
    @Published var idleTimeoutSeconds: Int = 300      // 5 min default
    @Published var autoLockOnSleep: Bool = true
    @Published var closeAppsOnSleep: Bool = false
    @Published var autoCloseSelectedApps: Bool = false
    @Published var appsToClose: [AppEntry] = []       // bundle IDs to close
    @Published var useAppleWatchUnlock: Bool = false
    @Published var showBlurOverlay: Bool = true

    private var overlayController: OverlayWindowController?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup
    func setup() {
        loadSettings()
        // Persist on every change
        $lockOnAppSwitch.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $autoLockOnIdle.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $idleTimeoutSeconds.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $autoLockOnSleep.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $closeAppsOnSleep.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $autoCloseSelectedApps.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $useAppleWatchUnlock.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $showBlurOverlay.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
    }

    // MARK: - Lock
    func lock(reason: LockReason = .manual) {
        guard !isLocked else { return }
        guard LicenseManager.shared.isLicensed else {
            postNotification("AppLocker: License required to lock.")
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isLocked = true

            if self.showBlurOverlay {
                self.showOverlay()
            }

            if self.autoCloseSelectedApps || (reason == .sleep && self.closeAppsOnSleep) {
                self.terminateSelectedApps()
            }
        }
    }

    // MARK: - Unlock
    func unlock() {
        AuthenticationManager.shared.authenticate { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isLocked = false
                    self?.hideOverlay()
                } else if let error {
                    print("Auth failed: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Called by Apple Watch / WatchConnectivity
    func unlockFromWatch() {
        guard useAppleWatchUnlock else { return }
        DispatchQueue.main.async { [weak self] in
            self?.isLocked = false
            self?.hideOverlay()
        }
    }

    // MARK: - Overlay
    private func showOverlay() {
        if overlayController == nil {
            overlayController = OverlayWindowController()
        }
        overlayController?.show()
    }

    func hideOverlay() {
        overlayController?.hide()
    }

    // MARK: - App termination
    func terminateSelectedApps() {
        let bundleIDs = Set(appsToClose.map(\.bundleID))
        NSWorkspace.shared.runningApplications.forEach { app in
            if let id = app.bundleIdentifier, bundleIDs.contains(id) {
                app.terminate()
            }
        }
    }

    // MARK: - Persistence
    private let defaults = UserDefaults.standard

    func loadSettings() {
        lockOnAppSwitch       = defaults.bool(forKey: Keys.lockOnAppSwitch)
        autoLockOnIdle        = defaults.optionalBool(forKey: Keys.autoLockOnIdle) ?? true
        idleTimeoutSeconds    = defaults.integer(forKey: Keys.idleTimeout) > 0
                                    ? defaults.integer(forKey: Keys.idleTimeout) : 300
        autoLockOnSleep       = defaults.optionalBool(forKey: Keys.autoLockOnSleep) ?? true
        closeAppsOnSleep      = defaults.bool(forKey: Keys.closeAppsOnSleep)
        autoCloseSelectedApps = defaults.bool(forKey: Keys.autoCloseApps)
        useAppleWatchUnlock   = defaults.bool(forKey: Keys.watchUnlock)
        showBlurOverlay       = defaults.optionalBool(forKey: Keys.blurOverlay) ?? true

        if let data = defaults.data(forKey: Keys.appsToClose),
           let apps = try? JSONDecoder().decode([AppEntry].self, from: data) {
            appsToClose = apps
        }
    }

    func saveSettings() {
        defaults.set(lockOnAppSwitch,       forKey: Keys.lockOnAppSwitch)
        defaults.set(autoLockOnIdle,        forKey: Keys.autoLockOnIdle)
        defaults.set(idleTimeoutSeconds,    forKey: Keys.idleTimeout)
        defaults.set(autoLockOnSleep,       forKey: Keys.autoLockOnSleep)
        defaults.set(closeAppsOnSleep,      forKey: Keys.closeAppsOnSleep)
        defaults.set(autoCloseSelectedApps, forKey: Keys.autoCloseApps)
        defaults.set(useAppleWatchUnlock,   forKey: Keys.watchUnlock)
        defaults.set(showBlurOverlay,       forKey: Keys.blurOverlay)

        if let data = try? JSONEncoder().encode(appsToClose) {
            defaults.set(data, forKey: Keys.appsToClose)
        }
    }

    private enum Keys {
        static let lockOnAppSwitch  = "al_lockOnAppSwitch"
        static let autoLockOnIdle   = "al_autoLockOnIdle"
        static let idleTimeout      = "al_idleTimeout"
        static let autoLockOnSleep  = "al_autoLockOnSleep"
        static let closeAppsOnSleep = "al_closeAppsOnSleep"
        static let autoCloseApps    = "al_autoCloseApps"
        static let appsToClose      = "al_appsToClose"
        static let watchUnlock      = "al_watchUnlock"
        static let blurOverlay      = "al_blurOverlay"
    }

    private func postNotification(_ msg: String) {
        let n = NSUserNotification()
        n.title = "AppLocker"
        n.informativeText = msg
        NSUserNotificationCenter.default.deliver(n)
    }
}

// MARK: - Supporting Types
enum LockReason { case manual, appSwitch, idle, sleep }

struct AppEntry: Identifiable, Codable, Hashable {
    var id: String { bundleID }
    let bundleID: String
    let name: String
    let iconData: Data?
}

// MARK: - UserDefaults helper
extension UserDefaults {
    func optionalBool(forKey key: String) -> Bool? {
        guard object(forKey: key) != nil else { return nil }
        return bool(forKey: key)
    }
}
