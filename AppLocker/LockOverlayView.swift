import SwiftUI
import LocalAuthentication

/// Full-screen overlay shown when Mac is locked.
struct LockOverlayView: View {
    @EnvironmentObject var lockMgr: LockManager
    @State private var isAuthenticating = false
    @State private var authFailed = false
    @State private var shake = false
    @State private var pulseRing = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var currentTime = Date()

    var body: some View {
        ZStack {
            // ── Blur backdrop ──────────────────────────────────────
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            // Dark tint
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // ── Clock ──────────────────────────────────────────
                VStack(spacing: 6) {
                    Text(timeString)
                        .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()

                    Text(dateString)
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                // ── Lock icon + ring ───────────────────────────────
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2)
                        .foregroundStyle(.white.opacity(0.15))
                        .frame(width: 110, height: 110)
                        .scaleEffect(pulseRing ? 1.12 : 1.0)
                        .opacity(pulseRing ? 0 : 0.6)
                        .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false), value: pulseRing)

                    Image(systemName: authFailed ? "xmark.shield.fill" : "lock.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(authFailed ? .red : .white)
                        .symbolRenderingMode(.hierarchical)
                        .offset(x: shake ? -8 : 0)
                        .animation(shake ? .default.repeatCount(4, autoreverses: true).speed(6) : .default, value: shake)
                }

                // ── Touch ID button ────────────────────────────────
                Button(action: triggerAuth) {
                    HStack(spacing: 10) {
                        Image(systemName: "touchid")
                            .font(.system(size: 20))
                        Text(isAuthenticating ? "Authenticating…" : "Unlock with Touch ID")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.12), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isAuthenticating)
                .keyboardShortcut(.return, modifiers: [])

                if authFailed {
                    Text("Authentication failed — try again")
                        .font(.system(size: 12))
                        .foregroundStyle(.red.opacity(0.85))
                        .transition(.opacity)
                }

                Spacer()

                // ── Bottom branding ────────────────────────────────
                Text("AppLocker  ·  Protected")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            pulseRing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                triggerAuth()
            }
        }
        .onReceive(timer) { _ in currentTime = Date() }
    }

    // MARK: - Actions
    private func triggerAuth() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authFailed = false

        AuthenticationManager.shared.authenticate { success, _ in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    lockMgr.isLocked = false
                    lockMgr.hideOverlay()
                } else {
                    authFailed = true
                    shake = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shake = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { authFailed = false }
                }
            }
        }
    }

    // MARK: - Helpers
    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: currentTime)
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: currentTime)
    }
}

// MARK: - Blur helper
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material    = material
        v.blendingMode = blendingMode
        v.state       = .active
        return v
    }

    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material     = material
        v.blendingMode = blendingMode
    }
}

#Preview {
    LockOverlayView()
        .environmentObject(LockManager.shared)
        .environmentObject(LicenseManager.shared)
        .frame(width: 800, height: 600)
}
