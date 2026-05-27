import SwiftUI

extension Color {
    /// Initialize from a 6-digit hex string (with or without leading `#`).
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xff) / 255,
            green: Double((rgb >> 8) & 0xff) / 255,
            blue: Double(rgb & 0xff) / 255
        )
    }
}

extension DrumrotTier {
    /// SwiftUI color from the web `TIER_CONFIG` hex.
    var color: Color { Color(hex: hexColor) }
}

extension PracticeTier {
    var color: Color { Color(hex: hexColor) }
}
