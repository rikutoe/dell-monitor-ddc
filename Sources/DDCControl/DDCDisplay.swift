import Foundation

/// Represents an external display controllable via DDC/CI over IOAVService.
public final class DDCDisplay {
    private let service: IOAVServiceRef

    /// Delay between DDC I2C operations (microseconds).
    private static let ddcWait: UInt32 = 10_000
    /// Delay after sending a read request (microseconds).
    private static let readWait: UInt32 = 40_000
    /// Number of write cycles per command (some displays need multiple).
    private static let writeCycles = 2
    /// Response buffer size for DDC read replies.
    private static let readBufferSize = 12

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

    /// Read a VCP value from the display.
    /// Note: DDC reads can be unreliable on Apple Silicon.
    public func read(vcp: VCPCode) throws -> UInt16 {
        // Send GET VCP request
        var requestPacket = DDCPacket.makeReadPacket(vcp: vcp.rawValue)
        let writeRet = avServiceWriteI2C(
            service,
            chipAddress: DDCPacket.chipAddress,
            dataAddress: UInt32(DDCPacket.defaultInputAddress),
            buffer: &requestPacket
        )
        if writeRet != 0 {
            throw DDCError.i2cWriteFailed(writeRet)
        }

        usleep(Self.readWait)

        // Read response
        var response = [UInt8](repeating: 0, count: Self.readBufferSize)
        let readRet = avServiceReadI2C(
            service,
            chipAddress: DDCPacket.chipAddress,
            offset: UInt32(DDCPacket.defaultInputAddress),
            buffer: &response
        )
        if readRet != 0 {
            throw DDCError.i2cReadFailed(readRet)
        }

        return try DDCPacket.parseReadReply(response, expectedVCP: vcp.rawValue)
    }

    /// Read current brightness (0-100).
    public func getBrightness() throws -> Int {
        NSLog("DDCControl: getBrightness()")
        return Int(try read(vcp: .brightness))
    }

    /// Read current contrast (0-100).
    public func getContrast() throws -> Int {
        NSLog("DDCControl: getContrast()")
        return Int(try read(vcp: .contrast))
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

    /// Read current volume (0-100).
    public func getVolume() throws -> Int {
        NSLog("DDCControl: getVolume()")
        return Int(try read(vcp: .volume))
    }

    /// Set volume (0-100).
    public func setVolume(_ value: Int) throws {
        NSLog("DDCControl: setVolume(%d)", value)
        try write(vcp: .volume, value: UInt16(clamping: value))
    }
}
