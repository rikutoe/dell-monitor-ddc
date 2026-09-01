import Testing
@testable import DDCMonitor

@Suite("Display control mode")
struct DisplayControlModeTests {
    @Test("Failure enters fallback and prevents further DDC attempts")
    func fallbackStopsDDCAttempts() {
        var mode = DisplayControlMode()

        #expect(mode.shouldAttemptDDC)
        let beganFallback = mode.beginSoftwareFallback()
        #expect(beganFallback)
        #expect(!mode.shouldAttemptDDC)
        let beganFallbackAgain = mode.beginSoftwareFallback()
        #expect(!beganFallbackAgain)
    }

    @Test("Reconnect and DDC success resume DDC control")
    func reconnectAndSuccessClearFallback() {
        var mode = DisplayControlMode()
        _ = mode.beginSoftwareFallback()
        mode.resetForReconnect()
        #expect(mode.shouldAttemptDDC)

        _ = mode.beginSoftwareFallback()
        mode.didSucceedWithDDC()
        #expect(mode.shouldAttemptDDC)
    }
}
