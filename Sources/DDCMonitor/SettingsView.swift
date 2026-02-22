import SwiftUI

struct SettingsView: View {
    @AppStorage("brightnessMin") private var brightnessMin = 0
    @AppStorage("brightnessMax") private var brightnessMax = 100
    @AppStorage("contrastMin") private var contrastMin = 0
    @AppStorage("contrastMax") private var contrastMax = 100
    @AppStorage("step") private var step = 5

    var body: some View {
        Form {
            Section("Brightness Range") {
                HStack {
                    Text("Min")
                    Slider(value: intBinding($brightnessMin), in: 0...100, step: 1)
                    Text("\(brightnessMin)")
                        .monospacedDigit()
                        .frame(width: 30, alignment: .trailing)
                }
                HStack {
                    Text("Max")
                    Slider(value: intBinding($brightnessMax), in: 0...100, step: 1)
                    Text("\(brightnessMax)")
                        .monospacedDigit()
                        .frame(width: 30, alignment: .trailing)
                }
            }

            Section("Contrast Range") {
                HStack {
                    Text("Min")
                    Slider(value: intBinding($contrastMin), in: 0...100, step: 1)
                    Text("\(contrastMin)")
                        .monospacedDigit()
                        .frame(width: 30, alignment: .trailing)
                }
                HStack {
                    Text("Max")
                    Slider(value: intBinding($contrastMax), in: 0...100, step: 1)
                    Text("\(contrastMax)")
                        .monospacedDigit()
                        .frame(width: 30, alignment: .trailing)
                }
            }

            Section("Step Size") {
                HStack {
                    Slider(value: intBinding($step), in: 1...20, step: 1)
                    Text("\(step)")
                        .monospacedDigit()
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 320)
        .padding()
    }

    private func intBinding(_ binding: Binding<Int>) -> Binding<Double> {
        Binding<Double>(
            get: { Double(binding.wrappedValue) },
            set: { binding.wrappedValue = Int($0) }
        )
    }
}
