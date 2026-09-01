/// Pure state machine for avoiding repeated DDC/CI writes after a confirmed failure.
struct DisplayControlMode: Equatable {
    private(set) var usesSoftwareFallback = false

    var shouldAttemptDDC: Bool { !usesSoftwareFallback }

    /// Returns true only for the transition that begins fallback mode.
    mutating func beginSoftwareFallback() -> Bool {
        guard !usesSoftwareFallback else { return false }
        usesSoftwareFallback = true
        return true
    }

    mutating func didSucceedWithDDC() {
        usesSoftwareFallback = false
    }

    mutating func resetForReconnect() {
        usesSoftwareFallback = false
    }
}
