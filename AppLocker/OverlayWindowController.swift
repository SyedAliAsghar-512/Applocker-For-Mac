import AppKit
import SwiftUI

/// Creates a full-screen blur overlay on every connected display.
/// Uses NSPanel (not NSWindow) so there is zero content flash — the blur
/// covers content before the compositor can draw it.
class OverlayWindowController {
    private var panels: [NSPanel] = []

    func show() {
        NSScreen.screens.forEach { screen in
            let panel = makePanel(for: screen)
            panel.orderFrontRegardless()
            panels.append(panel)
        }
        // Screen connection changes
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func hide() {
        panels.forEach { $0.close() }
        panels.removeAll()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screensChanged() {
        // Re-cover any newly connected displays
        let coveredFrames = Set(panels.map(\.frame))
        NSScreen.screens.forEach { screen in
            if !coveredFrames.contains(screen.frame) {
                let panel = makePanel(for: screen)
                panel.orderFrontRegardless()
                panels.append(panel)
            }
        }
    }

    // MARK: - Panel factory
    private func makePanel(for screen: NSScreen) -> NSPanel {
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level                  = .screenSaver          // above everything
        panel.collectionBehavior     = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isOpaque               = false
        panel.backgroundColor        = .clear
        panel.hasShadow              = false
        panel.ignoresMouseEvents     = false
        panel.acceptsMouseMovedEvents = true
        panel.setFrame(screen.frame, display: true)

        // Host SwiftUI lock view
        let hostingView = NSHostingView(
            rootView: LockOverlayView()
                .environmentObject(LockManager.shared)
                .environmentObject(LicenseManager.shared)
        )
        hostingView.frame = panel.contentView?.bounds ?? screen.frame
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        return panel
    }
}
