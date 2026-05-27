import SwiftUI

/// A drum pad / chassis button. Pulses briefly when triggered.
struct PadButton: View {
    let label: String
    var color: Color = SPColor.accentGreen
    var action: () -> Void

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            action()
            pulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { pulse = false }
        } label: {
            Text(label)
                .font(SPFont.mono(.headline, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SPColor.panel)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(pulse ? 1.0 : 0.5), lineWidth: pulse ? 2.5 : 1.5)
                )
                .foregroundStyle(color)
                .scaleEffect(reduceMotion ? 1 : (pulse ? 0.97 : 1))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: pulse)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) pad")
        .accessibilityHint("Double-tap to play")
    }
}

#Preview {
    PadButton(label: "SNARE") {}
        .padding()
        .background(SPColor.background)
}
