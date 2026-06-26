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

/// Mirrors the CSS custom properties from the web app's :root.
enum Theme {
    static let green      = Color(hex: "#4CAF50")
    static let greenDark  = Color(hex: "#388E3C")
    static let greenLight = Color(hex: "#E8F5E9")
    static let red        = Color(hex: "#E53935")
    static let redLight   = Color(hex: "#FFEBEE")
    static let bg         = Color(hex: "#F5F5F5")
    static let card       = Color.white
    static let text       = Color(hex: "#212121")
    static let muted      = Color(hex: "#757575")
    static let border     = Color(hex: "#E0E0E0")

    static let radius: CGFloat = 12
    static let shadow = Color.black.opacity(0.10)
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
