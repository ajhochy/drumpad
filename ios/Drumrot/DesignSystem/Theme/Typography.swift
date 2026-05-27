import SwiftUI

/// Typography helpers. Uses system monospaced/rounded as stand-ins until the
/// bundled IBM Plex Mono / Space Grotesk faces are wired in (Phase 9 polish).
enum SPFont {
    static func mono(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .monospaced).weight(weight)
    }

    static func display(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}
