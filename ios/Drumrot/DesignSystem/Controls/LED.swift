import SwiftUI

/// A small status LED that glows when active. Used for MIDI activity, click, etc.
struct LED: View {
    var on: Bool
    var color: Color = SPColor.accentGreen
    var diameter: CGFloat = 10

    var body: some View {
        Circle()
            .fill(on ? color : color.opacity(0.16))
            .frame(width: diameter, height: diameter)
            .shadow(color: on ? color.opacity(0.8) : .clear, radius: on ? 6 : 0)
            .animation(.easeOut(duration: 0.12), value: on)
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 16) { LED(on: true); LED(on: false); LED(on: true, color: SPColor.accentPink) }
        .padding()
        .background(SPColor.background)
}
