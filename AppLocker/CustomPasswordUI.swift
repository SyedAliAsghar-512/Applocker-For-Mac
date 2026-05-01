import AppKit

enum CustomPasswordUI {
    static func promptAndSave() {
        let alert = NSAlert()
        alert.messageText = "Set Custom Password"
        alert.informativeText = "This password is used when Touch ID is unavailable."
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = field
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let pwd = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !pwd.isEmpty {
                Keychain.savePassword(pwd)
            }
        }
    }

    static func promptAndValidate() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Enter Custom Password"
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = field
        alert.addButton(withTitle: "Unlock")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let input = field.stringValue
            return input == Keychain.loadPassword()
        }
        return false
    }
}
