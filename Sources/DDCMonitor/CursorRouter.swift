import Cocoa

/// Determines which screen the mouse cursor is currently on.
struct CursorRouter {
    /// Returns the screen containing the current mouse cursor position.
    static func currentScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        }
    }

    /// Returns true if the cursor is on an external (non-built-in) display.
    static func isCursorOnExternalDisplay() -> Bool {
        guard let screen = currentScreen() else { return false }
        return !isBuiltIn(screen: screen)
    }

    /// Check if a screen is the built-in display using CGDisplayIsBuiltin.
    static func isBuiltIn(screen: NSScreen) -> Bool {
        guard let displayID = screen.displayID else { return false }
        return CGDisplayIsBuiltin(displayID) != 0
    }
}

extension NSScreen {
    /// Extract CGDirectDisplayID from NSScreen.
    var displayID: CGDirectDisplayID? {
        guard let id = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return nil
        }
        return id
    }
}
