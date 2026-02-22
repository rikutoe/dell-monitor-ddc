import Foundation

public enum VCPCode: UInt8, Sendable {
    case brightness = 0x10
    case contrast = 0x12
}

public struct DDCPacket: Sendable {
    /// I2C 7-bit chip address for DDC displays
    public static let chipAddress: UInt32 = 0x37
    /// Default I2C data address (source address)
    public static let defaultInputAddress: UInt8 = 0x51
    /// Destination address = chipAddress << 1
    static let destinationAddress: UInt8 = 0x6E

    /// Build a DDC SET VCP write packet.
    ///
    /// Packet layout: [0x84, 0x03, vcp, valueHigh, valueLow, checksum]
    /// Checksum initial = 0x6E ^ inputAddress, then XOR all data bytes.
    public static func makeWritePacket(vcp: UInt8, value: UInt16) -> [UInt8] {
        var data: [UInt8] = [
            0x84,
            0x03,
            vcp,
            UInt8(value >> 8),
            UInt8(value & 0xFF),
            0x00,
        ]
        data[5] = xorChecksum(
            initial: destinationAddress ^ defaultInputAddress,
            data: data,
            range: 0...4
        )
        return data
    }

    /// Build a DDC GET VCP read request packet.
    ///
    /// Packet layout: [0x82, 0x01, vcp, checksum]
    /// Checksum initial = 0x6E, then XOR all data bytes.
    public static func makeReadPacket(vcp: UInt8) -> [UInt8] {
        var data: [UInt8] = [
            0x82,
            0x01,
            vcp,
            0x00,
        ]
        data[3] = xorChecksum(
            initial: destinationAddress,
            data: data,
            range: 0...2
        )
        return data
    }

    /// XOR checksum over a range of bytes with an initial value.
    public static func xorChecksum(initial: UInt8, data: [UInt8], range: ClosedRange<Int>) -> UInt8 {
        var chk = initial
        for i in range {
            chk ^= data[i]
        }
        return chk
    }
}
