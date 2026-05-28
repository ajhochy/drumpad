// ============================================================
// Chassis.swift
// drumrot · SP-808 KILLA — iPad
//
// Extends your existing Chassis helpers with the full kit needed
// by the redesigned surfaces. Drop these in alongside the
// Scanlines / Screw / .lcdPanel() / .chassisModule() you already
// have — names are namespaced to avoid clashing.
// ============================================================

import SwiftUI

// MARK: - Primitives

/// A single recessed Phillips-head screw.
struct SPScrew: View {
    var size: CGFloat = 14
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(hex: 0x828791), Color(hex: 0x5A5F68), Color(hex: 0x2A2D33)],
                    center: .init(x: 0.35, y: 0.30),
                    startRadius: 0, endRadius: size
                )
            )
            .frame(width: size, height: size)
            .overlay(
                // slot
                Rectangle()
                    .fill(SPColor.ink)
                    .frame(width: size * 0.65, height: 1.5)
                    .rotationEffect(.degrees(45))
                    .opacity(0.7)
            )
            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.6), radius: 0.5, x: 0, y: 1)
    }
}

/// LED dot — colored core, glow ring.
struct SPLED: View {
    enum Tone { case amber, amberHot, green, red, off }
    var tone: Tone = .green
    var size: CGFloat = 8

    private var color: Color {
        switch tone {
        case .amber:    return SPColor.ledAmber
        case .amberHot: return SPColor.ledAmberHot
        case .green:    return SPColor.ledGreen
        case .red:      return SPColor.ledRed
        case .off:      return SPColor.roomBG
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: tone == .off ? .clear : color.opacity(0.9), radius: size * 0.6)
            .overlay(
                Circle().stroke(SPColor.ink, lineWidth: tone == .off ? 1 : 0)
            )
    }
}

/// Diagonal scanline overlay for any LCD-style surface.
struct SPScanlines: View {
    var opacity: Double = 0.5
    var body: some View {
        GeometryReader { _ in
            Canvas { ctx, size in
                var y: CGFloat = 0
                while y < size.height {
                    ctx.fill(
                        Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                        with: .color(.black.opacity(0.2))
                    )
                    y += 3
                }
            }
            .opacity(opacity)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Surfaces (ViewModifiers)

extension View {

    /// Brushed-metal chassis face — the main play surface backdrop.
    func chassisFace(cornerRadius: CGFloat = 14) -> some View {
        self.background(
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x2C2F36), Color(hex: 0x232730), Color(hex: 0x1A1D23)],
                    startPoint: .top, endPoint: .bottom
                )
                // brushed verticals
                Canvas { ctx, size in
                    var x: CGFloat = 0
                    while x < size.width {
                        ctx.fill(
                            Path(CGRect(x: x, y: 0, width: 1, height: size.height)),
                            with: .color(.white.opacity(0.012))
                        )
                        x += 3
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(SPColor.ink, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
                .padding(0.5)
                .blendMode(.plusLighter)
        )
        .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 10)
    }

    /// A "module" — small chassis panel for rail cards.
    func chassisModule(padding: CGFloat = 14) -> some View {
        self
            .padding(padding)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x2C2F36), Color(hex: 0x1E2126)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(SPColor.ink, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }

    /// LCD panel modifier — dark green CRT with inner shadow + scanlines.
    func lcdPanel(cornerRadius: CGFloat = 6) -> some View {
        self
            .background(
                LinearGradient(
                    colors: [SPColor.lcdBG, Color(hex: 0x0D1A14)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(SPScanlines())
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(SPColor.ink, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 2)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(SPColor.lcdFG.opacity(0.06), lineWidth: 1.5)
                    .padding(1)
            )
    }
}

// MARK: - Module title (e.g. "Pattern" / "Coach Note")

struct SPModuleTitle: View {
    let title: String
    var meta: String? = nil
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(SPColor.ledAmber)
                .frame(width: 14, height: 1)
            Text(title.uppercased())
                .font(SPFont.ui(11, weight: .bold))
                .tracking(2)
                .foregroundStyle(SPColor.textDim)
            Spacer(minLength: 0)
            if let m = meta {
                Text(m.uppercased())
                    .font(SPFont.monoMicro)
                    .tracking(1.5)
                    .foregroundStyle(SPColor.ledAmberHot)
            }
        }
        .padding(.bottom, 8)
    }
}
