import Foundation

public enum DDCError: LocalizedError {
    case noExternalDisplay
    case serviceCreationFailed
    case i2cWriteFailed(Int32)
    case i2cReadFailed(Int32)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .noExternalDisplay:
            return "No external display found"
        case .serviceCreationFailed:
            return "Failed to create IOAVService"
        case .i2cWriteFailed(let status):
            return "I2C write failed (status: \(status))"
        case .i2cReadFailed(let status):
            return "I2C read failed (status: \(status))"
        case .invalidResponse:
            return "Invalid DDC response from display"
        }
    }
}
