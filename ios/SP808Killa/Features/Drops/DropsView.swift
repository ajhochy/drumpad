import SwiftUI
import SwiftData

struct DropsView: View {
    @Query private var collection: [DrumrotCollectionEntry]

    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 14)]

    private var collectedTiers: [String: Int] {
        Dictionary(collection.map { ($0.drumrotId, $0.tierIndex) }, uniquingKeysWith: max)
    }

    var body: some View {
        let all = DrumrotCatalog.all
        let collected = collectedTiers
        ZStack {
            SPColor.background.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(all) { drumrot in
                        let tierIdx = collected[drumrot.id]
                        let hasIt = tierIdx != nil
                        let tier = tierIdx.flatMap { DrumrotTier.order.indices.contains($0) ? DrumrotTier.order[$0] : nil } ?? drumrot.tier
                        DrumrotCardView(drumrot: drumrot, tier: tier, locked: !hasIt)
                    }
                }
                .padding(16)
            }
        }
        .safeAreaInset(edge: .top) {
            Text("\(collected.count) / \(all.count) collected")
                .font(SPFont.mono(.subheadline, weight: .bold))
                .foregroundStyle(SPColor.accentGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
        }
    }
}

#Preview {
    DropsView()
        .modelContainer(AppModelContainer.make(inMemory: true))
        .preferredColorScheme(.dark)
}
