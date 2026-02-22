import Testing
@testable import DDCControl

@Suite("DDCPacket")
struct DDCPacketTests {

    @Test("Write packet for brightness=50")
    func writePacketBrightness50() {
        let packet = DDCPacket.makeWritePacket(vcp: 0x10, value: 50)
        #expect(packet.count == 6)
        #expect(packet[0] == 0x84) // header
        #expect(packet[1] == 0x03) // length
        #expect(packet[2] == 0x10) // VCP code (brightness)
        #expect(packet[3] == 0x00) // value high
        #expect(packet[4] == 0x32) // value low (50)
        // checksum = 0x6E ^ 0x51 ^ 0x84 ^ 0x03 ^ 0x10 ^ 0x00 ^ 0x32
        let expected: UInt8 = 0x6E ^ 0x51 ^ 0x84 ^ 0x03 ^ 0x10 ^ 0x00 ^ 0x32
        #expect(packet[5] == expected)
    }

    @Test("Write packet for contrast=75")
    func writePacketContrast75() {
        let packet = DDCPacket.makeWritePacket(vcp: 0x12, value: 75)
        #expect(packet[2] == 0x12) // VCP code (contrast)
        #expect(packet[3] == 0x00) // value high
        #expect(packet[4] == 0x4B) // value low (75)
        let expected: UInt8 = 0x6E ^ 0x51 ^ 0x84 ^ 0x03 ^ 0x12 ^ 0x00 ^ 0x4B
        #expect(packet[5] == expected)
    }

    @Test("Write packet for large value (256)")
    func writePacketLargeValue() {
        let packet = DDCPacket.makeWritePacket(vcp: 0x10, value: 256)
        #expect(packet[3] == 0x01) // value high
        #expect(packet[4] == 0x00) // value low
    }

    @Test("Read packet for brightness")
    func readPacketBrightness() {
        let packet = DDCPacket.makeReadPacket(vcp: 0x10)
        #expect(packet.count == 4)
        #expect(packet[0] == 0x82) // header
        #expect(packet[1] == 0x01) // length
        #expect(packet[2] == 0x10) // VCP code
        // checksum = 0x6E ^ 0x82 ^ 0x01 ^ 0x10
        let expected: UInt8 = 0x6E ^ 0x82 ^ 0x01 ^ 0x10
        #expect(packet[3] == expected)
    }

    @Test("Read packet for contrast")
    func readPacketContrast() {
        let packet = DDCPacket.makeReadPacket(vcp: 0x12)
        #expect(packet[2] == 0x12)
        let expected: UInt8 = 0x6E ^ 0x82 ^ 0x01 ^ 0x12
        #expect(packet[3] == expected)
    }

    @Test("XOR checksum basic")
    func xorChecksum() {
        let data: [UInt8] = [0xAA, 0x55, 0xFF]
        let result = DDCPacket.xorChecksum(initial: 0x00, data: data, range: 0...2)
        #expect(result == 0xAA ^ 0x55 ^ 0xFF)
    }

    @Test("XOR checksum with initial value")
    func xorChecksumWithInitial() {
        let data: [UInt8] = [0x10, 0x20]
        let result = DDCPacket.xorChecksum(initial: 0xFF, data: data, range: 0...1)
        #expect(result == 0xFF ^ 0x10 ^ 0x20)
    }
}
