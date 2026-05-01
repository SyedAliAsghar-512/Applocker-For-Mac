import Foundation
import IOKit.pwr_mgt
import IOKit

/// Observes system sleep and wake events via IOKit.
class SleepWatcher {
    static let shared = SleepWatcher()
    private init() {}

    private var notificationPort: IONotificationPortRef?
    private var sleepNotifier: io_object_t = 0
    private var rootPort: io_connect_t = 0

    func startWatching() {
        rootPort = IORegisterForSystemPower(
            Unmanaged.passRetained(self).toOpaque(),
            &notificationPort,
            sleepWakeCallback,
            &sleepNotifier
        )

        guard rootPort != 0, let port = notificationPort else {
            print("AppLocker: Could not register for sleep/wake notifications.")
            return
        }

        let runLoopSource = IONotificationPortGetRunLoopSource(port).takeRetainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    }

    func stopWatching() {
        if sleepNotifier != 0 { IOObjectRelease(sleepNotifier); sleepNotifier = 0 }
        if rootPort != 0 { IOServiceClose(rootPort); rootPort = 0 }
        if let port = notificationPort { IONotificationPortDestroy(port); notificationPort = nil }
    }
}

// C-compatible callback (cannot use closures)
private let sleepWakeCallback: IOServiceInterestCallback = { refcon, service, messageType, messageArgument in
    guard let refcon else { return }
    let watcher = Unmanaged<SleepWatcher>.fromOpaque(refcon).takeUnretainedValue()

    switch messageType {
    case UInt32(kIOMessageSystemWillSleep):
        watcher.handleWillSleep(service: service)
        IOAllowPowerChange(watcher.rootPort, Int(bitPattern: messageArgument))

    case UInt32(kIOMessageSystemHasPoweredOn):
        watcher.handleDidWake()

    default:
        IOAllowPowerChange(watcher.rootPort, Int(bitPattern: messageArgument))
    }
}

private extension SleepWatcher {
    func handleWillSleep(service: io_service_t) {
        DispatchQueue.main.async {
            let mgr = LockManager.shared
            if mgr.autoLockOnSleep {
                mgr.lock(reason: .sleep)
            } else if mgr.closeAppsOnSleep {
                mgr.terminateSelectedApps()
            }
        }
    }

    func handleDidWake() {
        // Wake: overlay stays until user authenticates (handled by overlay UI)
        DispatchQueue.main.async {
            if LockManager.shared.isLocked {
                LockManager.shared.unlock()
            }
        }
    }
}
