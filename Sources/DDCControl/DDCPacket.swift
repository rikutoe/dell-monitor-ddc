import Foundation

public enum VCPCode: UInt8, Sendable {
    case brightness = 0x10
    case contrast = 0x12
    case volume = 0x62
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

    /// Parse a DDC GET VCP reply and extract the current value.
    ///
    /// Scans for length byte `0x88` followed by opcode `0x02` to handle
    /// responses with or without the source address prefix.
    public static func parseReadReply(_ data: [UInt8], expectedVCP: UInt8) throws -> UInt16 {
        // Find DDC reply start: length byte (0x88) + opcode (0x02)
        var offset = -1
        for i in 0..<(data.count - 1) {
            if data[i] == 0x88 && data[i + 1] == 0x02 {
                offset = i
                break
            }
        }

        guard offset >= 0, offset + 9 < data.count else {
            let hex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            NSLog("DDCControl: Invalid read response: %@", hex)
            throw DDCError.invalidResponse
        }

        // Layout relative to length byte:
        // [0] 0x88  length    [1] 0x02  opcode
        // [2] result code     [3] VCP opcode
        // [4] type code       [5] max high
        // [6] max low         [7] present high
        // [8] present low     [9] checksum
        let resultCode = data[offset + 2]
        guard resultCode == 0x00 else {
            NSLog("DDCControl: VCP error result code: %d", resultCode)
            throw DDCError.invalidResponse
        }

        let currentValue = (UInt16(data[offset + 7]) << 8) | UInt16(data[offset + 8])
        return currentValue
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
