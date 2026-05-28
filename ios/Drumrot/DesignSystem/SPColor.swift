import SwiftUI

/// SP-808 hardware palette, mirrored from `css/main.css` `:root` variables.
/// Canonical token names follow Claude Design's bundle; back-compat aliases at
/// the bottom keep the existing Play/cards/Chassis call sites compiling.
enum SPColor {

    // ---- Chassis ----
    static let chassis   = Color(hex: 0x272A30)
    static let chassis2  = Color(hex: 0x1E2126)
    static let roomBG    = Color(hex: 0x1A1C20)
    static let metal     = Color(hex: 0x3A3F47)
    static let metalDark = Color(hex: 0x191C20)
    static let plastic   = Color(hex: 0x0E1014)
    static let rubber    = Color(hex: 0x2A2D33)
    static let rubberHi  = Color(hex: 0x4A4E57)
    static let screw     = Color(hex: 0x5A5F68)
    static let ink       = Color(hex: 0x0A0C10)

    // ---- LCD ----
    static let lcdBG  = Color(hex: 0x0A1410)
    static let lcdBG2 = Color(hex: 0x13241C)
    static let lcdFG  = Color(hex: 0x7DF0A8)
    static let lcdDim = Color(hex: 0x2A4A37)

    // ---- LEDs ----
    static let ledAmber    = Color(hex: 0xFF8A1E)
    static let ledAmberHot = Color(hex: 0xFFB04A)
    static let ledRed      = Color(hex: 0xFF3A5A)
    static let ledGreen    = Color(hex: 0x5CF07D)

    // ---- Stickers / accents ----
    static let stickerPink   = Color(hex: 0xFF2A7A)
    static let stickerYellow = Color(hex: 0xFFD400)
    static let stickerCyan   = Color(hex: 0x10C4D6)
    static let stickerRed    = Color(hex: 0xE23226)
    static let dymo          = Color(hex: 0xCDD3DA)
    static let dymoRed       = Color(hex: 0xC2362E)

    // ---- Text ----
    static let text    = Color(hex: 0xDDE2EA)
    static let textDim = Color(hex: 0x7A818C)

    // ---- Lane accents — order: CRSH HHAT SNRE KICK TOMS RIDE ----
    static let laneColors: [Color] = [
        .init(hex: 0xFF2A7A),   // CRSH pink
        .init(hex: 0x5CF07D),   // HHAT green
        .init(hex: 0xDDE2EA),   // SNRE white
        .init(hex: 0xFF3A5A),   // KICK red
        .init(hex: 0xFF8A1E),   // TOMS amber
        .init(hex: 0x10C4D6),   // RIDE cyan
    ]
    static let laneNames = ["CRSH", "HHAT", "SNRE", "KICK", "TOMS", "RIDE"]

    // ---- Back-compat aliases (existing Play/cards/Chassis/LED call sites) ----
    static let background  = roomBG
    static let bgRoom      = roomBG
    static let panel       = chassis
    static let lcdBg       = lcdBG
    static let lcdBg2      = lcdBG2
    static let lcdFg       = lcdFG
    static let accentGreen = ledGreen
    static let accentOrange = ledAmber
    static let accentRed   = ledRed
    static let accentPink  = stickerPink

    static func lane(_ i: Int) -> Color { laneColors[((i % laneColors.count) + laneColors.count) % laneColors.count] }
}

// 24-bit hex initializer (the String-hex initializer lives in ColorHex.swift).
extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >>  8) & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: 1
        )
    }
}
