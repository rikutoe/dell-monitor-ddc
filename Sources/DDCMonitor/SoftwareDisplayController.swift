import AppKit
import CoreGraphics

/// Applies a safe software brightness fallback through a display transfer table.
final class SoftwareDisplayController {
    private var adjustedDisplayIDs = Set<CGDirectDisplayID>()

    /// Apply the requested values to the external display under the cursor, or the first one.
    @discardableResult
    func apply(brightness: Int, contrast: Int) -> Bool {
        guard let displayID = targetExternalDisplayID() else {
            NSLog("SoftwareDisplayController: No external display available")
            return false
        }

        let table = SoftwareDisplayTransfer.table(brightness: brightness, contrast: contrast)
        let result = setTransfer(table, on: displayID)
        guard result == .success else {
            NSLog("SoftwareDisplayController: Failed to set transfer table: %d", result.rawValue)
            return false
        }

        adjustedDisplayIDs.insert(displayID)
        return true
    }

    /// Remove software adjustment once DDC/CI is working again.
    func restoreStandardTransfer() -> Bool {
        guard !adjustedDisplayIDs.isEmpty else { return false }
        let standard = SoftwareDisplayTransfer.standardTable()
        for displayID in adjustedDisplayIDs {
            let result = setTransfer(standard, on: displayID)
            if result != .success {
                NSLog("SoftwareDisplayController: Failed to restore transfer table: %d", result.rawValue)
            }
        }
        adjustedDisplayIDs.removeAll()
        return true
    }

    private func targetExternalDisplayID() -> CGDirectDisplayID? {
        if let screen = CursorRouter.currentScreen(),
           !CursorRouter.isBuiltIn(screen: screen),
           let displayID = screen.displayID {
            return displayID
        }

        return NSScreen.screens.first(where: { !CursorRouter.isBuiltIn(screen: $0) })?.displayID
    }

    private func setTransfer(_ table: DisplayTransferTable, on displayID: CGDirectDisplayID) -> CGError {
        table.red.withUnsafeBufferPointer { red in
            table.green.withUnsafeBufferPointer { green in
                table.blue.withUnsafeBufferPointer { blue in
                    CGSetDisplayTransferByTable(
                        displayID,
                        UInt32(table.red.count),
                        red.baseAddress,
                        green.baseAddress,
                        blue.baseAddress
                    )
                }
            }
        }
    }
}

/// Pure transfer-table calculation kept independent from display APIs for unit testing.
struct SoftwareDisplayTransfer {
    static let tableSize = 256
    /// Prevent the fallback from reducing a display to an unusably black image.
    static let minimumLuminance: Float = 0.25

    static func table(brightness: Int, contrast: Int) -> DisplayTransferTable {
        let values = (0..<tableSize).map { index in
            component(
                input: Float(index) / Float(tableSize - 1),
                brightness: brightness,
                contrast: contrast
            )
        }
        return DisplayTransferTable(red: values, green: values, blue: values)
    }

    static func standardTable() -> DisplayTransferTable {
        let values = (0..<tableSize).map { Float($0) / Float(tableSize - 1) }
        return DisplayTransferTable(red: values, green: values, blue: values)
    }

    static func component(input: Float, brightness: Int, contrast: Int) -> Float {
        let source = clamp(input, lower: 0, upper: 1)
        let brightnessLevel = Float(clamp(brightness, lower: 0, upper: 100)) / 100
        let contrastLevel = Float(clamp(contrast, lower: 0, upper: 100)) / 100
        let luminance = minimumLuminance + brightnessLevel * (1 - minimumLuminance)
        let contrastScale = 0.5 + contrastLevel
        let contrasted = (source - 0.5) * contrastScale + 0.5
        return clamp(contrasted, lower: 0, upper: 1) * luminance
    }

    private static func clamp<T: Comparable>(_ value: T, lower: T, upper: T) -> T {
        min(upper, max(lower, value))
    }
}

struct DisplayTransferTable {
    let red: [Float]
    let green: [Float]
    let blue: [Float]
}
