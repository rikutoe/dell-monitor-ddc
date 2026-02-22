import Foundation
import Observation
import DDCControl

/// Manages brightness and contrast values, applying changes to the display.
@Observable
final class BrightnessEngine {
    var brightness: Int
    var contrast: Int
    private var display: DDCDisplay?
    private let settings = SettingsStore.shared

    init() {
        brightness = settings.lastBrightness ?? 50
        contrast = settings.lastContrast ?? 50
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
        guard let display else { return }
        do {
            try display.setBrightness(clamped)
            brightness = clamped
            settings.lastBrightness = clamped
        } catch {
            NSLog("BrightnessEngine: brightness error: %@", error.localizedDescription)
        }
    }

    /// Set contrast directly (from slider). No OSD.
    func adjustContrast(to value: Int) {
        let clamped = clampContrast(value)
        guard let display else { return }
        do {
            try display.setContrast(clamped)
            contrast = clamped
            settings.lastContrast = clamped
        } catch {
            NSLog("BrightnessEngine: contrast error: %@", error.localizedDescription)
        }
    }

    /// Adjust both brightness and contrast together (hotkey).
    func adjust(by delta: Int) {
        let bNew = clampBrightness(brightness + delta)
        let cNew = clampContrast(contrast + delta)
        applyBoth(brightness: bNew, contrast: cNew)
    }

    private func applyBoth(brightness bNew: Int, contrast cNew: Int) {
        guard let display else { return }
        do {
            try display.setBrightness(bNew)
            brightness = bNew
            settings.lastBrightness = bNew
        } catch {
            NSLog("BrightnessEngine: brightness error: %@", error.localizedDescription)
        }
        do {
            try display.setContrast(cNew)
            contrast = cNew
            settings.lastContrast = cNew
        } catch {
            NSLog("BrightnessEngine: contrast error: %@", error.localizedDescription)
        }
        onValueChanged?(brightness, contrast)
    }

    private func clampBrightness(_ value: Int) -> Int {
        max(settings.brightnessMin, min(settings.brightnessMax, value))
    }

    private func clampContrast(_ value: Int) -> Int {
        max(settings.contrastMin, min(settings.contrastMax, value))
    }
}
