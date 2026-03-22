import SwiftUI

@main
struct DDCMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("DDC Monitor", systemImage: "sun.max.fill") {
            MenuBarView(engine: appDelegate.engine)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let engine = BrightnessEngine()
    private let hotkeyManager = HotkeyManager()
    private let osdManager = OSDManager()

    private static let buildTimestamp: String = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return fmt.string(from: Date())
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLog.log("=== DDCMonitor launched at \(Self.buildTimestamp) ===")
        AppLog.log("AXIsProcessTrusted = \(AXIsProcessTrusted())")
        engine.setUp()

        engine.onValueChanged = { [weak self] brightness, _ in
            self?.osdManager.show(kind: .brightness, value: brightness)
        }
        engine.onVolumeChanged = { [weak self] volume in
            self?.osdManager.show(kind: .volume, value: volume)
        }

        // Brightness: F1/F2/F14/F15 — only when cursor is on external display
        hotkeyManager.onBrightnessDown = { [weak self] in
            self?.engine.decrement() ?? false
        }
        hotkeyManager.onBrightnessUp = { [weak self] in
            self?.engine.increment() ?? false
        }

        // Volume: only when audio output is routed to external display
        hotkeyManager.onVolumeDown = { [weak self] in
            guard AudioOutputRouter.isOutputOnExternalDisplay() else { return false }
            return self?.engine.volumeDecrement() ?? false
        }
        hotkeyManager.onVolumeUp = { [weak self] in
            guard AudioOutputRouter.isOutputOnExternalDisplay() else { return false }
            return self?.engine.volumeIncrement() ?? false
        }
        hotkeyManager.onMute = { [weak self] in
            guard AudioOutputRouter.isOutputOnExternalDisplay() else { return false }
            return self?.engine.volumeToggleMute() ?? false
        }

        hotkeyManager.start()
    }
}
