import SwiftUI

/// A small, deliberate palette in the spirit of Portal's dark, immersive,
/// full-bleed nature photography look — deep near-black surfaces, soft
/// off-white text, and one calm accent used sparingly (selection, the play
/// button) rather than scattered everywhere.
enum Theme {
    static let background = Color(red: 0.043, green: 0.055, blue: 0.063)   // #0B0E10
    static let surface = Color(red: 0.086, green: 0.102, blue: 0.114)      // #161A1D
    static let accent = Color(red: 0.42, green: 0.78, blue: 0.65)          // muted nature teal
    static let textPrimary = Color.white.opacity(0.94)
    static let textSecondary = Color.white.opacity(0.55)
    static let hairline = Color.white.opacity(0.08)
}
