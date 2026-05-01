import Foundation
import LocalAuthentication

final class AuthManager {
    func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        let ctx = LAContext()
        var error: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async { completion(success) }
            }
        } else {
            DispatchQueue.main.async { completion(CustomPasswordUI.promptAndValidate()) }
        }
    }

    func requireAdminAuth(reason: String, completion: @escaping (Bool) -> Void) {
        authenticate(reason: reason, completion: completion)
    }
}
