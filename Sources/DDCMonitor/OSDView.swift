import SwiftUI

/// The kind of value the OSD is displaying.
enum OSDKind {
    case brightness
    case volume
}

/// Tahoe-style OSD content view.
struct OSDView: View {
    let kind: OSDKind
    let value: Int
    let maxValue: Int

    private var fraction: Double {
        guard maxValue > 0 else { return 0 }
        return Double(value) / Double(maxValue)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
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

    private var icon: String {
        switch kind {
        case .brightness:
            return fraction < 0.33 ? "sun.min.fill" : "sun.max.fill"
        case .volume:
            if value == 0 { return "speaker.slash.fill" }
            return fraction < 0.33 ? "speaker.wave.1.fill"
                : fraction < 0.66 ? "speaker.wave.2.fill"
                : "speaker.wave.3.fill"
        }
    }
}
