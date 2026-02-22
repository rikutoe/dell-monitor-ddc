import Foundation

/// Represents an external display controllable via DDC/CI over IOAVService.
public final class DDCDisplay {
    private let service: IOAVServiceRef

    /// Delay between DDC I2C operations (microseconds).
    private static let ddcWait: UInt32 = 10_000
    /// Number of write cycles per command (some displays need multiple).
    private static let writeCycles = 2

    init(service: IOAVServiceRef) {
        self.service = service
    }

    /// Enumerate all connected external displays.
    public static func enumerate() -> [DDCDisplay] {
        findExternalAVServices().map { DDCDisplay(service: $0) }
    }

    /// Write a VCP value to the display.
    public func write(vcp: VCPCode, value: UInt16) throws {
        var packet = DDCPacket.makeWritePacket(vcp: vcp.rawValue, value: value)

        for i in 0..<Self.writeCycles {
            usleep(Self.ddcWait)
            let ret = avServiceWriteI2C(
                service,
                chipAddress: DDCPacket.chipAddress,
                dataAddress: UInt32(DDCPacket.defaultInputAddress),
                buffer: &packet
            )
            if ret != 0 {
                NSLog("DDCControl: I2C write failed (cycle %d, status %d)", i, ret)
                throw DDCError.i2cWriteFailed(ret)
            }
        }
    }

    /// Set brightness (0-100).
    public func setBrightness(_ value: Int) throws {
        NSLog("DDCControl: setBrightness(%d)", value)
        try write(vcp: .brightness, value: UInt16(clamping: value))
    }

    /// Set contrast (0-100).
    public func setContrast(_ value: Int) throws {
        NSLog("DDCControl: setContrast(%d)", value)
        try write(vcp: .contrast, value: UInt16(clamping: value))
    }
}
