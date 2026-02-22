import Cocoa
import CoreGraphics

/// Intercepts F1/F2 brightness keys via CGEvent tap.
/// Uses .cgSessionEventTap + NX_SYSDEFINED (MonitorControl's proven approach).
final class HotkeyManager {
    private static let keyF1: Int64 = 0x7A
    private static let keyF2: Int64 = 0x78

    private var eventTap: CFMachPort?

    var onF1: (() -> Void)?
    var onF2: (() -> Void)?

    func start() {
        let trusted = AXIsProcessTrusted()
        NSLog("[Hotkey] AXIsProcessTrusted: %d", trusted ? 1 : 0)
        guard trusted else {
            promptAccessibility()
            return
        }

        // Listen for ALL event types to debug what comes through
        let eventMask: CGEventMask = ~CGEventMask(0)

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
        NSLog("[Hotkey] Event tap started (all events, session level)")
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Re-enable tap if disabled
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            NSLog("[Hotkey] Tap re-enabled")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        // Log ALL non-mouse event types for debugging
        let rawType = type.rawValue
        if rawType != 5 && rawType != 6 && rawType != 22 { // skip mouseMoved, drag, scroll
            NSLog("[Hotkey] Event type=%u", rawType)
        }

        // Path 1: NX_SYSDEFINED (type 14) - media key events
        if rawType == 14 {
            return handleMediaKey(event: event)
        }

        // Path 2: Regular keyDown (type 10)
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            if keyCode == Self.keyF1 {
                NSLog("[Hotkey] F1 keyDown")
                onF1?()
                return nil
            } else if keyCode == Self.keyF2 {
                NSLog("[Hotkey] F2 keyDown")
                onF2?()
                return nil
            }
        }

        return Unmanaged.passRetained(event)
    }

    private func handleMediaKey(event: CGEvent) -> Unmanaged<CGEvent>? {
        guard let nsEvent = NSEvent(cgEvent: event) else {
            return Unmanaged.passRetained(event)
        }

        let subtype = nsEvent.subtype.rawValue
        NSLog("[Hotkey] NX_SYSDEFINED subtype=%d data1=0x%x", subtype, nsEvent.data1)

        guard subtype == 8 else {
            return Unmanaged.passRetained(event)
        }

        let data1 = nsEvent.data1
        let keyType = (data1 & 0xFFFF_0000) >> 16
        let keyDown = ((data1 & 0xFF00) >> 8) == 0x0A

        NSLog("[Hotkey] Media key type=%d down=%d", keyType, keyDown ? 1 : 0)

        guard keyDown else { return Unmanaged.passRetained(event) }

        // NX_KEYTYPE_BRIGHTNESS_DOWN=3, NX_KEYTYPE_BRIGHTNESS_UP=2
        switch keyType {
        case 3:
            NSLog("[Hotkey] Brightness DOWN")
            onF1?()
            return nil
        case 2:
            NSLog("[Hotkey] Brightness UP")
            onF2?()
            return nil
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
