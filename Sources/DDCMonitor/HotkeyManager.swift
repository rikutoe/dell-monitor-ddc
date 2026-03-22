import Cocoa
import CoreGraphics

/// Intercepts brightness and volume key events via CGEvent tap.
/// Supports F1/F2 (Apple keyboard), F14/F15 (external keyboard brightness keys),
/// and volume media keys / F10-F12 keycodes.
/// Callbacks return Bool: true = handled (consume event), false = passthrough.
final class HotkeyManager {
    // Brightness keycodes
    private static let keyF1: Int64 = 0x7A
    private static let keyF2: Int64 = 0x78
    private static let keyF14: Int64 = 0x6B  // brightness down on external keyboards
    private static let keyF15: Int64 = 0x71  // brightness up on external keyboards

    // Volume keycodes (standard function key mode)
    private static let keyF10: Int64 = 0x6D  // mute
    private static let keyF11: Int64 = 0x67  // volume down
    private static let keyF12: Int64 = 0x6F  // volume up

    private var eventTap: CFMachPort?

    /// Return true to consume the event, false to pass through.
    var onBrightnessDown: (() -> Bool)?
    var onBrightnessUp: (() -> Bool)?
    var onVolumeDown: (() -> Bool)?
    var onVolumeUp: (() -> Bool)?
    var onMute: (() -> Bool)?

    func start() {
        let trusted = AXIsProcessTrusted()
        AppLog.log("[Hotkey] AXIsProcessTrusted = \(trusted)")
        guard trusted else {
            AppLog.log("[Hotkey] NOT trusted — prompting accessibility")
            promptAccessibility()
            return
        }

        let eventMask: CGEventMask =
            CGEventMask(1 << CGEventType.keyDown.rawValue)
            | CGEventMask(1 << 14) // NX_SYSDEFINED

        AppLog.log("[Hotkey] Creating CGEvent tap...")
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, type, event, userInfo in
                guard let mgr = userInfo.map({
                    Unmanaged<HotkeyManager>.fromOpaque($0).takeUnretainedValue()
                }) else {
                    return Unmanaged.passRetained(event)
                }
                return mgr.handleEvent(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            AppLog.log("[Hotkey] FAILED to create CGEvent tap")
            return
        }

        eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        AppLog.log("[Hotkey] CGEvent tap active — listening for brightness & volume keys")
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        // NX_SYSDEFINED media key events
        if type.rawValue == 14 {
            return handleMediaKey(event: event)
        }

        // Regular keyDown — function key mode
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            return handleKeyDown(keyCode: keyCode, event: event)
        }

        return Unmanaged.passRetained(event)
    }

    private func handleKeyDown(keyCode: Int64, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Brightness
        if keyCode == Self.keyF1 || keyCode == Self.keyF14 {
            AppLog.log("[Hotkey] Brightness DOWN (keyCode=0x\(String(keyCode, radix: 16)))")
            let handled = onBrightnessDown?() ?? false
            return handled ? nil : Unmanaged.passRetained(event)
        }
        if keyCode == Self.keyF2 || keyCode == Self.keyF15 {
            AppLog.log("[Hotkey] Brightness UP (keyCode=0x\(String(keyCode, radix: 16)))")
            let handled = onBrightnessUp?() ?? false
            return handled ? nil : Unmanaged.passRetained(event)
        }

        // Volume
        if keyCode == Self.keyF11 {
            AppLog.log("[Hotkey] Volume DOWN (keyCode=0x\(String(keyCode, radix: 16)))")
            let handled = onVolumeDown?() ?? false
            return handled ? nil : Unmanaged.passRetained(event)
        }
        if keyCode == Self.keyF12 {
            AppLog.log("[Hotkey] Volume UP (keyCode=0x\(String(keyCode, radix: 16)))")
            let handled = onVolumeUp?() ?? false
            return handled ? nil : Unmanaged.passRetained(event)
        }
        if keyCode == Self.keyF10 {
            AppLog.log("[Hotkey] Mute (keyCode=0x\(String(keyCode, radix: 16)))")
            let handled = onMute?() ?? false
            return handled ? nil : Unmanaged.passRetained(event)
        }

        return Unmanaged.passRetained(event)
    }

    private func handleMediaKey(event: CGEvent) -> Unmanaged<CGEvent>? {
        guard let nsEvent = NSEvent(cgEvent: event),
              nsEvent.subtype.rawValue == 8 else {
            return Unmanaged.passRetained(event)
        }

        let data1 = nsEvent.data1
        let keyType = (data1 & 0xFFFF_0000) >> 16
        let keyDown = ((data1 & 0xFF00) >> 8) == 0x0A

        guard keyDown else { return Unmanaged.passRetained(event) }

        switch keyType {
        case 3: // NX_KEYTYPE_BRIGHTNESS_DOWN
            let handled = onBrightnessDown?() ?? false
            return handled ? nil : Unmanaged.passRetained(event)
        case 2: // NX_KEYTYPE_BRIGHTNESS_UP
            let handled = onBrightnessUp?() ?? false
            return handled ? nil : Unmanaged.passRetained(event)
        case 1: // NX_KEYTYPE_SOUND_DOWN
            AppLog.log("[Hotkey] Media VOLUME DOWN")
            let handled = onVolumeDown?() ?? false
            return handled ? nil : Unmanaged.passRetained(event)
        case 0: // NX_KEYTYPE_SOUND_UP
            AppLog.log("[Hotkey] Media VOLUME UP")
            let handled = onVolumeUp?() ?? false
            return handled ? nil : Unmanaged.passRetained(event)
        case 7: // NX_KEYTYPE_MUTE
            AppLog.log("[Hotkey] Media MUTE")
            let handled = onMute?() ?? false
            return handled ? nil : Unmanaged.passRetained(event)
        default:
            return Unmanaged.passRetained(event)
        }
    }

    private func promptAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        eventTap = nil
    }
}
