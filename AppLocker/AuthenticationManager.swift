import Foundation
import LocalAuthentication

/// Handles Touch ID, Face ID, and password fallback.
class AuthenticationManager {
    static let shared = AuthenticationManager()
    private init() {}

    typealias AuthCompletion = (Bool, Error?) -> Void

    /// Primary authentication entry point.
    /// Tries biometrics first; falls back to macOS password.
    func authenticate(completion: @escaping AuthCompletion) {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Password"
        context.touchIDAuthenticationAllowableReuseDuration = 0

        var error: NSError?
        let canEval = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)

        guard canEval else {
            // No biometrics and no password policy — allow unlock
            completion(true, nil)
            return
        }

        let reason = "Unlock AppLocker"
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, err in
            completion(success, err)
        }
    }

    /// Check if Touch ID hardware is available.
    var isTouchIDAvailable: Bool {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            return false
        }
        return ctx.biometryType == .touchID
    }

    /// Check if any biometry is enrolled.
    var isBiometryEnrolled: Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }
}
