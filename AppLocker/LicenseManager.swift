import Foundation
import Security
import CryptoKit

/// Manages license key validation for the paid app.
/// Replace `validateOnServer` with your real license server endpoint.
class LicenseManager: ObservableObject {
    static let shared = LicenseManager()
    private init() { load() }

    @Published var isLicensed: Bool = false
    @Published var licenseKey: String = ""
    @Published var licenseStatus: LicenseStatus = .notActivated
    @Published var customerName: String = ""

    enum LicenseStatus {
        case notActivated, validating, valid, invalid, networkError
        var message: String {
            switch self {
            case .notActivated: return "Enter your license key to unlock all features."
            case .validating:   return "Validating…"
            case .valid:        return "✓ License active"
            case .invalid:      return "✗ Invalid license key"
            case .networkError: return "Could not reach license server. Try again."
            }
        }
    }

    // MARK: - Activate
    func activate(key: String) async {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        await MainActor.run { licenseStatus = .validating }

        // 1. Local format check  (format: ALCK-XXXX-XXXX-XXXX-XXXX)
        guard isValidFormat(trimmed) else {
            await MainActor.run { licenseStatus = .invalid }
            return
        }

        // 2. Remote validation (replace URL with your Gumroad/Paddle/custom endpoint)
        let activated = await validateOnServer(key: trimmed)

        await MainActor.run {
            if activated {
                licenseKey    = trimmed
                isLicensed    = true
                licenseStatus = .valid
                save()
            } else {
                licenseStatus = .invalid
            }
        }
    }

    func deactivate() {
        licenseKey    = ""
        isLicensed    = false
        licenseStatus = .notActivated
        customerName  = ""
        save()
    }

    // MARK: - Format check
    private func isValidFormat(_ key: String) -> Bool {
        // Expected: ALCK-XXXX-XXXX-XXXX-XXXX  (4-4-4-4-4 segments)
        let parts = key.components(separatedBy: "-")
        guard parts.count == 5, parts[0] == "ALCK" else { return false }
        return parts.dropFirst().allSatisfy { $0.count == 4 }
    }

    // MARK: - Server validation
    /// Replace this with a real Gumroad / LemonSqueezy / Paddle license check.
    private func validateOnServer(key: String) async -> Bool {
        // ── DEMO: accept any correctly-formatted key offline ──
        // Remove this in production and use real server validation.
        return isValidFormat(key)
    }

    // MARK: - Persistence (Keychain)
    private let keychainKey = "com.yourcompany.AppLocker.licenseKey"
    private let keychainService = "AppLocker"

    private func save() {
        let data = licenseKey.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String:   data
        ]
        SecItemDelete(query as CFDictionary)
        if !licenseKey.isEmpty { SecItemAdd(query as CFDictionary, nil) }
        UserDefaults.standard.set(isLicensed, forKey: "al_isLicensed")
    }

    private func load() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let key = String(data: data, encoding: .utf8), !key.isEmpty else { return }

        licenseKey    = key
        isLicensed    = UserDefaults.standard.bool(forKey: "al_isLicensed")
        licenseStatus = isLicensed ? .valid : .notActivated
    }
}
