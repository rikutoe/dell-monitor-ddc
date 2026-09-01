# DDC Monitor

macOS menu bar app for controlling brightness and contrast on DDC/CI-capable external monitors.

Built for Apple Silicon Macs. Dell displays are hardware-verified for DDC/CI control; other compatible displays are supported with automatic software display adjustment when the connection path cannot carry DDC/CI commands. Pure Swift — no external runtime dependencies.

![App Icon](Resources/AppIcon-preview.png)

## Features

- **Menu bar sliders** — Adjust brightness and contrast from the menu bar
- **Global hotkeys** — Fn+F1/F2 to adjust brightness & contrast simultaneously
- **Smart display targeting** — Mouse cursor position determines which display to control (DDC/CI or software adjustment for external, passthrough for built-in)
- **Connection-aware fallback** — Automatically uses software display adjustment when DDC/CI writes fail, including the Philips PHL 243V7 over its current HDMI connection path
- **Tahoe-style OSD** — Native floating overlay shows current level on hotkey use
- **Day/Night presets** — One-click presets with long-press to save current values
- **Launch at Login** — Toggle from the menu bar; uses macOS native login items

## Requirements

- macOS 14.0+
- Apple Silicon Mac
- External monitor that supports DDC/CI; Dell monitors are hardware-verified
- A connection path that passes DDC/CI commands for hardware control. When it does not, the app automatically falls back to software display adjustment
- Accessibility permission (for global hotkeys)

## Install

```bash
git clone https://github.com/rikutoe/dell-monitor-ddc.git
cd dell-monitor-ddc
./Scripts/build-app.sh
cp -R .build/release-app/DDCMonitor.app /Applications/
```

Then open **DDC Monitor** from `/Applications` and grant Accessibility permission when prompted.

## Build

```bash
# Release build + .app bundle
./Scripts/build-app.sh

# Development build
swift build
```

## Architecture

```
Sources/
  DDCMonitor/              # Menu bar app (SwiftUI)
    App.swift              # MenuBarExtra entry point
    MenuBarView.swift      # Sliders, presets, launch-at-login toggle
    BrightnessEngine.swift # Adjustment logic + value persistence
    HotkeyManager.swift    # CGEvent tap for global F1/F2
    CursorRouter.swift     # Cursor → screen detection
    OSD{Window,View,Manager}.swift  # Floating OSD overlay
    SettingsStore.swift    # UserDefaults wrapper
  DDCControl/              # Native DDC/CI library
    DDCDisplay.swift       # Display enumeration + VCP read/write
    DDCPacket.swift        # DDC packet construction + checksum
    IOAVServiceBridge.swift # Private API loaded at runtime
```

## Key Design Decisions

| Decision | Rationale |
|---|---|
| Write-only DDC (in-memory tracking) | DDC reads are unreliable on Apple Silicon |
| IOAVService loaded at runtime | Direct DDC access without external tools while avoiding an ABI crash |
| CGEvent tap for hotkeys | System-wide F1/F2 interception with passthrough |
| NSPanel for OSD | Floating window without private OSD APIs |

## License

MIT
