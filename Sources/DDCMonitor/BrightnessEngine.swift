import Foundation
import DDCControl

/// Manages brightness and contrast values, applying changes to the display.
final class BrightnessEngine {
    private(set) var brightness: Int = 30
    private(set) var contrast: Int = 39
    private var display: DDCDisplay?

    let step = 5
    let minValue = 0
    let maxValue = 100

    /// Called when values change (for UI updates).
    var onValueChanged: ((Int, Int) -> Void)?

    func setUp() {
        display = DDCDisplay.enumerate().first
        if display == nil {
            NSLog("BrightnessEngine: No external display found")
        }
    }

    /// Increase brightness and contrast by one step.
    func increment() {
        adjust(by: step)
    }

    /// Decrease brightness and contrast by one step.
    func decrement() {
        adjust(by: -step)
    }

    func adjust(by delta: Int) {
        let newBrightness = clamp(brightness + delta)
        let newContrast = clamp(contrast + delta)

        guard let display else { return }

        do {
            try display.setBrightness(newBrightness)
            brightness = newBrightness
        } catch {
            NSLog("BrightnessEngine: brightness write error: %@", error.localizedDescription)
        }

        do {
            try display.setContrast(newContrast)
            contrast = newContrast
        } catch {
            NSLog("BrightnessEngine: contrast write error: %@", error.localizedDescription)
        }

        onValueChanged?(brightness, contrast)
    }

    private func clamp(_ value: Int) -> Int {
        max(minValue, min(maxValue, value))
    }
}
