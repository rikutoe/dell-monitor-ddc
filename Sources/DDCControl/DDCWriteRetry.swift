import Foundation

/// Timing and retry values for a DDC write command.
struct DDCWritePolicy {
    let operationDelay: UInt32
    let writeCycles: Int
    let maximumRetries: Int
    let retryDelay: UInt32

    static let standard = DDCWritePolicy(
        operationDelay: 10_000,
        writeCycles: 2,
        maximumRetries: 4,
        retryDelay: 20_000
    )
}

/// Executes DDC write cycles while tolerating transient I2C failures.
enum DDCWriteRetry {
    /// Returns the last I2C failure status after exhausting retries, or nil on success.
    static func perform(
        policy: DDCWritePolicy,
        operation: () -> Int32,
        sleep: (UInt32) -> Void
    ) -> Int32? {
        let cycles = max(policy.writeCycles, 1)
        let retries = max(policy.maximumRetries, 0)
        var lastFailure: Int32?

        for attempt in 0...retries {
            var didSucceed = false

            for _ in 0..<cycles {
                sleep(policy.operationDelay)
                let status = operation()
                if status == 0 {
                    didSucceed = true
                } else {
                    lastFailure = status
                }
            }

            if didSucceed {
                return nil
            }

            if attempt < retries {
                sleep(policy.retryDelay)
            }
        }

        return lastFailure
    }
}
