import SwiftUI

/// Full-screen drop reveal. Auto-dismisses after 6s (9s for OG), or on tap.
/// Honors Reduce Motion (cross-fade instead of scale-in).
struct RevealOverlay: View {
    let item: AppStore.RevealItem
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    private var isOG: Bool { item.tier == .og }

    private var badge: String {
        guard item.isNew else { return "↑ UPGRADED TIER" }
        return isOG ? "⭐ FIRST OG!" : "✦ NEW!"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(badge)
                    .font(SPFont.mono(.headline, weight: .bold))
                    .foregroundStyle(isOG ? SPColor.accentPink : SPColor.accentGreen)
                DrumrotCardView(drumrot: item.drumrot, tier: item.tier)
                    .frame(width: 300)
                    .shadow(color: item.tier.color.opacity(0.5), radius: 30)
                Text("from “\(item.fromAchievement)”")
                    .font(SPFont.mono(.caption))
                    .foregroundStyle(.secondary)
                Text("tap to dismiss")
                    .font(SPFont.mono(.caption2))
                    .foregroundStyle(.tertiary)
            }
            .scaleEffect(reduceMotion ? 1 : (shown ? 1 : 0.85))
            .opacity(shown ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { onDismiss() }
        .task {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { shown = true }
            try? await Task.sleep(for: .seconds(isOG ? 9 : 6))
            onDismiss()
        }
    }
}

#Preview {
    let og = DrumrotCatalog.all.first { $0.tier == .og }!
    return RevealOverlay(
        item: .init(drumrot: og, tier: .og, fromAchievement: "First Hit", isNew: true),
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
