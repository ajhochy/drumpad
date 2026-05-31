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

    /// True when the player has an active streak but hasn't practiced today yet.
    private var streakAtRisk: Bool {
        guard streak > 0 else { return false }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        let todayKey = fmt.string(from: Date())
        return !daySet.contains(todayKey)
    }

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

            // Streak-at-risk callout (issue #72)
            if streakAtRisk {
                HStack(spacing: 8) {
                    Text("🥁").font(.body)
                    Text("Practice today to keep your streak alive!")
                        .font(SPFont.monoSmall).tracking(1.2)
                        .foregroundStyle(SPColor.ledAmberHot)
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SPColor.ledAmberHot.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(SPColor.ledAmberHot.opacity(0.4), lineWidth: 1))
            }

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
        // Group achievements by category for the quest-log layout.
        let categories = [
            ("on_the_kit", "🥁", "On the Kit"),
            ("showing_up", "📅", "Showing Up"),
            ("speed_runs", "⚡", "Speed Runs"),
            ("craft_crew", "🎛️", "Craft Crew"),
        ]
        let byCategory = Dictionary(grouping: AchievementCatalog.all) { $0.cat }

        return VStack(alignment: .leading, spacing: 10) {
            SPModuleTitle(
                title: "Achievements",
                meta: "\(unlockedIds.count)/\(AchievementCatalog.all.count)"
            )

            ForEach(categories, id: \.0) { (catId, catIcon, catName) in
                let catAchs = byCategory[catId] ?? []
                if !catAchs.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        // Category header
                        HStack(spacing: 6) {
                            Text(catIcon).font(.caption)
                            Text(catName.uppercased())
                                .font(SPFont.monoSmall).tracking(1.8)
                                .foregroundStyle(SPColor.ledAmber)
                        }
                        .padding(.bottom, 2)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                            spacing: 8
                        ) {
                            ForEach(catAchs) { ach in
                                achievementBadge(ach)
                            }
                        }
                    }
                    .padding(.bottom, 8)
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
        let isSecret = ach.isSecret && !unlocked

        return HStack(spacing: 8) {
            // Icon: padlock for secret+locked, category icon for non-secret+locked, achievement icon when unlocked
            if isSecret {
                Text("🔒").font(.title3)
            } else if unlocked {
                Text(ach.icon).font(.title3)
            } else {
                Text(ach.categoryIcon).font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                if isSecret {
                    Text("???")
                        .font(SPFont.ui(11, weight: .bold)).tracking(0.4)
                        .foregroundStyle(SPColor.textDim)
                        .lineLimit(1)
                    Text("Secret achievement")
                        .font(SPFont.monoMicro).tracking(0.5)
                        .foregroundStyle(SPColor.textDim).lineLimit(1)
                } else {
                    Text(ach.name)
                        .font(SPFont.ui(11, weight: .bold)).tracking(0.4)
                        .foregroundStyle(unlocked ? SPColor.text : SPColor.textDim)
                        .lineLimit(1)
                    // Show hint for non-secret, locked achievements
                    let hintText = unlocked ? ach.desc : (ach.hint.isEmpty ? ach.desc : ach.hint)
                    Text(hintText)
                        .font(SPFont.monoMicro).tracking(0.5)
                        .foregroundStyle(SPColor.textDim).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .overlay(alignment: .topTrailing) {
            // Difficulty badge (not shown for secret achievements)
            if !isSecret {
                difficultyBadge(ach.dropDifficulty)
                    .padding(4)
            }
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
        .opacity(unlocked ? 1 : (isSecret ? 0.35 : 0.55))
        .accessibilityLabel(isSecret ? "Secret achievement — locked" : "\(ach.name): \(ach.desc). \(unlocked ? "Unlocked" : "Locked")")
    }

    private func difficultyBadge(_ difficulty: DropDifficulty) -> some View {
        let (color, label): (Color, String) = {
            switch difficulty {
            case .entry:  return (SPColor.ledGreen,    "ENTRY")
            case .easy:   return (SPColor.lcdFG,       "EASY")
            case .medium: return (SPColor.ledAmber,    "MED")
            case .hard:   return (SPColor.ledAmberHot, "HARD")
            case .elite:  return (SPColor.stickerPink, "ELITE")
            }
        }()
        return Text(label)
            .font(SPFont.monoMicro).tracking(1)
            .foregroundStyle(color)
            .padding(.horizontal, 4).padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

#Preview {
    ProgressTabView()
        .modelContainer(AppModelContainer.make(inMemory: true))
        .preferredColorScheme(.dark)
}
