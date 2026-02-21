# Phase 2: Minimal E2E App (m1ddc CLI Bridge)

## Done Criteria
Menu bar app button click changes monitor brightness via m1ddc CLI.

## Tasks

- [ ] Create Swift Package Manager project (Package.swift)
- [ ] Implement App.swift - MenuBarExtra entry point
- [ ] Implement MenuBarView.swift - Minimal UI with button
- [ ] Implement CLIDDCBridge.swift - m1ddc Process wrapper
- [ ] `swift build` succeeds
- [ ] `swift run` -> button click -> brightness changes visually

## Verification
```bash
swift build && swift run
# Click button -> monitor brightness changes
```
