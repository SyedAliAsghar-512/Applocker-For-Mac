import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity

/// Listens for "unlock" messages from a paired Apple Watch.
/// Requires a companion WatchKit extension (see README for watch target setup).
class AppleWatchUnlockManager: NSObject, WCSessionDelegate {
    static let shared = AppleWatchUnlockManager()
    private override init() { super.init() }

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    /// Watch sends { "action": "unlock" } message when user lifts wrist near Mac.
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        guard let action = message["action"] as? String, action == "unlock" else { return }
        LockManager.shared.unlockFromWatch()
    }

    /// Detect wrist-raise unlock (proximity-based via watch heartbeat)
    func session(_ session: WCSession,
                 didReceiveApplicationContext context: [String: Any]) {
        if let cmd = context["cmd"] as? String, cmd == "wristUnlock" {
            LockManager.shared.unlockFromWatch()
        }
    }
}

#else
/// Stub for platforms without WatchConnectivity
class AppleWatchUnlockManager {
    static let shared = AppleWatchUnlockManager()
    private init() {}
    func start() {}
}
#endif
