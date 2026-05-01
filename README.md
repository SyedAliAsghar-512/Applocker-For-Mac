# AppLocker for Mac (Starter)

This repo contains **starter SwiftUI code** for a menubar AppLocker on macOS 13–26.
It **blocks only locked apps** and requires **Touch ID** with **custom password fallback** to unlock.

> ⚠️ This is a starter project, not a full commercial product. It uses post‑launch termination + immediate relaunch after auth (App Store–friendly). A true pre‑launch block requires a system extension.

## Features
- Menubar app
- Per‑app lock rules
- Touch ID with custom password fallback
- Persistent rules in Application Support
- Configurable unlock timeout
- Admin‑gated rule changes (auth required)

---

## Project Structure
```
AppLocker/
  AppLockerApp.swift
  AppMonitor.swift
  AuthManager.swift
  CustomPasswordUI.swift
  Keychain.swift
  RulesStore.swift
  RulesView.swift
LaunchAgents/
  com.example.applocker.plist
README.md
```

---

## How to Run in Xcode
1. **Create a new Xcode project**
   - macOS App > SwiftUI > Swift
   - Product Name: `AppLocker`
2. Replace the generated Swift files with the contents from the `AppLocker/` folder in this repo.
3. Set your **bundle identifier** to `com.example.applocker` (or update code + plist if you change it).
4. Build & run.

---

## Auto‑Start on Login (LaunchAgent)
Copy `LaunchAgents/com.example.applocker.plist` to:
```
~/Library/LaunchAgents/
```
Then load it:
```bash
launchctl load ~/Library/LaunchAgents/com.example.applocker.plist
```

---

## Custom Password Setup
Use the UI in the app menu:
- “Set Custom Password”
- Stored in Keychain

---

## Build & Create DMG
1. Build the app in Xcode (Product > Archive or Build)
2. Locate the `.app` (typically in `~/Library/Developer/Xcode/DerivedData/.../Build/Products/Release/AppLocker.app`)
3. Create DMG:
```bash
hdiutil create -volname AppLocker -srcfolder /path/to/AppLocker.app -ov -format UDZO AppLocker.dmg
```

---

## Create ZIP
```bash
ditto -c -k --sequesterRsrc --keepParent /path/to/AppLocker.app AppLocker.zip
```

---

## Notes
- This design **terminates locked apps immediately** and prompts for auth.
- After auth, it relaunches the app and allows it for a timeout window.
- For strict pre‑launch blocking, a system extension is required.
