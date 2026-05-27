import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Query private var playDays: [PracticeDay]
    @Query private var scores: [LessonScore]
    @Query private var unlocks: [AchievementUnlock]

    private var daySet: Set<String> { Set(playDays.map(\.day)) }
    private var unlockedIds: Set<String> { Set(unlocks.map(\.achievementId)) }
    private var streak: Int { PracticeStreak.current(playDays: daySet) }
    private var totalSessions: Int { scores.reduce(0) { $0 + $1.plays } }
    private var bestScore: Int { scores.map(\.high).max() ?? 0 }
    private var topAccuracy: Int { scores.map(\.lastAccuracy).max() ?? 0 }

    var body: some View {
        ZStack {
            SPColor.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statRow
                    calendar
                    achievementsSection
                }
                .padding(16)
            }
        }
    }

    private var statRow: some View {
        HStack(spacing: 12) {
            statCard("🔥 \(streak)", "day streak")
            statCard("\(totalSessions)", "sessions")
            statCard("\(bestScore)", "best score")
            statCard(topAccuracy > 0 ? "\(topAccuracy)%" : "—", "top accuracy")
        }
    }

    private func statCard(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(SPFont.mono(.title3, weight: .bold)).foregroundStyle(SPColor.accentGreen)
            Text(label).font(SPFont.mono(.caption2)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(SPColor.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var calendar: some View {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"; fmt.timeZone = TimeZone(identifier: "UTC")
        let cal = Calendar(identifier: .gregorian)
        return VStack(alignment: .leading, spacing: 8) {
            Text("LAST 14 DAYS").font(SPFont.mono(.caption, weight: .bold)).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach((0..<14).reversed(), id: \.self) { offset in
                    let date = cal.date(byAdding: .day, value: -offset, to: Date())!
                    let on = daySet.contains(fmt.string(from: date))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(on ? SPColor.accentGreen : Color.white.opacity(0.08))
                        .frame(height: 28)
                }
            }
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACHIEVEMENTS \(unlockedIds.count)/\(AchievementCatalog.all.count)")
                .font(SPFont.mono(.caption, weight: .bold)).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(AchievementCatalog.all) { ach in
                    let unlocked = unlockedIds.contains(ach.id)
                    HStack(spacing: 8) {
                        Text(ach.icon).font(.title3)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(ach.name).font(SPFont.mono(.caption2, weight: .bold)).lineLimit(1)
                            Text(ach.desc).font(SPFont.mono(.caption2)).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SPColor.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .opacity(unlocked ? 1 : 0.4)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(unlocked ? SPColor.accentGreen.opacity(0.6) : .clear, lineWidth: 1))
                }
            }
        }
    }
}

#Preview {
    ProgressTabView()
        .modelContainer(AppModelContainer.make(inMemory: true))
        .preferredColorScheme(.dark)
}
