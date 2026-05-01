import Foundation
import IOKit

/// Polls IOKit for user idle time and triggers auto-lock.
class IdleMonitor {
    static let shared = IdleMonitor()
    private init() {}

    private var timer: Timer?
    private let pollInterval: TimeInterval = 10  // check every 10s

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.check()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func check() {
        let mgr = LockManager.shared
        guard mgr.autoLockOnIdle, !mgr.isLocked else { return }

        let idle = systemIdleSeconds()
        if idle >= Double(mgr.idleTimeoutSeconds) {
            mgr.lock(reason: .idle)
        }
    }

    /// Returns seconds since last user HID event.
    func systemIdleSeconds() -> Double {
        var iter: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDSystem"),
            &iter
        )
        guard result == KERN_SUCCESS else { return 0 }
        defer { IOObjectRelease(iter) }

        let entry = IOIteratorNext(iter)
        guard entry != 0 else { return 0 }
        defer { IOObjectRelease(entry) }

        var dict: Unmanaged<CFMutableDictionary>?
        let kr = IORegistryEntryCreateCFProperties(entry, &dict, kCFAllocatorDefault, 0)
        guard kr == KERN_SUCCESS, let cfDict = dict?.takeRetainedValue() as? [String: Any] else {
            return 0
        }

        guard let hidIdleTimeNs = cfDict["HIDIdleTime"] as? UInt64 else { return 0 }
        return Double(hidIdleTimeNs) / 1_000_000_000.0
    }

    /// Reset idle timer on any user activity (call this on mouse/key events if needed).
    func resetIdle() {
        // IOKit tracks this automatically — no action needed
    }
}
