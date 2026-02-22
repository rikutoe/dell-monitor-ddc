# DDC Monitor - Progress

## Phase Overview

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | DDC verification (m1ddc CLI) | Complete |
| 1 | Document-driven development foundation | Complete |
| 2 | Minimal E2E app (m1ddc CLI bridge) | Complete |
| 3 | Native DDC control module | Complete |
| 4 | Global hotkeys (F1/F2) + Tahoe OSD | In Progress |
| 5 | Smart cursor-based targeting | Pending |
| 6 | Menu bar UI (sliders + settings) | Pending |
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
- **Status**: In Progress
