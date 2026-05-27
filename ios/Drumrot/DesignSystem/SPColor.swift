import SwiftUI

/// SP-808 hardware palette, mirrored from `css/main.css` `:root` variables.
enum SPColor {
    // Chassis / metal / plastic
    static let bgRoom    = Color(hex: "#1a1c20")
    static let chassis   = Color(hex: "#272a30")
    static let chassis2  = Color(hex: "#1e2126")
    static let metal     = Color(hex: "#3a3f47")
    static let metalDark = Color(hex: "#191c20")
    static let plastic   = Color(hex: "#0e1014")
    static let rubber    = Color(hex: "#2a2d33")
    static let rubberHi  = Color(hex: "#4a4e57")
    static let screw     = Color(hex: "#5a5f68")
    static let ink       = Color(hex: "#0a0c10")

    // LCD screen
    static let lcdBg   = Color(hex: "#0a1410")
    static let lcdBg2  = Color(hex: "#13241c")
    static let lcdFg   = Color(hex: "#7df0a8")
    static let lcdDim  = Color(hex: "#2a4a37")

    // LEDs
    static let ledAmber    = Color(hex: "#ff8a1e")
    static let ledAmberHot = Color(hex: "#ffb04a")
    static let ledRed      = Color(hex: "#ff3a5a")
    static let ledGreen    = Color(hex: "#5cf07d")

    // Stickers / accents
    static let stickerPink   = Color(hex: "#ff2a7a")
    static let stickerYellow = Color(hex: "#ffd400")
    static let stickerCyan   = Color(hex: "#10c4d6")

    // Text
    static let text    = Color(hex: "#dde2ea")
    static let textDim = Color(hex: "#7a818c")

    /// Lane accent colors (crash, hihat, snare, kick, tom, ride).
    static func lane(_ index: Int) -> Color {
        switch index {
        case 0: return stickerPink
        case 1: return ledGreen
        case 2: return text
        case 3: return ledRed
        case 4: return ledAmber
        default: return stickerCyan
        }
    }

    // Back-compat aliases used elsewhere.
    static let background  = bgRoom
    static let panel       = chassis
    static let accentGreen = ledGreen
    static let accentOrange = ledAmber
    static let accentRed   = ledRed
    static let accentPink  = stickerPink
}
