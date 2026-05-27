import SwiftUI

/// Port of the v0.3 `renderDrumrotCard` chrome: tier banner, portrait (image with
/// emoji fallback), name plate, flavor, stats footer, OG ∞/MAX rules, locked variant.
struct DrumrotCardView: View {
    let drumrot: Drumrot
    /// Display tier (collected tier, or the base tier for locked cells).
    let tier: DrumrotTier
    var locked: Bool = false

    private enum Stat { case bpm, groove, power }

    var body: some View {
        VStack(spacing: 0) {
            banner
            portrait
            namePlate
            Text(locked ? "Not yet collected." : drumrot.flavor)
                .font(SPFont.mono(.caption2))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            statsRow
            footer
        }
        .background(SPColor.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(locked ? Color.white.opacity(0.08) : accent.opacity(0.7), lineWidth: 1.5)
        )
        .opacity(locked ? 0.6 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accent: Color { tier.color }

    private var banner: some View {
        HStack {
            Text(locked ? "★ ???" : "★ \(tier.label)")
                .font(SPFont.mono(.caption2, weight: .bold))
            Spacer()
            Text(numberDisplay)
                .font(SPFont.mono(.caption2, weight: .bold))
        }
        .foregroundStyle(locked ? Color.secondary : .black)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(locked ? AnyShapeStyle(SPColor.background) : AnyShapeStyle(accent))
    }

    private var portrait: some View {
        ZStack {
            LinearGradient(colors: [accent.opacity(0.18), .clear],
                           startPoint: .top, endPoint: .bottom)
            if locked {
                Text("???")
                    .font(SPFont.display(.largeTitle, weight: .heavy))
                    .foregroundStyle(.secondary)
            } else {
                // Emoji fallback sits behind; the image (if present) covers it.
                Text(drumrot.emoji).font(.system(size: 54))
                Image(drumrot.imageName)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(height: 132)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var namePlate: some View {
        VStack(spacing: 2) {
            Text(locked ? "???" : drumrot.name)
                .font(SPFont.display(.subheadline, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(locked ? "unknown" : drumrot.sub)
                .font(SPFont.mono(.caption2))
                .foregroundStyle(accent)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell("bpm", statText(.bpm))
            statCell("grv", statText(.groove))
            statCell("pwr", statText(.power))
        }
        .padding(.horizontal, 10)
    }

    private func statCell(_ key: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(key).font(SPFont.mono(.caption2)).foregroundStyle(.secondary)
            Text(value).font(SPFont.mono(.footnote, weight: .bold)).foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack {
            Text(numberDisplay).font(SPFont.mono(.caption2)).foregroundStyle(.secondary)
            Spacer()
            Text("sp-808 killa").font(SPFont.mono(.caption2)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var numberDisplay: String {
        if locked { return "#???" }
        return tier == .og ? "#\(drumrot.num)/OG" : "#\(drumrot.num)"
    }

    private func statText(_ stat: Stat) -> String {
        if locked { return "—" }
        if tier == .og { return stat == .power ? "MAX" : "∞" }
        let v = stat == .bpm ? drumrot.bpm : stat == .groove ? drumrot.groove : drumrot.power
        if stat == .power && v >= 99 { return "MAX" }
        return "\(v)"
    }

    private var accessibilityText: String {
        if locked { return "Locked drumrot, not yet collected." }
        return "\(drumrot.name), tier \(tier.displayName), number \(drumrot.num). "
            + "Stats: bpm \(statText(.bpm)), groove \(statText(.groove)), power \(statText(.power))."
    }
}

#Preview {
    let all = DrumrotCatalog.all
    return ScrollView {
        HStack(alignment: .top, spacing: 12) {
            if let og = all.first(where: { $0.tier == .og }) {
                DrumrotCardView(drumrot: og, tier: .og)
            }
            if let common = all.first(where: { $0.tier == .common }) {
                DrumrotCardView(drumrot: common, tier: .common)
                DrumrotCardView(drumrot: common, tier: .common, locked: true)
            }
        }
        .frame(width: 660)
        .padding()
    }
    .background(SPColor.background)
    .preferredColorScheme(.dark)
}
