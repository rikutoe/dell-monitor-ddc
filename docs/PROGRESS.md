# DDC Monitor - Progress

## Phase Overview

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | DDC verification (m1ddc CLI) | Complete |
| 1 | Document-driven development foundation | Complete |
| 2 | Minimal E2E app (m1ddc CLI bridge) | Complete |
| 3 | Native DDC control module | Complete |
| 4 | Global hotkeys (F1/F2) + Tahoe OSD | Partial |
| 5 | Smart cursor-based targeting | Complete |
| 6 | Menu bar UI (sliders + settings) | Complete |
| 7 | Polish | Pending |

## Phase Details

### Phase 0: DDC Verification
- **Status**: Complete
- **Findings**:
  - Monitor: Dell S3423DWC detected via m1ddc
  - DDC writes: Reliable (brightness + contrast)
  - DDC reads: Unreliable (known Apple Silicon issue)
  - `m1ddc chg` with negative values: Argument parsing issue
  - Original values: brightness=30, contrast=39
- **Decision**: Track values in-memory after writes instead of relying on DDC reads

### Phase 1: Document-driven development foundation
- **Status**: Complete

### Phase 2: Minimal E2E app (m1ddc CLI bridge)
- **Status**: Complete
- **Deliverables**:
  - Package.swift (SPM executable target, macOS 14+)
  - App.swift - MenuBarExtra entry point
  - MenuBarView.swift - Brightness/Contrast ±5 buttons
  - CLIDDCBridge.swift - m1ddc Process wrapper
- **Verified**: Button click → brightness & contrast change visually

### Phase 3: Native DDC control module
- **Status**: Complete
- **Deliverables**:
  - DDCPacket.swift - Packet construction + XOR checksum
  - IOAVServiceBridge.swift - Private API via dlsym (not @_silgen_name due to ABI crash)
  - DDCDisplay.swift - Display enumeration + VCP write
  - DDCError.swift - Error types
  - DDCPacketTests.swift - 7 tests passing
- **Verified**: Native DDC brightness/contrast write via IOAVService works
- **Note**: @_silgen_name caused SIGTRAP crash; switched to dlsym + @convention(c)

### Phase 4: Global hotkeys (F1/F2) + Tahoe-style OSD
- **Status**: Partial
- **Deliverables**:
  - HotkeyManager.swift - CGEvent tap (Fn+F1/F2 で動作)
  - BrightnessEngine.swift - brightness + contrast 同時調整
  - OSDWindow.swift / OSDView.swift / OSDManager.swift - Tahoe 風 OSD
- **Verified**: Fn+F1/F2 → brightness/contrast 変更 + OSD 表示
- **Backlog**: Fn なしで F1/F2 を捕捉する方法を調査（Lunar は成功している）
  - macOS Tahoe で NX_SYSDEFINED subtype=8 が生成されない
  - subtype=7 data1=0x1 が来るが F1/F2 の区別不可
  - Lunar の実装を参考に要調査

### Phase 5: Smart cursor-based targeting
- **Status**: Complete
- **Deliverables**:
  - CursorRouter.swift - NSEvent.mouseLocation + CGDisplayIsBuiltin
  - BrightnessEngine updated - returns Bool for passthrough support
  - HotkeyManager updated - consume/passthrough based on cursor position
