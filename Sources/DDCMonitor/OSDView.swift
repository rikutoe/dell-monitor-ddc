import SwiftUI

/// Tahoe-style OSD content view showing brightness level.
struct OSDView: View {
    let value: Int
    let maxValue: Int

    private var fraction: Double {
        guard maxValue > 0 else { return 0 }
        return Double(value) / Double(maxValue)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: brightnessIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.quaternary)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(.primary)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)

            Text("\(value)")
                .font(.system(size: 12, weight: .medium).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(width: 200)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private var brightnessIcon: String {
        if fraction < 0.33 {
            return "sun.min.fill"
        } else if fraction < 0.66 {
            return "sun.max.fill"
        } else {
            return "sun.max.fill"
        }
    }
}
