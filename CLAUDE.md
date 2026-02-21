# DDC Monitor - Project Instructions

## Overview
macOS menu bar app for controlling Dell external monitor brightness/contrast via DDC/CI.
Apple Silicon Mac + USB-C/Thunderbolt connection. Swift + SwiftUI, no external runtime dependencies.

## Architecture
- **Swift Package Manager** project (executable target `DDCMonitor` + library target `DDCControl`)
- `Sources/DDCMonitor/` - Menu bar app, UI, hotkeys, OSD
- `Sources/DDCControl/` - Native DDC/CI control via IOAVService
- `Tests/DDCControlTests/` - Unit tests for DDC packet construction

## Key Technical Decisions
- DDC reads are unreliable on Apple Silicon; track values in-memory after writes
- IOAVService private API via `@_silgen_name` for DDC communication
- CGEvent tap for global F1/F2 hotkey interception (requires Accessibility permission)
- NSPanel + SwiftUI for custom OSD (no Private API like OSDUIHelper)
- Mouse cursor position determines target display (DDC for external, passthrough for built-in)

## Hardware Context
- Monitor: Dell S3423DWC (identified via m1ddc)
- DDC/CI: Write works reliably, reads are unstable
- Default brightness range: 0-100, contrast range: 0-100

## Document Management

| Document | Update When | Skip When |
|---|---|---|
| CLAUDE.md | Architecture decisions, new patterns, project rules change | Minor implementation progress |
| docs/MASTER.md | Requirements change, architecture decisions, new patterns | Minor bug fixes within scope |
| docs/PROGRESS.md | Phase start/complete, blockers found, scope changes | Task-level progress (use plans/) |
| docs/plans/phase-N.md | Phase starts (create), task start/complete (update) | After phase completion (close, reflect in PROGRESS.md) |

## Phase Review Rules
1. Report Done criteria achievement to user after all phase tasks complete
2. Present verification results (command output, screenshots, etc.)
3. Get user approval before proceeding to next phase
4. If review feedback given, fix and re-request review
5. Update PROGRESS.md phase status to "complete" only after user approval

## Coding Rules
- Modular approach: split by responsibility
- Each file under 300 lines; split if exceeding
- Swift 6 concurrency: isolate IOKit calls in dedicated actor/serial queue
