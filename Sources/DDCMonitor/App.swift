import SwiftUI

@main
struct DDCMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("DDC Monitor", systemImage: "sun.max.fill") {
            MenuBarView(engine: appDelegate.engine)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let engine = BrightnessEngine()
    private let hotkeyManager = HotkeyManager()
    private let osdManager = OSDManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        engine.setUp()

        engine.onValueChanged = { [weak self] brightness, _ in
            self?.osdManager.show(value: brightness)
        }

        hotkeyManager.onF1 = { [weak self] in
            self?.engine.decrement()
        }
        hotkeyManager.onF2 = { [weak self] in
            self?.engine.increment()
        }
        hotkeyManager.start()
    }
}
