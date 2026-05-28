import SwiftUI

/// On-screen MIDI activity overlay (#58).
///
/// In DEBUG builds this floats over the Play highway so we can see what's
/// arriving from CoreMIDI on a real device. In Release it backs the
/// `SettingsView → MIDI → Recent activity` disclosure (no floating panel).
///
/// Each row shows `note=N vel=V` and either the mapped lane tag
/// (`→ CRSH/HHAT/...`) or `→ unmapped` so we can distinguish CoreMIDI
/// delivery failures from GM-mapping gaps.
struct MIDIDiagnosticOverlay: View {
    @ObservedObject var midi: MIDIInputManager
    var compact: Bool = true

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            if midi.recentEvents.isEmpty {
                Text("no events")
                    .font(SPFont.mono(.caption2))
                    .foregroundStyle(SPColor.lcdDim)
            } else {
                ForEach(midi.recentEvents.reversed()) { event in
                    row(event)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(compact ? 0.55 : 0))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(SPColor.lcdFg.opacity(compact ? 0.25 : 0), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text("MIDI RX")
                .font(SPFont.mono(.caption2, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(SPColor.ledGreen)
            Text("\(midi.recentEvents.count) / src \(midi.sources.count)")
                .font(SPFont.mono(.caption2))
                .foregroundStyle(SPColor.lcdDim)
        }
    }

    private func row(_ event: MIDIInputManager.RecentEvent) -> some View {
        HStack(spacing: 4) {
            Text(Self.timeFormatter.string(from: event.timestamp))
                .foregroundStyle(SPColor.lcdDim)
            Text("n=\(event.note)")
                .foregroundStyle(SPColor.lcdFg)
            Text("v=\(event.velocity)")
                .foregroundStyle(SPColor.lcdFg)
            Text("→")
                .foregroundStyle(SPColor.lcdDim)
            if let lane = event.lane {
                Text(laneTag(lane))
                    .foregroundStyle(SPColor.lane(lane.rawValue))
                    .bold()
            } else {
                Text("unmapped")
                    .foregroundStyle(SPColor.ledAmber)
            }
        }
        .font(SPFont.mono(.caption2))
    }

    private func laneTag(_ lane: DrumLane) -> String {
        switch lane {
        case .crash: "CRSH"
        case .hihat: "HHAT"
        case .snare: "SNRE"
        case .kick:  "KICK"
        case .tom:   "TOMS"
        case .ride:  "RIDE"
        }
    }
}
