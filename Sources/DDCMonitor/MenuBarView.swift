import SwiftUI
import DDCControl

struct MenuBarView: View {
    let engine: BrightnessEngine

    var body: some View {
        VStack(spacing: 8) {
            Text("Brightness: \(engine.brightness)")
                .font(.headline)

            HStack(spacing: 12) {
                Button("- \(engine.step)") {
                    engine.decrement()
                }
                Button("+ \(engine.step)") {
                    engine.increment()
                }
            }

            Divider()

            Text("Contrast: \(engine.contrast)")
                .font(.headline)

            HStack(spacing: 12) {
                Button("- \(engine.step)") {
                    engine.adjust(by: -engine.step)
                }
                Button("+ \(engine.step)") {
                    engine.adjust(by: engine.step)
                }
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
    }
}
