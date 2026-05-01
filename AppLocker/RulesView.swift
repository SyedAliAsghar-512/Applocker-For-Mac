import SwiftUI

struct RulesView: View {
    @EnvironmentObject var rules: RulesStore
    private let auth = AuthManager()

    @State private var showPasswordSet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Locked Apps")
                .font(.headline)

            if rules.lockedApps.isEmpty {
                Text("No locked apps yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rules.lockedApps) { app in
                    HStack {
                        Text(app.name)
                        Spacer()
                        Button("Remove") {
                            auth.requireAdminAuth(reason: "Authorize removing locked app") { ok in
                                if ok { rules.remove(app: app) }
                            }
                        }
                    }
                }
            }

            Divider()

            Button("Add App to Lock") { addApp() }
            Button("Set Custom Password") { setPassword() }

            Divider()

            HStack {
                Text("Unlock Timeout (minutes)")
                Spacer()
                Stepper(value: timeoutBinding, in: 1...240) {
                    Text("\(timeoutBinding.wrappedValue)")
                }
                .frame(width: 160)
            }
        }
        .padding(12)
        .frame(width: 320)
    }

    private var timeoutBinding: Binding<Int> {
        Binding(
            get: { UserDefaults.standard.integer(forKey: "unlockTimeoutMinutes") },
            set: { UserDefaults.standard.set($0, forKey: "unlockTimeoutMinutes") }
        )
    }

    private func addApp() {
        auth.requireAdminAuth(reason: "Authorize adding locked app") { ok in
            guard ok else { return }
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.application]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if panel.runModal() == .OK, let url = panel.url {
                let bundle = Bundle(url: url)
                let id = bundle?.bundleIdentifier ?? url.lastPathComponent
                let name = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? url.deletingPathExtension().lastPathComponent

                rules.add(app: LockedApp(id: id, name: name, path: url.path))
            }
        }
    }

    private func setPassword() {
        auth.requireAdminAuth(reason: "Authorize setting custom password") { ok in
            guard ok else { return }
            CustomPasswordUI.promptAndSave()
        }
    }
}
