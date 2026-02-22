import AppKit

/// Controls OSD window show/hide with auto-fadeout timer.
final class OSDManager {
    private let window = OSDWindow()
    private var hideTimer: Timer?

    /// Auto-fadeout delay in seconds.
    private let fadeDelay: TimeInterval = 1.5

    func show(value: Int, maxValue: Int = 100) {
        hideTimer?.invalidate()
        window.show(value: value, maxValue: maxValue)

        hideTimer = Timer.scheduledTimer(withTimeInterval: fadeDelay, repeats: false) { [weak self] _ in
            self?.window.fadeOut()
        }
    }
}
