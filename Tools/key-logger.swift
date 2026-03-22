#!/usr/bin/env swift
// Minimal key event diagnostic — run with: swift Tools/key-logger.swift
// Press F1/F2 (and other keys) to see what macOS actually sends.
// Ctrl+C to quit.

import Cocoa
import Darwin

// Disable stdout buffering
setbuf(stdout, nil)

let trusted = AXIsProcessTrusted()
if !trusted {
    print("⚠️  Accessibility permission required.")
    print("   System Settings → Privacy & Security → Accessibility → add Terminal (or your terminal app)")
    let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
    AXIsProcessTrustedWithOptions(opts)
    print("   Waiting 5s for permission grant...")
    sleep(5)
    guard AXIsProcessTrusted() else {
        print("❌ Still not trusted. Grant permission and re-run.")
        exit(1)
    }
}

print("✅ Accessibility OK. Listening for ALL key events...")
print("   Press F1, F2, Shift+F1, etc. Ctrl+C to quit.\n")
print(String(repeating: "-", count: 80))
fflush(stdout)

let eventMask: CGEventMask =
    (1 << CGEventType.keyDown.rawValue)
    | (1 << CGEventType.keyUp.rawValue)
    | (1 << 14)  // NX_SYSDEFINED
    | (1 << CGEventType.flagsChanged.rawValue)

guard let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .listenOnly,  // listen only — won't block anything
    eventsOfInterest: eventMask,
    callback: { _, type, event, _ in
        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        switch type {
        case .keyDown:
            let shift = flags.contains(.maskShift) ? "Shift+" : ""
            let ctrl  = flags.contains(.maskControl) ? "Ctrl+" : ""
            let opt   = flags.contains(.maskAlternate) ? "Opt+" : ""
            let cmd   = flags.contains(.maskCommand) ? "Cmd+" : ""
            let fn    = flags.contains(.maskSecondaryFn) ? "Fn+" : ""
            let mods  = "\(fn)\(shift)\(ctrl)\(opt)\(cmd)"
            let name  = keycodeName(keyCode)
            print("[keyDown]    keyCode=0x\(String(keyCode, radix: 16, uppercase: true).leftPad(4)) (\(name))  mods=\(mods.isEmpty ? "none" : mods)  rawFlags=0x\(String(flags.rawValue, radix: 16))")
            fflush(stdout)

        case .keyUp:
            let name = keycodeName(keyCode)
            print("[keyUp]      keyCode=0x\(String(keyCode, radix: 16, uppercase: true).leftPad(4)) (\(name))")
            fflush(stdout)

        case .flagsChanged:
            print("[flagsChanged] rawFlags=0x\(String(flags.rawValue, radix: 16))")
            fflush(stdout)

        default:
            if type.rawValue == 14 {
                // NX_SYSDEFINED — media/special key
                if let nsEvent = NSEvent(cgEvent: event) {
                    let subtype = nsEvent.subtype.rawValue
                    let data1 = nsEvent.data1
                    let keyType = (data1 & 0xFFFF_0000) >> 16
                    let keyState = (data1 & 0xFF00) >> 8
                    let isDown = keyState == 0x0A
                    let repeat_ = data1 & 0x1
                    print("[NX_SYSDEFINED] subtype=\(subtype)  keyType=\(keyType) (\(mediaKeyName(keyType)))  down=\(isDown)  repeat=\(repeat_)  data1=0x\(String(data1, radix: 16))")
                } else {
                    print("[NX_SYSDEFINED] (could not convert to NSEvent)")
                }
                fflush(stdout)
            } else {
                print("[type=\(type.rawValue)] keyCode=\(keyCode) flags=0x\(String(flags.rawValue, radix: 16))")
                fflush(stdout)
            }
        }

        return Unmanaged.passRetained(event)
    },
    userInfo: nil
) else {
    print("❌ Failed to create CGEvent tap. Check Accessibility permission.")
    fflush(stdout)
    exit(1)
}

let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

print("Tap active. Waiting for events...\n")
fflush(stdout)

// Keep alive
CFRunLoopRun()

// --- helpers ---

func keycodeName(_ code: Int64) -> String {
    switch code {
    case 0x7A: return "F1"
    case 0x78: return "F2"
    case 0x63: return "F3"
    case 0x76: return "F4"
    case 0x60: return "F5"
    case 0x61: return "F6"
    case 0x62: return "F7"
    case 0x64: return "F8"
    case 0x65: return "F9"
    case 0x6D: return "F10"
    case 0x67: return "F11"
    case 0x6F: return "F12"
    case 0x69: return "F13"
    case 0x6B: return "F14"
    case 0x71: return "F15"
    case 0x00: return "A"
    case 0x31: return "Space"
    case 0x24: return "Return"
    case 0x35: return "Escape"
    case 0x33: return "Delete"
    case 0x7E: return "UpArrow"
    case 0x7D: return "DownArrow"
    case 0x7B: return "LeftArrow"
    case 0x7C: return "RightArrow"
    default:   return "?"
    }
}

func mediaKeyName(_ keyType: Int) -> String {
    switch keyType {
    case 0:  return "BRIGHTNESS_UP(legacy)"
    case 1:  return "BRIGHTNESS_DOWN(legacy)"
    case 2:  return "NX_KEYTYPE_BRIGHTNESS_UP"
    case 3:  return "NX_KEYTYPE_BRIGHTNESS_DOWN"
    case 7:  return "PLAY/PAUSE"
    case 8:  return "NEXT"
    case 9:  return "PREVIOUS"
    case 10: return "MUTE"
    case 16: return "VOLUME_DOWN"
    case 17: return "VOLUME_UP"
    case 20: return "ILLUMINATION_DOWN"
    case 21: return "ILLUMINATION_UP"
    default: return "unknown(\(keyType))"
    }
}

extension String {
    func leftPad(_ length: Int, with char: Character = "0") -> String {
        String(repeating: char, count: max(0, length - count)) + self
    }
}
