import SwiftUI

struct DropsView: View {
    @EnvironmentObject private var persistence: PersistenceStore
    private var collection: [DrumrotCollectionEntry] { persistence.collection }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    private var collectedTiers: [String: Int] {
        Dictionary(collection.map { ($0.drumrotId, $0.tierIndex) }, uniquingKeysWith: max)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            infoColumn
                .frame(width: 300)
            collectionPanel
        }
        .padding(14)
    }

    // MARK: - Left: info column

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("Patch").font(SPFont.display(28)).foregroundStyle(SPColor.text)
                Text("Drops").font(SPFont.display(28)).foregroundStyle(SPColor.ledAmberHot)
            }

            Text("EARN DROPS BY CLEARING LESSONS.\nCOLLECT ALL 31 DRUMROT CHARACTERS.\nOG TIER = ∞/MAX STATS.")
                .font(SPFont.monoMicro).tracking(1.8)
                .foregroundStyle(SPColor.textDim).lineSpacing(2)

            // Progress LCD panel
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("COLLECTION PROGRESS")
                        .font(SPFont.monoSmall).tracking(1.8).foregroundStyle(SPColor.lcdFG)
                        .shadow(color: SPColor.lcdFG.opacity(0.4), radius: 2)
                    Spacer()
                    liveIndicator
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("COLLECTED")
                            .font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.lcdDim)
                        Spacer()
                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            Text("\(collectedTiers.count)")
                                .font(SPFont.lcd(32)).foregroundStyle(SPColor.lcdFG)
                                .shadow(color: SPColor.lcdFG.opacity(0.5), radius: 6)
                            Text("/ \(DrumrotCatalog.all.count)")
                                .font(SPFont.lcd(16)).foregroundStyle(SPColor.lcdDim)
                        }
                    }
                    SPProgressBar(
                        progress: DrumrotCatalog.all.isEmpty ? 0
                            : Double(collectedTiers.count) / Double(DrumrotCatalog.all.count),
                        height: 10
                    )
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .lcdPanel(cornerRadius: 10)

            // Tier breakdown
            VStack(alignment: .leading, spacing: 6) {
                SPModuleTitle(title: "Tier Breakdown")
                ForEach(DrumrotTier.order, id: \.self) { tier in
                    let total = DrumrotCatalog.all.filter { $0.tier == tier }.count
                    if total > 0 {
                        let collectedCount = DrumrotCatalog.all.filter {
                            $0.tier == tier && collectedTiers[$0.id] != nil
                        }.count
                        tierRow(tier: tier, collected: collectedCount, total: total)
                    }
                }
            }
            .chassisModule()

            Spacer(minLength: 0)

            SPScribble(text: "save 'em up!", color: SPColor.stickerPink, rotation: -4)
                .padding(.leading, 14)
        }
        .padding(18)
        .background(LinearGradient(colors: [Color(hex: 0x2C2F36), SPColor.chassis2],
                                   startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SPColor.ink, lineWidth: 1))
    }

    private var liveIndicator: some View {
        HStack(spacing: 5) {
            SPLED(tone: .green, size: 6)
            Text("LIVE").font(SPFont.monoSmall).tracking(1.8).foregroundStyle(SPColor.ledGreen)
                .shadow(color: SPColor.ledGreen.opacity(0.5), radius: 2)
        }
    }

    private func tierRow(tier: DrumrotTier, collected: Int, total: Int) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tier.color)
                .frame(width: 10, height: 10)
                .shadow(color: tier.color, radius: 3)
            Text(tier.label)
                .font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.textDim)
            Spacer()
            Text("\(collected)/\(total)")
                .font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.ledAmberHot)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(SPColor.ink)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Right: collection panel

    private var collectionPanel: some View {
        let all = DrumrotCatalog.all
        let collected = collectedTiers
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("My").font(SPFont.display(24)).foregroundStyle(SPColor.text)
                    Text("Crates").font(SPFont.display(24)).foregroundStyle(SPColor.stickerPink)
                }
                Spacer()
                Text("\(collected.count) / \(all.count) PULLED")
                    .font(SPFont.monoSmall).tracking(1.8).foregroundStyle(SPColor.textDim)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(all) { drumrot in
                        let tierIdx = collected[drumrot.id]
                        let hasIt = tierIdx != nil
                        let tier = tierIdx.flatMap {
                            DrumrotTier.order.indices.contains($0) ? DrumrotTier.order[$0] : nil
                        } ?? drumrot.tier
                        DrumrotCardView(drumrot: drumrot, tier: tier, locked: !hasIt)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(16)
        .chassisFace()
    }
}

#Preview {
    DropsView()
        .environmentObject(PersistenceStore(defaults: nil))
        .preferredColorScheme(.dark)
}
