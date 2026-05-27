// ============================================================
// Components.swift
// drumrot · SP-808 KILLA — iPad
//
// Reusable chassis-language widgets used across surfaces:
//
//   SPPad             — rubber drum pad (with LED + label + key hint)
//   SPSwitch          — physical toggle ("Click", "Loop", etc.)
//   SPStepper         — value with -/+ buttons
//   SPPushButton      — chassis push button (transport, tabs, tools)
//   SPSticker         — yellow Bungee badge ("NEW", "PROPERTY OF...")
//   SPDymo            — Dymo / typewriter strip label
//   SPScribble        — Permanent Marker scribble text
//   SPSegments        — segmented physical buttons (settings)
//   SPSlider          — chassis slider with glow knob
//   SPProgressBar     — amber→red horizontal fill bar
//   SPKnob            — turn-knob for FX
//
// All visual — no business logic, no state for cross-screen data.
// Pure presentation, suitable for swapping into existing views.
// ============================================================

import SwiftUI

// MARK: - SPPad

struct SPPad: View {
    let title: String
    let keyHint: String
    var lane: Int = 0
    var isHit: Bool = false

    private var rim: Color { SPColor.laneColors[lane % 6] }

    var body: some View {
        ZStack {
            // body
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [SPColor.rubberHi, SPColor.rubber, SPColor.roomBG],
                        center: .init(x: 0.5, y: 0.3),
                        startRadius: 0, endRadius: 90
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(SPColor.ink, lineWidth: 1)
                )
                .overlay( // inner rim
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(rim.opacity(isHit ? 0.9 : 0.25), lineWidth: 1)
                        .padding(3)
                )
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: isHit ? 0 : 4)

            // tiny LED top-right
            VStack {
                HStack {
                    Spacer()
                    SPLED(tone: .amber, size: 6)
                        .overlay(Circle().fill(rim).frame(width: 6, height: 6).shadow(color: rim, radius: 4))
                }
                Spacer()
            }
            .padding(7)

            // label + key
            VStack(spacing: 4) {
                Text(title.uppercased())
                    .font(SPFont.ui(12, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(SPColor.text)
                Text(keyHint)
                    .font(SPFont.monoMicro)
                    .tracking(1.5)
                    .foregroundStyle(SPColor.textDim)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(SPColor.ink)
                    .overlay(Rectangle().stroke(.black, lineWidth: 1))
            }
        }
        .frame(minHeight: 62)
        .offset(y: isHit ? 3 : 0)
        .animation(.spring(response: 0.12, dampingFraction: 0.6), value: isHit)
    }
}

// MARK: - SPSwitch

struct SPSwitch: View {
    @Binding var isOn: Bool
    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(
                    isOn
                    ? AnyShapeStyle(LinearGradient(colors: [SPColor.ledAmber, Color(hex: 0xC45A10)],
                                                   startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(SPColor.roomBG)
                )
                .frame(width: 38, height: 18)
                .overlay(Capsule().stroke(.black, lineWidth: 1))
                .shadow(color: isOn ? SPColor.ledAmber.opacity(0.4) : .clear, radius: 6)

            Circle()
                .fill(
                    LinearGradient(
                        colors: isOn ? [Color(hex: 0xFFD0A0), SPColor.ledAmber]
                                     : [Color(hex: 0x828791), SPColor.screw],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 14, height: 14)
                .padding(2)
                .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
        }
        .contentShape(Capsule())
        .onTapGesture { withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { isOn.toggle() } }
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? Text("on") : Text("off"))
    }
}

// MARK: - SPPushButton

struct SPPushButton<Label: View>: View {
    enum Variant { case neutral, primary, danger }

    let variant: Variant
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    init(_ variant: Variant = .neutral, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.variant = variant
        self.action = action
        self.label = label
    }

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            label()
                .font(SPFont.ui(11, weight: .bold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(foreground)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
                )
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(SPColor.ink, lineWidth: 1))
                .shadow(color: shadowGlow, radius: 12)
                .shadow(color: .black.opacity(0.4), radius: 2, y: 2)
                .offset(y: pressed ? 2 : 0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }

    private var foreground: Color {
        switch variant {
        case .primary: return Color(hex: 0x1A0C00)
        case .danger:  return .white
        case .neutral: return SPColor.text
        }
    }
    private var gradientColors: [Color] {
        switch variant {
        case .primary: return [SPColor.ledAmber, Color(hex: 0xC45A10)]
        case .danger:  return [SPColor.ledRed, Color(hex: 0xA01A35)]
        case .neutral: return [Color(hex: 0x34383F), Color(hex: 0x1F2127)]
        }
    }
    private var shadowGlow: Color {
        switch variant {
        case .primary: return SPColor.ledAmber.opacity(0.3)
        case .danger:  return SPColor.ledRed.opacity(0.3)
        case .neutral: return .clear
        }
    }
}

// MARK: - SPSticker / SPDymo / SPScribble

