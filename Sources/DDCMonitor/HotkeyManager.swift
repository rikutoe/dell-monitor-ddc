import Cocoa
import CoreGraphics

/// Intercepts F1/F2 key events via CGEvent tap.
/// Callbacks return Bool: true = handled (consume event), false = passthrough.
final class HotkeyManager {
    private static let keyF1: Int64 = 0x7A
    private static let keyF2: Int64 = 0x78

    private var eventTap: CFMachPort?

    /// Return true to consume the event, false to pass through.
    var onF1: (() -> Bool)?
    var onF2: (() -> Bool)?

    func start() {
        let trusted = AXIsProcessTrusted()
        guard trusted else {
            promptAccessibility()
            return
        }

        let eventMask: CGEventMask =
            CGEventMask(1 << CGEventType.keyDown.rawValue)
            | CGEventMask(1 << 14) // NX_SYSDEFINED

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
            NSLog("[Hotkey] Failed to create CGEvent tap")
            return
        }

        eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
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

        // Regular keyDown (Fn+F1/F2 or standard function key mode)
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            if keyCode == Self.keyF1 {
                let handled = onF1?() ?? false
                return handled ? nil : Unmanaged.passRetained(event)
            } else if keyCode == Self.keyF2 {
                let handled = onF2?() ?? false
                return handled ? nil : Unmanaged.passRetained(event)
            }
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
            let handled = onF1?() ?? false
            return handled ? nil : Unmanaged.passRetained(event)
        case 2: // NX_KEYTYPE_BRIGHTNESS_UP
            let handled = onF2?() ?? false
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
