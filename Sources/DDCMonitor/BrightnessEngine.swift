import Foundation
import Observation
import DDCControl
import AppKit

/// Manages brightness and contrast values, applying changes to the display.
@Observable
final class BrightnessEngine {
    var brightness: Int
    var contrast: Int
    var volume: Int
    /// Error message from the last display read attempt (nil = success).
    var lastReadError: String?
    private var display: DDCDisplay?
    private let settings = SettingsStore.shared

    init() {
        brightness = settings.lastBrightness ?? 50
        contrast = settings.lastContrast ?? 50
        volume = settings.lastVolume ?? 50
    }

    var minValue: Int { 0 }
    var maxValue: Int { 100 }

    /// Current normalized level (0.0 = min, 1.0 = max), derived from brightness.
    private var level: Double {
        let range = Double(settings.brightnessMax - settings.brightnessMin)
        guard range > 0 else { return 0 }
        return Double(brightness - settings.brightnessMin) / range
    }

    private var hotkeySteps: Int { settings.hotkeySteps }

    /// Current normalized volume level (0.0 = min, 1.0 = max).
    private var volumeLevel: Double {
        let range = Double(settings.volumeMax - settings.volumeMin)
        guard range > 0 else { return 0 }
        return Double(volume - settings.volumeMin) / range
    }

    /// Called when brightness/contrast change (for OSD).
    var onValueChanged: ((Int, Int) -> Void)?
    /// Called when volume changes (for OSD).
    var onVolumeChanged: ((Int) -> Void)?

