import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

/// Dark theme: black / dark-grey surfaces, white text, light-green accents.
enum Theme {
    static let green      = Color(hex: "#4CAF50")   // primary accent
    static let greenDark  = Color(hex: "#66BB6A")   // brighter green for text/accents on dark
    static let greenLight = Color(hex: "#1C3A28")   // subtle green tint for button/badge fills
    static let red        = Color(hex: "#FF5252")
    static let redLight   = Color(hex: "#3A1E1E")
    static let bg         = Color(hex: "#000000")   // app background (black)
    static let card       = Color(hex: "#1C1C1E")   // cards / surfaces (dark grey)
    static let inset      = Color(hex: "#2C2C2E")   // insets on top of cards (fields, icon buttons)
    static let text       = Color(hex: "#FFFFFF")   // primary text (white)
    static let muted      = Color(hex: "#A0A0A5")   // secondary text (light grey)
    static let border     = Color(hex: "#3A3A3C")

    static let radius: CGFloat = 12
    static let shadow = Color.black.opacity(0.5)
}

/// Reusable card container matching the web `.stat-card` / section look.
struct CardBackground: ViewModifier {
    var padding: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .shadow(color: Theme.shadow, radius: 6, x: 0, y: 2)
    }
}

extension View {
    func card(padding: CGFloat = 20) -> some View { modifier(CardBackground(padding: padding)) }
}
