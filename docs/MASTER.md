# DDC Monitor - Master Document

## Requirements

### Core
- Apple Silicon Mac + USB-C/Thunderbolt Dell external monitor
- F1/F2 global hotkeys adjust brightness + contrast simultaneously
- Mouse cursor position determines target (Dell = DDC, built-in = macOS standard passthrough)
- Brightness/contrast upper/lower limits user-configurable
- Menu bar resident app with sliders + settings
- macOS Tahoe-style custom OSD on F1/F2 operation
- Swift + SwiftUI, no external runtime dependencies

### OSD Specification
- macOS Tahoe new OSD design: small notification-style bar below menu bar, screen top-right
- NSPanel (`.floating` level) + SwiftUI
- Content: brightness icon + level bar + numeric value
- Auto-fadeout after 1.5 seconds
- Timer reset on continuous key operations

### Display Targeting
- `NSEvent.mouseLocation` + `NSScreen.screens` for cursor position
- `CGDisplayIsBuiltin` for built-in/external discrimination
- NSScreen <-> DDCDisplay mapping via CGDirectDisplayID
- Only consume events for external monitors; passthrough for built-in

## Architecture

```
Sources/
  DDCMonitor/          # Menu bar app
    App.swift          # MenuBarExtra entry point
    MenuBarView.swift  # Slider popover UI
    SettingsView.swift # Range limit settings
    SettingsStore.swift # UserDefaults wrapper
    HotkeyManager.swift # CGEvent tap for F1/F2
    BrightnessEngine.swift # Adjustment logic + range limits
    CursorRouter.swift # Cursor position -> screen detection
    DisplayManager.swift # NSScreen <-> DDCDisplay mapping
    OSDWindow.swift    # NSPanel subclass
    OSDView.swift      # SwiftUI OSD content
    OSDManager.swift   # Show/hide control, timer, fade
  DDCControl/          # Native DDC library
    IOAVServiceBridge.swift # Private API declarations
    DDCPacket.swift    # Packet construction + checksum
    DDCDisplay.swift   # Enumeration + VCP read/write
    DDCError.swift     # Error types
Tests/
  DDCControlTests/
    DDCPacketTests.swift # Checksum verification
```

## Design Decisions

| Decision | Rationale |
|---|---|
| Track brightness in-memory, not via DDC read | DDC reads unreliable on Apple Silicon |
| IOAVService via @_silgen_name | Direct DDC access without external dependencies |
| CGEvent tap for hotkeys | System-wide F1/F2 interception |
| NSPanel for OSD | Floating window without Private API dependency |
| m1ddc CLI bridge first (Phase 2) | De-risk DDC communication before native implementation |

## Reference Implementations
- [MonitorControl](https://github.com/MonitorControl/MonitorControl) - Arm64DDC.swift
- [AppleSiliconDDC](https://github.com/waydabber/AppleSiliconDDC)