    func setUp() {
        display = DDCDisplay.enumerate().first
        if display == nil {
            NSLog("BrightnessEngine: No external display found")
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenDidChange(_ note: Notification) {
        NSLog("BrightnessEngine: Screen configuration changed, reconnecting")
        reconnect()
    }

    /// Re-enumerate displays to pick up reconnected monitors.
    func reconnect() {
        display = DDCDisplay.enumerate().first
        if display != nil {
            NSLog("BrightnessEngine: Display reconnected")
        } else {
            NSLog("BrightnessEngine: No external display found after reconnect")
        }
    }

    /// Try to read current brightness/contrast from the display via DDC.
    /// Updates values on success, sets lastReadError on failure.
    func refreshFromDisplay() {
        lastReadError = nil

        if display == nil {
            reconnect()
        }
        guard let display else {
            lastReadError = DDCError.noExternalDisplay.localizedDescription
            return
        }

        do {
            let b = try display.getBrightness()
            let c = try display.getContrast()
            let v = try display.getVolume()
            brightness = b
            contrast = c
            volume = v
            settings.lastBrightness = b
            settings.lastContrast = c
            settings.lastVolume = v
            NSLog("BrightnessEngine: Read from display - brightness=%d, contrast=%d, volume=%d", b, c, v)
        } catch {
            NSLog("BrightnessEngine: Failed to read from display: %@", error.localizedDescription)
            lastReadError = error.localizedDescription
        }
    }

    /// Map a normalized level (0.0–1.0) to brightness and contrast values.
    private func valuesForLevel(_ lvl: Double) -> (brightness: Int, contrast: Int) {
        let clamped = max(0, min(1, lvl))
        let b = settings.brightnessMin + Int(round(clamped * Double(settings.brightnessMax - settings.brightnessMin)))
        let c = settings.contrastMin + Int(round(clamped * Double(settings.contrastMax - settings.contrastMin)))
        return (b, c)
    }

    /// Increase brightness and contrast by one step.
    @discardableResult
    func increment() -> Bool {
        let onExternal = CursorRouter.isCursorOnExternalDisplay()
        guard onExternal else { return false }
        let newLevel = min(1.0, level + 1.0 / Double(hotkeySteps))
        let (bNew, cNew) = valuesForLevel(newLevel)
        AppLog.log("[Engine] increment() level=\(String(format: "%.3f", level))→\(String(format: "%.3f", newLevel)) b=\(bNew) c=\(cNew)")
        applyBoth(brightness: bNew, contrast: cNew)
        return true
    }

    /// Decrease brightness and contrast by one step.
    @discardableResult
    func decrement() -> Bool {
        let onExternal = CursorRouter.isCursorOnExternalDisplay()
        guard onExternal else { return false }
        let newLevel = max(0.0, level - 1.0 / Double(hotkeySteps))
        let (bNew, cNew) = valuesForLevel(newLevel)
        AppLog.log("[Engine] decrement() level=\(String(format: "%.3f", level))→\(String(format: "%.3f", newLevel)) b=\(bNew) c=\(cNew)")
        applyBoth(brightness: bNew, contrast: cNew)
        return true
    }

    /// Set brightness directly (from slider). No OSD.
    func adjustBrightness(to value: Int) {
        let clamped = clampBrightness(value)
        let ok = withReconnect { try $0.setBrightness(clamped) }
        if ok {
            brightness = clamped
            settings.lastBrightness = clamped
        }
    }

    /// Set contrast directly (from slider). No OSD.
    func adjustContrast(to value: Int) {
        let clamped = clampContrast(value)
        let ok = withReconnect { try $0.setContrast(clamped) }
        if ok {
            contrast = clamped
            settings.lastContrast = clamped
        }
    }

    /// Set volume directly (from slider). No OSD.
    func adjustVolume(to value: Int) {
        let clamped = clampVolume(value)
        let ok = withReconnect { try $0.setVolume(clamped) }
        if ok {
            volume = clamped
            settings.lastVolume = clamped
        }
    }

    /// Adjust both brightness and contrast by a number of level steps.
    func adjust(bySteps delta: Int) {
        let newLevel = max(0, min(1, level + Double(delta) / Double(hotkeySteps)))
        let (bNew, cNew) = valuesForLevel(newLevel)
        applyBoth(brightness: bNew, contrast: cNew)
    }

    // MARK: - Volume hotkey control

    /// Increase volume by one step via DDC. Only call when audio output is external display.
    @discardableResult
    func volumeIncrement() -> Bool {
        let newLevel = min(1.0, volumeLevel + 1.0 / Double(hotkeySteps))
        let vNew = volumeForLevel(newLevel)
        AppLog.log("[Engine] volumeIncrement() level=\(String(format: "%.3f", volumeLevel))→\(String(format: "%.3f", newLevel)) v=\(vNew)")
        return applyVolume(vNew)
    }

    /// Decrease volume by one step via DDC.
    @discardableResult
    func volumeDecrement() -> Bool {
        let newLevel = max(0.0, volumeLevel - 1.0 / Double(hotkeySteps))
        let vNew = volumeForLevel(newLevel)
        AppLog.log("[Engine] volumeDecrement() level=\(String(format: "%.3f", volumeLevel))→\(String(format: "%.3f", newLevel)) v=\(vNew)")
        return applyVolume(vNew)
    }

    /// Toggle mute (set volume to 0, or restore previous).
    @discardableResult
    func volumeToggleMute() -> Bool {
        let vNew = volume > settings.volumeMin ? settings.volumeMin : (settings.lastVolume ?? 50)
        AppLog.log("[Engine] volumeToggleMute() \(volume)→\(vNew)")
        return applyVolume(vNew)
    }

    private func volumeForLevel(_ lvl: Double) -> Int {
        let clamped = max(0, min(1, lvl))
        return settings.volumeMin + Int(round(clamped * Double(settings.volumeMax - settings.volumeMin)))
    }

    private func applyVolume(_ vNew: Int) -> Bool {
        let ok = withReconnect { try $0.setVolume(vNew) }
        if ok {
            volume = vNew
            settings.lastVolume = vNew
        }
        AppLog.log("[Engine] setVolume(\(vNew)) ok=\(ok)")
        onVolumeChanged?(volume)
        return ok
    }

    /// DDC/CI needs a pause between consecutive I2C writes on the same bus.
    private static let interCommandDelay: useconds_t = 50_000  // 50ms

    private func applyBoth(brightness bNew: Int, contrast cNew: Int) {
        let bOk = withReconnect({ try $0.setBrightness(bNew) })
        if bOk {
            brightness = bNew
            settings.lastBrightness = bNew
        }
        AppLog.log("[Engine] setBrightness(\(bNew)) ok=\(bOk)")

        usleep(Self.interCommandDelay)

        let cOk = withReconnect({ try $0.setContrast(cNew) })
        if cOk {
            contrast = cNew
            settings.lastContrast = cNew
        }
        AppLog.log("[Engine] setContrast(\(cNew)) ok=\(cOk)")

        onValueChanged?(brightness, contrast)
    }

    /// Try a DDC operation; on failure, reconnect and retry once.
    private func withReconnect(_ operation: (DDCDisplay) throws -> Void) -> Bool {
        if let display {
            do {
                try operation(display)
                return true
            } catch {
                NSLog("BrightnessEngine: DDC write failed, reconnecting: %@",
                      error.localizedDescription)
            }
        }
        reconnect()
        guard let display else { return false }
        do {
            try operation(display)
            return true
        } catch {
            NSLog("BrightnessEngine: DDC write failed after reconnect: %@",
                  error.localizedDescription)
            return false
        }
    }

    private func clampBrightness(_ value: Int) -> Int {
        max(settings.brightnessMin, min(settings.brightnessMax, value))
    }

    private func clampContrast(_ value: Int) -> Int {
        max(settings.contrastMin, min(settings.contrastMax, value))
    }

    private func clampVolume(_ value: Int) -> Int {
        max(settings.volumeMin, min(settings.volumeMax, value))
    }
}
