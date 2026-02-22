import SwiftUI
import DDCControl

struct MenuBarView: View {
    @State private var brightness: Int = 30
    @State private var contrast: Int = 39
    @State private var statusMessage: String = ""
    @State private var display: DDCDisplay?

    private let step = 5

    var body: some View {
        VStack(spacing: 8) {
            Text("Brightness: \(brightness)")
                .font(.headline)

            HStack(spacing: 12) {
                Button("- \(step)") {
                    adjustBrightness(by: -step)
                }
                Button("+ \(step)") {
                    adjustBrightness(by: step)
                }
            }

            Divider()

            Text("Contrast: \(contrast)")
                .font(.headline)

            HStack(spacing: 12) {
                Button("- \(step)") {
                    adjustContrast(by: -step)
                }
                Button("+ \(step)") {
                    adjustContrast(by: step)
                }
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .onAppear {
            display = DDCDisplay.enumerate().first
            if display == nil {
                statusMessage = "No external display found"
            }
        }
    }

    private func adjustBrightness(by delta: Int) {
        let newValue = max(0, min(100, brightness + delta))
        guard let display else {
            statusMessage = "No display"
            return
        }
        do {
            try display.setBrightness(newValue)
            brightness = newValue
            statusMessage = "Brightness: \(newValue)"
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    private func adjustContrast(by delta: Int) {
        let newValue = max(0, min(100, contrast + delta))
        guard let display else {
            statusMessage = "No display"
            return
        }
        do {
            try display.setContrast(newValue)
            contrast = newValue
            statusMessage = "Contrast: \(newValue)"
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }
}
