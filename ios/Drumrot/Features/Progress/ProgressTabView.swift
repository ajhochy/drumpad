import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject private var persistence: PersistenceStore
    private var playDays: [PracticeDay] { persistence.playDays }
    private var scores: [LessonScore] { persistence.scores }
    private var unlocks: [AchievementUnlock] { persistence.unlocks }

    private var daySet: Set<String> { Set(playDays.map(\.day)) }
    private var unlockedIds: Set<String> { Set(unlocks.map(\.achievementId)) }
    private var streak: Int { PracticeStreak.current(playDays: daySet) }
    private var totalSessions: Int { scores.reduce(0) { $0 + $1.plays } }
    private var bestScore: Int { scores.map(\.high).max() ?? 0 }
    private var topAccuracy: Int { scores.map(\.lastAccuracy).max() ?? 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                pageHeader

                HStack(alignment: .top, spacing: 14) {
                    streakModule.frame(width: 280)
                    activityModule.frame(maxWidth: .infinity)
                }

                HStack(alignment: .top, spacing: 14) {
                    statsModule.frame(width: 280)
                    achievementsModule.frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 22).padding(.vertical, 16)
        }
    }

    // MARK: - Page header

    private var pageHeader: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 8) {
                Text("Tour").font(SPFont.display(32)).foregroundStyle(SPColor.text)
                Text("Diary").font(SPFont.display(32)).foregroundStyle(SPColor.stickerPink)
            }
            Spacer()
            Text("STATS FROM THE PRACTICE ROOM · LAST 14 DAYS\nKEEP THE KIT WARM · DON'T DROP THE STREAK")
                .font(SPFont.monoMicro).tracking(1.8)
                .foregroundStyle(SPColor.textDim).multilineTextAlignment(.trailing)
        }
        .padding(.bottom, 12)
        .overlay(Rectangle().fill(SPColor.ink).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Streak module

    private var streakModule: some View {
        VStack(alignment: .leading, spacing: 10) {
            SPModuleTitle(title: "Day Streak", meta: "LIVE")

            // Big LCD readout
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT").font(SPFont.monoMicro).tracking(1.8).foregroundStyle(SPColor.lcdDim)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(streak > 0 ? "🔥 \(streak)" : "\(streak)")
                        .font(SPFont.lcd(44)).foregroundStyle(SPColor.lcdFG)
                        .shadow(color: SPColor.lcdFG.opacity(0.5), radius: 6)
                    Text("d").font(SPFont.lcd(20)).foregroundStyle(SPColor.lcdDim)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lcdPanel()

            Text("LAST 14 DAYS").font(SPFont.monoMicro).tracking(1.8).foregroundStyle(SPColor.textDim)

            calendarStrip
        }
        .padding(14)
        .background(LinearGradient(colors: [Color(hex: 0x2C2F36), SPColor.chassis2],
                                   startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SPColor.ink, lineWidth: 1))
        .overlay(alignment: .bottomTrailing) {
            SPDymo(text: "DO NOT BREAK", rotation: 2).padding(14)
        }
    }

    private var calendarStrip: some View {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        let cal = Calendar(identifier: .gregorian)
        return HStack(spacing: 5) {
            ForEach((0..<14).reversed(), id: \.self) { offset in
                let date = cal.date(byAdding: .day, value: -offset, to: Date())!
                let key = fmt.string(from: date)
                let on = daySet.contains(key)
                let isToday = offset == 0
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(on ? SPColor.ledGreen : Color.white.opacity(0.08))
                        .frame(height: 28)
                        .shadow(color: on ? SPColor.ledGreen.opacity(0.5) : .clear, radius: 4)
                    Text(isToday ? "▲" : "")
                        .font(.system(size: 7))
                        .foregroundStyle(SPColor.ledAmber)
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel(on ? "Practiced" : "No practice")
            }
        }
    }

    // MARK: - Activity module

    private var activityModule: some View {
        VStack(alignment: .leading, spacing: 10) {
            SPModuleTitle(title: "Activity", meta: "\(totalSessions) SESSIONS")

            // 14-day heatmap expanded to 4-week view
            fourWeekHeatmap

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [Color(hex: 0x2C2F36), SPColor.chassis2],
                                   startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SPColor.ink, lineWidth: 1))
    }

    private var fourWeekHeatmap: some View {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        let cal = Calendar(identifier: .gregorian)
        let days = (0..<28).reversed().map { offset -> (String, Bool) in
            let date = cal.date(byAdding: .day, value: -offset, to: Date())!
            let key = fmt.string(from: date)
            return (key, daySet.contains(key))
        }
        let weekLabels = ["M", "T", "W", "T", "F", "S", "S"]
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(weekLabels, id: \.self) { label in
                    Text(label).font(SPFont.monoMicro).tracking(1).foregroundStyle(SPColor.textDim)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<4, id: \.self) { week in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { day in
                        let idx = week * 7 + day
                        let on = idx < days.count ? days[idx].1 : false
                        RoundedRectangle(cornerRadius: 3)
                            .fill(on ? SPColor.ledGreen : Color.white.opacity(0.07))
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .shadow(color: on ? SPColor.ledGreen.opacity(0.4) : .clear, radius: 3)
                    }
                }
            }
        }
    }

    // MARK: - Stats module

    private var statsModule: some View {
        VStack(alignment: .leading, spacing: 10) {
            SPModuleTitle(title: "Personal Bests")

            VStack(spacing: 6) {
                statRow(label: "TOP SCORE", value: "\(bestScore)", glowColor: SPColor.ledAmberHot)
                statRow(label: "TOP ACCURACY",
                        value: topAccuracy > 0 ? "\(topAccuracy)%" : "—",
                        glowColor: SPColor.lcdFG)
                statRow(label: "TOTAL SESSIONS", value: "\(totalSessions)", glowColor: SPColor.ledAmber)
                statRow(label: "LESSONS PLAYED",
                        value: "\(scores.filter { $0.plays > 0 }.count)",
                        glowColor: SPColor.stickerCyan)
            }
        }
        .padding(14)
        .background(LinearGradient(colors: [Color(hex: 0x2C2F36), SPColor.chassis2],
                                   startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SPColor.ink, lineWidth: 1))
    }

    private func statRow(label: String, value: String, glowColor: Color) -> some View {
        HStack {
            Text(label).font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.textDim)
            Spacer()
            Text(value)
                .font(SPFont.lcd(18)).foregroundStyle(glowColor)
                .shadow(color: glowColor.opacity(0.5), radius: 4)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(SPColor.ink)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    // MARK: - Achievements module

    private var achievementsModule: some View {
        VStack(alignment: .leading, spacing: 10) {
            SPModuleTitle(
                title: "Achievements",
                meta: "\(unlockedIds.count)/\(AchievementCatalog.all.count)"
            )

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                spacing: 8
            ) {
                ForEach(AchievementCatalog.all) { ach in
                    achievementBadge(ach)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(hex: 0x2C2F36), SPColor.chassis2],
                                   startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SPColor.ink, lineWidth: 1))
    }

    private func achievementBadge(_ ach: Achievement) -> some View {
        let unlocked = unlockedIds.contains(ach.id)
        return HStack(spacing: 8) {
            Text(ach.icon).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(ach.name)
                    .font(SPFont.ui(11, weight: .bold)).tracking(0.4)
                    .foregroundStyle(unlocked ? SPColor.text : SPColor.textDim)
                    .lineLimit(1)
                Text(ach.desc)
                    .font(SPFont.monoMicro).tracking(0.5)
                    .foregroundStyle(SPColor.textDim).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            unlocked
            ? AnyShapeStyle(LinearGradient(
                colors: [SPColor.ledAmber.opacity(0.12), SPColor.ink],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            : AnyShapeStyle(SPColor.ink)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(unlocked ? SPColor.ledAmber.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1)
        )
        .opacity(unlocked ? 1 : 0.45)
        .accessibilityLabel("\(ach.name): \(ach.desc). \(unlocked ? "Unlocked" : "Locked")")
    }
}

#Preview {
    ProgressTabView()
        .environmentObject(PersistenceStore(defaults: nil))
        .preferredColorScheme(.dark)
}
