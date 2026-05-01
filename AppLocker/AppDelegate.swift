import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as menu bar app only (no Dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Boot core manager
        LockManager.shared.setup()

        // Status bar
        statusBarController = StatusBarController()

        // Background monitors
        SleepWatcher.shared.startWatching()
        IdleMonitor.shared.start()
        AppMonitor.shared.start()

        // Watch-connectivity stub (requires WatchKit extension in full build)
        AppleWatchUnlockManager.shared.start()

        // First-launch: open settings if not licensed
        if !LicenseManager.shared.isLicensed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        SleepWatcher.shared.stopWatching()
        IdleMonitor.shared.stop()
        AppMonitor.shared.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
