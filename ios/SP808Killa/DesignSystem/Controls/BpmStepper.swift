import SwiftUI

/// Tempo control clamped to the web's 40–200 BPM range.
struct BpmStepper: View {
    @Binding var bpm: Int
    var range: ClosedRange<Int> = 40...200

    var body: some View {
        HStack(spacing: 14) {
            stepButton("minus") { bpm = max(range.lowerBound, bpm - 1) }
            VStack(spacing: 0) {
                Text("\(bpm)")
                    .font(SPFont.mono(.title2, weight: .bold))
                    .foregroundStyle(SPColor.accentGreen)
                Text("BPM").font(SPFont.mono(.caption2)).foregroundStyle(.secondary)
            }
            .frame(minWidth: 64)
            stepButton("plus") { bpm = min(range.upperBound, bpm + 1) }
        }
    }

    private func stepButton(_ symbol: String, _ act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Image(systemName: symbol)
                .font(.headline)
                .frame(width: 40, height: 40)
                .background(Circle().fill(SPColor.panel))
                .foregroundStyle(SPColor.accentGreen)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StatefulPreviewWrapper(96) { BpmStepper(bpm: $0) }
        .padding()
        .background(SPColor.background)
}

/// Tiny helper so `#Preview` can host a binding.
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content
    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initial)
        self.content = content
    }
    var body: some View { content($value) }
}
