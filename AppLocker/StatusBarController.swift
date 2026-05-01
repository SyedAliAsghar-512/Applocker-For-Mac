import AppKit
import SwiftUI
import Combine

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        buildMenu()
        updateIcon(locked: LockManager.shared.isLocked)

        // React to lock state
        LockManager.shared.$isLocked
            .receive(on: DispatchQueue.main)
            .sink { [weak self] locked in
                self?.updateIcon(locked: locked)
                self?.buildMenu()
            }
            .store(in: &cancellables)
    }

    // MARK: - Icon
    private func updateIcon(locked: Bool) {
        let name = locked ? "lock.fill" : "lock.open.fill"
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: name, accessibilityDescription: "AppLocker")
            btn.image?.isTemplate = true
        }
    }

    // MARK: - Menu
    private func buildMenu() {
        let menu = NSMenu()
        let locked = LockManager.shared.isLocked

        let lockItem = NSMenuItem(
            title: locked ? "🔓  Unlock Mac" : "🔒  Lock Now",
            action: locked ? #selector(handleUnlock) : #selector(handleLock),
            keyEquivalent: locked ? "" : "l"
        )
        lockItem.keyEquivalentModifierMask = [.command, .shift]
        lockItem.target = self
        menu.addItem(lockItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit AppLocker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func handleLock() {
        LockManager.shared.lock(reason: .manual)
    }

    @objc private func handleUnlock() {
        LockManager.shared.unlock()
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
