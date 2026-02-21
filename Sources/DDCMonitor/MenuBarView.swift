import SwiftUI

struct MenuBarView: View {
    @State private var brightness: Int = 30
    @State private var contrast: Int = 39
    @State private var statusMessage: String = ""

    private let bridge = CLIDDCBridge()
    private let step = 5

    var body: some View {
        VStack(spacing: 8) {
            Text("Brightness: \(brightness)")
                .font(.headline)

            HStack(spacing: 12) {
                Button("- \(step)") {
                    adjust(\.brightness, by: -step)
                }
                Button("+ \(step)") {
                    adjust(\.brightness, by: step)
                }
            }

            Divider()

            Text("Contrast: \(contrast)")
                .font(.headline)

            HStack(spacing: 12) {
                Button("- \(step)") {
                    adjust(\.contrast, by: -step)
                }
                Button("+ \(step)") {
                    adjust(\.contrast, by: step)
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
    }

    private enum Control: String {
        case brightness, contrast
    }

    private func adjust(_ keyPath: WritableKeyPath<MenuBarView, Int>, by delta: Int) {
        let current = self[keyPath: keyPath]
        let newValue = max(0, min(100, current + delta))

        let result: Result<Void, DDCBridgeError>
        if keyPath == \.brightness {
            result = bridge.setBrightness(newValue)
        } else {
            result = bridge.setContrast(newValue)
        }

        switch result {
        case .success:
            // SwiftUI @State requires direct assignment
            if keyPath == \.brightness {
                brightness = newValue
            } else {
                contrast = newValue
            }
            statusMessage = "Set to \(newValue)"
        case .failure(let error):
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }
}
