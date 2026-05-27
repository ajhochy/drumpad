import SwiftUI

/// Library lesson card: number, New/Played stamp, metadata, mini-notation, stars,
/// high score. Mirrors the web library card.
struct LessonCardView: View {
    let index: Int
    let lesson: Lesson
    let score: LessonScore?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("#\(index + 1)")
                        .font(SPFont.mono(.caption, weight: .bold))
                        .foregroundStyle(SPColor.accentGreen)
                    Spacer()
                    Text(score == nil ? "NEW" : "PLAYED")
                        .font(SPFont.mono(.caption2, weight: .bold))
                        .foregroundStyle(score == nil ? SPColor.accentPink : .secondary)
                }
                Text(lesson.name)
                    .font(SPFont.display(.headline, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text("\(lesson.bpm) BPM · \(lesson.genre) · \(lesson.difficulty)")
                    .font(SPFont.mono(.caption2)).foregroundStyle(.secondary)
                miniNotation
                HStack {
                    stars
                    Spacer()
                    if let high = score?.high, high > 0 {
                        Text("\(high)").font(SPFont.mono(.caption, weight: .bold))
                            .foregroundStyle(SPColor.accentGreen)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SPColor.panel)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(lesson.name), \(lesson.bpm) BPM, \(lesson.difficulty). \(score?.stars ?? 0) stars.")
    }

    private var stars: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { i in
                Image(systemName: i < (score?.stars ?? 0) ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(i < (score?.stars ?? 0) ? SPColor.accentOrange : .secondary)
            }
        }
    }

    /// Compact lane × step dot grid from the lesson's first bar.
    private var miniNotation: some View {
        let steps = min(lesson.beatsPerBar, 16)
        let laneSet: [Int] = Array(Set(lesson.notes.map(\.lane))).sorted()
        let beats = Set(lesson.notes.filter { $0.beat < steps }.map { "\($0.lane)-\($0.beat)" })
        return VStack(spacing: 2) {
            ForEach(laneSet, id: \.self) { lane in
                HStack(spacing: 2) {
                    ForEach(0..<steps, id: \.self) { step in
                        Circle()
                            .fill(beats.contains("\(lane)-\(step)") ? SPColor.accentGreen : Color.white.opacity(0.08))
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
    }
}
