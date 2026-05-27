import SwiftUI

/// Temporary scaffold screen for tabs whose real content lands in later phases.
struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        ZStack {
            SPColor.background.ignoresSafeArea()
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                    .foregroundStyle(SPColor.accentGreen)
                Text("drumrot")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PlaceholderScreen(title: "PLAY")
        .preferredColorScheme(.dark)
}
