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

    var step: Int { settings.step }
    var minValue: Int { 0 }
    var maxValue: Int { 100 }

    /// Called when values change (for UI updates).
    var onValueChanged: ((Int, Int) -> Void)?

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

    /// Increase brightness and contrast by one step.
    @discardableResult
    func increment() -> Bool {
        guard CursorRouter.isCursorOnExternalDisplay() else { return false }
        let bNew = clampBrightness(brightness + step)
        let cNew = clampContrast(contrast + step)
        applyBoth(brightness: bNew, contrast: cNew)
        return true
    }

    /// Decrease brightness and contrast by one step.
    @discardableResult
    func decrement() -> Bool {
        guard CursorRouter.isCursorOnExternalDisplay() else { return false }
        let bNew = clampBrightness(brightness - step)
        let cNew = clampContrast(contrast - step)
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

    /// Adjust both brightness and contrast together (hotkey).
    func adjust(by delta: Int) {
        let bNew = clampBrightness(brightness + delta)
        let cNew = clampContrast(contrast + delta)
        applyBoth(brightness: bNew, contrast: cNew)
    }

    private func applyBoth(brightness bNew: Int, contrast cNew: Int) {
        if withReconnect({ try $0.setBrightness(bNew) }) {
            brightness = bNew
            settings.lastBrightness = bNew
        }
        if withReconnect({ try $0.setContrast(cNew) }) {
            contrast = cNew
            settings.lastContrast = cNew
        }
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
