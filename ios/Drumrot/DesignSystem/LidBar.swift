// ============================================================
// LidBar.swift
// drumrot · SP-808 KILLA — iPad
//
// Custom top bar replacing the default TabView chrome — the
// "chassis lid" with brand badge, screws, PWR/MIDI LEDs and the
// 5 tab buttons. Drive `selection` from your TabView via a
// custom selection binding.
// ============================================================

import SwiftUI

enum SPTab: String, CaseIterable, Identifiable {
    case play, library, progress, build, drops
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .play:     return "play.fill"
        case .library:  return "rectangle.stack.fill"
        case .progress: return "chart.bar.fill"
        case .build:    return "square.grid.3x3.fill"
        case .drops:    return "rectangle.portrait.on.rectangle.portrait.angled"
        }
    }
}

struct SPLidBar: View {
    @Binding var selection: SPTab
    @Binding var midiConnected: Bool
    var onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 18) {

            // ---- BRAND ----
            HStack(spacing: 14) {
                SPScrew()

                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LinearGradient(colors: [SPColor.ledAmber, SPColor.ledRed],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 46, height: 46)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(SPColor.ink, lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.6), radius: 4, y: 4)

                    Text("SP")
                        .font(SPFont.display(22))
                        .foregroundStyle(SPColor.roomBG)

                    // sticker peel
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(SPColor.stickerYellow)
                        .rotationEffect(.degrees(-12))
                        .offset(x: 22, y: -22)
                        .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("SP-808 KILLA")
                        .font(SPFont.display(22))
                        .tracking(0.4)
                        .foregroundStyle(SPColor.text)
                    Text("DRUM TRAINER · IPAD · FW 2.6.1")
                        .font(SPFont.monoMicro).tracking(1.8)
                        .foregroundStyle(SPColor.textDim)
                }
            }

            Spacer()

            // ---- TABS ----
            HStack(spacing: 8) {
                ForEach(SPTab.allCases) { tab in
                    SPTabButton(tab: tab, active: selection == tab) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            selection = tab
                        }
                    }
                }
            }

            Spacer()

            // ---- LID RIGHT ----
            HStack(spacing: 14) {
                HStack(spacing: 5) {
                    SPLED(tone: .green)
                    Text("PWR").font(SPFont.monoMicro).tracking(1.5).foregroundStyle(SPColor.textDim)
                }
                HStack(spacing: 5) {
                    SPLED(tone: midiConnected ? .red : .off)
                    Text("MIDI").font(SPFont.monoMicro).tracking(1.5).foregroundStyle(SPColor.textDim)
                }

                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(SPColor.textDim)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(
                                RadialGradient(colors: [SPColor.rubberHi, SPColor.rubber, Color(hex: 0x14161A)],
                                               center: .init(x: 0.35, y: 0.30),
                                               startRadius: 0, endRadius: 22)
                            )
                        )
                        .overlay(Circle().stroke(SPColor.ink, lineWidth: 1))
                        .shadow(color: .black.opacity(0.6), radius: 2, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")

                SPScrew()
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .background(
            LinearGradient(colors: [Color(hex: 0x34383F), SPColor.chassis, SPColor.chassis2],
                           startPoint: .top, endPoint: .bottom)
        )
        .overlay(
            // bright top edge highlight
            Rectangle()
                .fill(LinearGradient(colors: [.clear,
                                              Color.white.opacity(0.18),
                                              Color.white.opacity(0.18),
                                              .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 1),
            alignment: .top
        )
        .overlay(Rectangle().fill(SPColor.ink).frame(height: 1), alignment: .bottom)
    }
}

// MARK: - Tab button

private struct SPTabButton: View {
    let tab: SPTab
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon).font(.system(size: 12, weight: .bold))
                Text(tab.title.uppercased())
                    .font(SPFont.ui(12, weight: .bold))
                    .tracking(1.4)
            }
            .foregroundStyle(active ? SPColor.ledAmberHot : SPColor.textDim)
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(
                LinearGradient(
                    colors: active ? [SPColor.roomBG, Color(hex: 0x14161A)]
                                   : [Color(hex: 0x2F333A), Color(hex: 0x1F2127)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(SPColor.ink, lineWidth: 1))
            .overlay(alignment: .top) {
                // amber pip when active
                if active {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(SPColor.ledAmber)
                        .frame(width: 8, height: 3)
                        .offset(y: -3)
                        .shadow(color: SPColor.ledAmber, radius: 4)
                }
            }
            .shadow(color: active ? SPColor.ledAmber.opacity(0.25) : .black.opacity(0.4),
                    radius: active ? 12 : 3, y: active ? 0 : 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(active ? [.isSelected, .isButton] : .isButton)
    }
}
