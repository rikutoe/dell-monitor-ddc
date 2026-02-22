import SwiftUI
import DDCControl

struct MenuBarView: View {
    let engine: BrightnessEngine
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 12) {
            // Brightness slider
            HStack {
                Image(systemName: "sun.max.fill")
                    .frame(width: 20)
                Slider(
                    value: brightnessBinding,
                    in: Double(engine.minValue)...Double(engine.maxValue),
                    step: 1
                )
                Text("\(engine.brightness)")
                    .monospacedDigit()
                    .frame(width: 30, alignment: .trailing)
            }

            // Contrast slider
            HStack {
                Image(systemName: "circle.lefthalf.filled")
                    .frame(width: 20)
                Slider(
                    value: contrastBinding,
                    in: Double(engine.minValue)...Double(engine.maxValue),
                    step: 1
                )
                Text("\(engine.contrast)")
                    .monospacedDigit()
                    .frame(width: 30, alignment: .trailing)
            }

            Divider()

            Button("Settings...") {
                showSettings = true
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 280)
    }

    private var brightnessBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(engine.brightness) },
            set: { newValue in
                let delta = Int(newValue) - engine.brightness
                if delta != 0 {
                    engine.adjustBrightness(to: Int(newValue))
                }
            }
        )
    }

    private var contrastBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(engine.contrast) },
            set: { newValue in
                let delta = Int(newValue) - engine.contrast
                if delta != 0 {
                    engine.adjustContrast(to: Int(newValue))
                }
            }
        )
    }
}