struct SPSticker: View {
    let text: String
    var rotation: Double = -5
    var body: some View {
        Text(text.uppercased())
            .font(SPFont.display(11))
            .tracking(0.6)
            .foregroundStyle(SPColor.ink)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Capsule().fill(SPColor.stickerYellow))
            .overlay(Capsule().stroke(SPColor.roomBG, lineWidth: 2))
            .shadow(color: .black.opacity(0.7), radius: 6, y: 2)
            .rotationEffect(.degrees(rotation))
    }
}

struct SPDymo: View {
    let text: String
    var red: Bool = false
    var rotation: Double = -3
    var body: some View {
        Text(text.uppercased())
            .font(SPFont.dymo)
            .tracking(2)
            .foregroundStyle(red ? Color.white : SPColor.roomBG)
            .padding(.horizontal, 8).padding(.vertical, 2)
            .background(red ? SPColor.dymoRed : SPColor.dymo)
            .overlay(
                Rectangle().stroke(Color.white.opacity(0.4), lineWidth: 1).offset(y: -0.5)
            )
            .shadow(color: .black.opacity(0.6), radius: 3, y: 2)
            .rotationEffect(.degrees(rotation))
    }
}

struct SPScribble: View {
    let text: String
    var color: Color = SPColor.stickerPink
    var rotation: Double = -3
    var body: some View {
        Text(text)
            .font(SPFont.scribble)
            .foregroundStyle(color)
            .shadow(color: .black.opacity(0.5), radius: 0, x: 1, y: 1)
            .rotationEffect(.degrees(rotation))
    }
}

// MARK: - SPSegments (settings segmented control)

struct SPSegments: View {
    let options: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { idx, opt in
                Button {
                    selectedIndex = idx
                } label: {
                    Text(opt.uppercased())
                        .font(SPFont.ui(10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(idx == selectedIndex ? SPColor.ledAmberHot : SPColor.textDim)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: idx == selectedIndex
                                ? [SPColor.roomBG, Color(hex: 0x14161A)]
                                : [Color(hex: 0x2F333A), Color(hex: 0x1F2127)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                }
                .buttonStyle(.plain)
                if idx < options.count - 1 {
                    Rectangle().fill(SPColor.ink).frame(width: 1)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(SPColor.ink, lineWidth: 1))
    }
}

// MARK: - SPSlider

struct SPSlider: View {
    @Binding var value: Double            // 0...1
    var formatted: String                 // e.g. "-6dB"

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(SPColor.roomBG)
                    .frame(height: 6)
                    .overlay(Capsule().stroke(.black, lineWidth: 1))

                Capsule()
                    .fill(LinearGradient(colors: [SPColor.ledAmber, SPColor.ledRed],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, geo.size.width * value), height: 6)
                    .shadow(color: SPColor.ledAmber.opacity(0.5), radius: 3)

                Circle()
                    .fill(RadialGradient(colors: [Color(hex: 0xFFD0A0), SPColor.ledAmber, Color(hex: 0x5A2A00)],
                                         center: .init(x: 0.35, y: 0.3),
                                         startRadius: 0, endRadius: 18))
                    .frame(width: 18, height: 18)
                    .offset(x: max(0, geo.size.width * value) - 9)
                    .shadow(color: SPColor.ledAmber.opacity(0.4), radius: 4)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { g in
                                value = min(1, max(0, g.location.x / geo.size.width))
                            }
                    )
            }
        }
        .frame(width: 200, height: 24)
        .overlay(alignment: .trailing) {
            Text(formatted)
                .font(SPFont.monoSmall)
                .foregroundStyle(SPColor.lcdFG)
                .shadow(color: SPColor.lcdFG.opacity(0.4), radius: 2)
                .offset(x: 44)
        }
    }
}

// MARK: - SPProgressBar

struct SPProgressBar: View {
    var progress: Double           // 0...1
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(SPColor.roomBG)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.black, lineWidth: 1))
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [SPColor.ledAmber, SPColor.ledRed],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * progress)
                    .shadow(color: SPColor.ledAmber.opacity(0.5), radius: 4)
            }
        }
        .frame(height: height)
    }
}

// MARK: - SPKnob (visual; bind to your VM if you want it turnable)

struct SPKnob: View {
    var rotation: Double          // degrees from -150 to 150 looks good
    var label: String
    var value: String

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .top) {
                Circle()
                    .fill(RadialGradient(colors: [SPColor.rubberHi, SPColor.rubber, Color(hex: 0x14161A)],
                                         center: .init(x: 0.4, y: 0.3),
                                         startRadius: 0, endRadius: 28))
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(SPColor.ink, lineWidth: 1))
                    .shadow(color: .black.opacity(0.6), radius: 3, y: 2)

                Capsule()
                    .fill(SPColor.ledAmber)
                    .frame(width: 2.5, height: 14)
                    .offset(y: 5)
                    .shadow(color: SPColor.ledAmber.opacity(0.7), radius: 3)
                    .rotationEffect(.degrees(rotation), anchor: .center)
                    .offset(y: 13)
            }

            Text(label.uppercased())
                .font(SPFont.monoMicro).tracking(1.5)
                .foregroundStyle(SPColor.textDim)
            Text(value)
                .font(SPFont.monoSmall)
                .foregroundStyle(SPColor.lcdFG)
                .shadow(color: SPColor.lcdFG.opacity(0.4), radius: 2)
        }
    }
}
