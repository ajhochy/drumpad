import SwiftUI

/// Typography. Two layers:
///  1. Existing `mono`/`display` (system monospaced/rounded) — kept as-is so the
///     already-verified Play tab + cards don't change.
///  2. Bundled-font API (Bungee / Major Mono Display / IBM Plex Mono / Special
///     Elite / Permanent Marker) for the new chassis design language + re-skins.
///     Space Grotesk / Inter are variable fonts (not bundled) → system fallback.
enum SPFont {

    // MARK: existing system API (unchanged)
    static func mono(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .monospaced).weight(weight)
    }
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    // MARK: bundled PostScript names (verified against the .ttf name tables)
    private static let bungee  = "Bungee-Regular"
    private static let majMono = "MajorMonoDisplay-Regular"
    private static let plexR   = "IBMPlexMono-Regular"
    private static let plexM   = "IBMPlexMono-Medium"
    private static let elite   = "SpecialElite-Regular"
    private static let marker  = "PermanentMarker-Regular"

    // ---- Display / Bungee ----
    /// Big titles / screen headings (CGFloat overload — distinct from display(_:weight:)).
    static func display(_ size: CGFloat = 32, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom(bungee, size: size, relativeTo: style)
    }
    /// Judge text on the highway ("PERFECT!" / "MISS").
    static let judge = Font.custom(bungee, size: 38, relativeTo: .largeTitle)

    // ---- LCD / Major Mono ----
    static func lcd(_ size: CGFloat = 14, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(majMono, size: size, relativeTo: style)
    }
    static let monoMicro = Font.custom(majMono, size: 9, relativeTo: .caption2)
    static let monoSmall = Font.custom(majMono, size: 11, relativeTo: .caption)

    // ---- UI / Space Grotesk (variable → system rounded fallback) ----
    enum Weight { case regular, medium, bold }
    static func ui(_ size: CGFloat = 12, weight: Weight = .bold,
                   relativeTo style: Font.TextStyle = .body) -> Font {
        let w: Font.Weight = weight == .bold ? .bold : (weight == .medium ? .medium : .regular)
        return .system(size: size, weight: w, design: .rounded)
    }

    // ---- Body / Inter (variable → system fallback) ----
    static func body(_ size: CGFloat = 14, weight: Font.Weight = .regular,
                     relativeTo style: Font.TextStyle = .body) -> Font {
        .system(size: size, weight: weight)
    }

    // ---- Secondary mono / IBM Plex Mono ----
    static func plex(_ size: CGFloat = 11, medium: Bool = false,
                     relativeTo style: Font.TextStyle = .caption) -> Font {
        .custom(medium ? plexM : plexR, size: size, relativeTo: style)
    }

    // ---- Sticker fonts ----
    static let dymo     = Font.custom(elite,  size: 11, relativeTo: .caption)
    static let scribble = Font.custom(marker, size: 14, relativeTo: .callout)
}
