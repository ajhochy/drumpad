import SwiftUI

/// Transient banner shown when an achievement unlocks.
struct AchievementToast: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 12) {
            Text(achievement.icon).font(.title2)
            VStack(alignment: .leading, spacing: 1) {
                Text(achievement.name).font(SPFont.mono(.subheadline, weight: .bold))
                Text(achievement.desc).font(SPFont.mono(.caption2)).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(SPColor.accentGreen.opacity(0.6), lineWidth: 1))
        .shadow(radius: 12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
