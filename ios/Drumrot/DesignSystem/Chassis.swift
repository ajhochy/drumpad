import SwiftUI

/// Faint horizontal CRT scanlines for LCD surfaces (matches `.readout::after`).
struct Scanlines: View {
    var body: some View {
        GeometryReader { geo in
            let count = Int(geo.size.height / 3)
            VStack(spacing: 2) {
                ForEach(0..<max(count, 1), id: \.self) { _ in
                    Color.black.opacity(0.18).frame(height: 1)
                }
            }
        }
        .allowsHitTesting(false)
        .opacity(0.5)
    }
}

/// A panel screw head.
struct Screw: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(colors: [SPColor.screw, SPColor.metalDark],
                               center: .topLeading, startRadius: 0, endRadius: 8)
            )
            .frame(width: 10, height: 10)
            .overlay(Rectangle().fill(.black.opacity(0.5)).frame(width: 6, height: 1.2).rotationEffect(.degrees(35)))
            .overlay(Circle().stroke(.black.opacity(0.6), lineWidth: 0.5))
            .accessibilityHidden(true)
    }
}

extension View {
    /// Dark-green LCD screen surface (inset, glow, scanlines) — `.readout` / `.lcd-wrap`.
    func lcdPanel(cornerRadius: CGFloat = 8) -> some View {
        self
            .background(
                LinearGradient(colors: [SPColor.lcdBg2, SPColor.lcdBg],
                               startPoint: .top, endPoint: .bottom)
            )
            .overlay(Scanlines().clipShape(RoundedRectangle(cornerRadius: cornerRadius)))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(SPColor.lcdFg.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(SPColor.ink, lineWidth: 1)
            )
    }

    /// A brushed-metal chassis module with an etched title (rail modules).
    func chassisModule(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(SPFont.mono(.caption2, weight: .bold))
                .tracking(2)
                .foregroundStyle(SPColor.textDim)
            self
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [SPColor.chassis, SPColor.chassis2],
                           startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(SPColor.metalDark, lineWidth: 1))
    }
}
