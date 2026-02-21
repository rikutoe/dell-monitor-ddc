# Phase 2: Minimal E2E App (m1ddc CLI Bridge)

## Done Criteria
Menu bar app button click changes monitor brightness via m1ddc CLI.

## Tasks

- [x] Create Swift Package Manager project (Package.swift)
- [x] Implement App.swift - MenuBarExtra entry point
- [x] Implement MenuBarView.swift - Minimal UI with button (+ contrast)
- [x] Implement CLIDDCBridge.swift - m1ddc Process wrapper
- [x] `swift build` succeeds
- [x] `swift run` -> button click -> brightness & contrast changes visually

## Verification
```bash
swift build && swift run
# Click button -> monitor brightness changes
```
