import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var lockMgr: LockManager
    @EnvironmentObject var licenseMgr: LicenseManager

    @State private var licenseInput: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AppLocker Settings")
                .font(.title2)

            GroupBox("Security") {
                Toggle("Lock on app switch", isOn: $lockMgr.lockOnAppSwitch)
                Toggle("Auto lock on idle", isOn: $lockMgr.autoLockOnIdle)
                HStack {
                    Text("Idle timeout (seconds)")
                    Spacer()
                    Stepper(value: $lockMgr.idleTimeoutSeconds, in: 30...3600, step: 30) {
                        Text("\(lockMgr.idleTimeoutSeconds)")
                    }
                    .frame(width: 200)
                }
                Toggle("Auto lock on sleep", isOn: $lockMgr.autoLockOnSleep)
                Toggle("Show blur overlay", isOn: $lockMgr.showBlurOverlay)
            }

            GroupBox("App Auto-Close") {
                Toggle("Close selected apps", isOn: $lockMgr.autoCloseSelectedApps)
                Toggle("Close apps on sleep", isOn: $lockMgr.closeAppsOnSleep)

                if !lockMgr.appsToClose.isEmpty {
                    ForEach(lockMgr.appsToClose) { app in
                        HStack {
                            if let data = app.iconData, let image = NSImage(data: data) {
                                Image(nsImage: image)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            }
                            Text(app.name)
                            Spacer()
                            Button("Remove") {
                                lockMgr.appsToClose.removeAll { $0.id == app.id }
                            }
                        }
                    }
                }

                Button("Add App…") { addApp() }
            }

            GroupBox("Apple Watch Unlock") {
                Toggle("Enable Apple Watch unlock", isOn: $lockMgr.useAppleWatchUnlock)
            }

            GroupBox("License") {
                Text(licenseMgr.licenseStatus.message)
                    .foregroundStyle(licenseMgr.isLicensed ? .green : .secondary)

                HStack {
                    TextField("License key", text: $licenseInput)
                    Button("Activate") {
                        Task { await licenseMgr.activate(key: licenseInput) }
                    }
                }

                if licenseMgr.isLicensed {
                    Button("Deactivate") { licenseMgr.deactivate() }
                }
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func addApp() {
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
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            let iconData = icon.tiffRepresentation

            let entry = AppEntry(bundleID: id, name: name, iconData: iconData)
            if !lockMgr.appsToClose.contains(entry) {
                lockMgr.appsToClose.append(entry)
            }
        }
    }
}
