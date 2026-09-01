import Testing
@testable import DDCMonitor

@Suite("Software display transfer")
struct SoftwareDisplayTransferTests {
    @Test("Minimum brightness retains visible output")
    func minimumBrightnessIsNotBlack() {
        let output = SoftwareDisplayTransfer.component(input: 1, brightness: 0, contrast: 50)

        #expect(output == SoftwareDisplayTransfer.minimumLuminance)
        #expect(output > 0)
    }

    @Test("Transfer table has equal RGB channels")
    func tableKeepsNeutralColors() {
        let table = SoftwareDisplayTransfer.table(brightness: 50, contrast: 50)

        #expect(table.red.count == SoftwareDisplayTransfer.tableSize)
        #expect(table.red == table.green)
        #expect(table.green == table.blue)
    }

    @Test("Higher contrast expands values around the midpoint")
    func contrastChangesSlope() {
        let low = SoftwareDisplayTransfer.component(input: 0.25, brightness: 100, contrast: 0)
        let high = SoftwareDisplayTransfer.component(input: 0.25, brightness: 100, contrast: 100)

        #expect(high < low)
    }

    @Test("Standard table is a linear identity mapping")
    func standardTableIsIdentity() {
        let table = SoftwareDisplayTransfer.standardTable()

        #expect(table.red.first == 0)
        #expect(table.red.last == 1)
        #expect(table.red[128] == Float(128) / Float(SoftwareDisplayTransfer.tableSize - 1))
    }
}
