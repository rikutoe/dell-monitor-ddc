import Testing
@testable import DDCControl

@Suite("DDC write retries")
struct DDCWriteRetryTests {
    @Test("Finishes all write cycles when an early cycle fails")
    func completesCyclesBeforeReportingSuccess() {
        let policy = DDCWritePolicy(operationDelay: 10, writeCycles: 2, maximumRetries: 4, retryDelay: 20)
        var statuses: [Int32] = [1, 0]
        var pauses: [UInt32] = []

        let failure = DDCWriteRetry.perform(policy: policy, operation: {
            statuses.removeFirst()
        }, sleep: { pauses.append($0) })

        #expect(failure == nil)
        #expect(statuses.isEmpty)
        #expect(pauses == [10, 10])
    }

    @Test("Retries a failed write cycle and succeeds later")
    func retriesAfterFailedCycle() {
        let policy = DDCWritePolicy(operationDelay: 10, writeCycles: 2, maximumRetries: 4, retryDelay: 20)
        var statuses: [Int32] = [1, 2, 3, 0]
        var pauses: [UInt32] = []

        let failure = DDCWriteRetry.perform(policy: policy, operation: {
            statuses.removeFirst()
        }, sleep: { pauses.append($0) })

        #expect(failure == nil)
        #expect(statuses.isEmpty)
        #expect(pauses == [10, 10, 20, 10, 10])
    }

    @Test("Returns the final status after four retries")
    func returnsFailureAfterRetryLimit() {
        let policy = DDCWritePolicy(operationDelay: 10, writeCycles: 2, maximumRetries: 4, retryDelay: 20)
        var statuses = Array(repeating: Int32(7), count: 10)
        var pauses: [UInt32] = []

        let failure = DDCWriteRetry.perform(policy: policy, operation: {
            statuses.removeFirst()
        }, sleep: { pauses.append($0) })

        #expect(failure == 7)
        #expect(statuses.isEmpty)
        #expect(pauses.filter { $0 == 10 }.count == 10)
        #expect(pauses.filter { $0 == 20 }.count == 4)
    }
}
