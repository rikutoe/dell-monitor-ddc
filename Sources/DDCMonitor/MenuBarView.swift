import SwiftUI
import ServiceManagement
import DDCControl

struct MenuBarView: View {
    let engine: BrightnessEngine
    private let settings = SettingsStore.shared
    @State private var brightness: Double = 0
    @State private var contrast: Double = 0
    @State private var volume: Double = 0
    @State private var savedPreset: String?
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(spacing: 12) {
            // Error banner
            if let error = engine.lastReadError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.yellow.opacity(0.1))
                )
            }

            // Brightness slider
            HStack {
                Image(systemName: "sun.max.fill")
                    .frame(width: 20)
                Slider(
                    value: $brightness,
                    in: Double(engine.minValue)...Double(engine.maxValue),
                    step: 1
                )
                Text("\(Int(brightness))")
                    .monospacedDigit()
                    .frame(width: 30, alignment: .trailing)
            }

            // Contrast slider
            HStack {
                Image(systemName: "circle.lefthalf.filled")
                    .frame(width: 20)
                Slider(
                    value: $contrast,
                    in: Double(engine.minValue)...Double(engine.maxValue),
                    step: 1
                )
                Text("\(Int(contrast))")
                    .monospacedDigit()
                    .frame(width: 30, alignment: .trailing)
            }

            // Volume slider
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .frame(width: 20)
                Slider(
                    value: $volume,
                    in: Double(engine.minValue)...Double(engine.maxValue),
                    step: 1
                )
                Text("\(Int(volume))")
                    .monospacedDigit()
                    .frame(width: 30, alignment: .trailing)
            }

            // Presets
            HStack(spacing: 8) {
                PresetButton(
                    label: "Day",
                    icon: "sun.max",
                    active: matchesPreset(b: settings.dayBrightness, c: settings.dayContrast),
                    saved: savedPreset == "day"
                ) {
                    applyPreset(
                        brightness: settings.dayBrightness,
                        contrast: settings.dayContrast
                    )
                } onLongPress: {
                    savePreset("day")
                }

                PresetButton(
                    label: "Night",
                    icon: "moon",
                    active: matchesPreset(b: settings.nightBrightness, c: settings.nightContrast),
                    saved: savedPreset == "night"
                ) {
                    applyPreset(
                        brightness: settings.nightBrightness,
                        contrast: settings.nightContrast
                    )
                } onLongPress: {
                    savePreset("night")
                }
            }

            Divider()

            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        NSLog("Launch at login error: %@", error.localizedDescription)
                        launchAtLogin = !newValue
                    }
                }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 280)
        .onAppear {
            engine.refreshFromDisplay()
            syncFromEngine()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            engine.refreshFromDisplay()
            syncFromEngine()
        }
        .onChange(of: brightness) { _, newValue in
            let intValue = Int(newValue)
            if intValue != engine.brightness {
                engine.adjustBrightness(to: intValue)
            }
        }
        .onChange(of: contrast) { _, newValue in
            let intValue = Int(newValue)
            if intValue != engine.contrast {
                engine.adjustContrast(to: intValue)
            }
        }
        .onChange(of: volume) { _, newValue in
            let intValue = Int(newValue)
            if intValue != engine.volume {
                engine.adjustVolume(to: intValue)
            }
        }
    }

    private func matchesPreset(b: Int, c: Int) -> Bool {
        Int(brightness) == b && Int(contrast) == c
    }

    private func syncFromEngine() {
        brightness = Double(engine.brightness)
        contrast = Double(engine.contrast)
        volume = Double(engine.volume)
    }

    private func applyPreset(brightness b: Int, contrast c: Int) {
        engine.adjustBrightness(to: b)
        engine.adjustContrast(to: c)
        brightness = Double(b)
        contrast = Double(c)
    }

    private func savePreset(_ name: String) {
        let b = Int(brightness)
        let c = Int(contrast)
        if name == "day" {
            settings.dayBrightness = b
            settings.dayContrast = c
        } else {
            settings.nightBrightness = b
            settings.nightContrast = c
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            savedPreset = name
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                savedPreset = nil
            }
        }
    }
}

// MARK: - Preset Button with long-press support

struct PresetButton: View {
    let label: String
    let icon: String
    let active: Bool
    let saved: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPressed = false

    private var displayLabel: String {
        if saved { return "Saved" }
        return label
    }

    private var displayIcon: String {
        if saved { return "checkmark.circle.fill" }
        return icon
    }

    private var backgroundColor: Color {
        if saved { return .green.opacity(0.2) }
        if active { return .accentColor.opacity(0.2) }
        return .clear
    }

    private var foregroundColor: Color? {
        if saved { return .green }
        if active { return .accentColor }
        return nil
    }

    var body: some View {
        Label(displayLabel, systemImage: displayIcon)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundStyle(foregroundColor ?? .primary)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: active)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                onLongPress()
            } onPressingChanged: { pressing in
                isPressed = pressing
            }
    }
}
