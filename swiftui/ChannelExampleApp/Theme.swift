import SwiftUI

// MARK: - Color hex extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Colors (matches RN theme.ts)

enum Colors {
    static let background = Color.white
    static let surface = Color(hex: "#f8f9fa")
    static let dark = Color(hex: "#32373c")
    static let accent = Color(hex: "#0693e3")
    static let accentSecondary = Color(hex: "#9b51e0")
    static let text = Color(hex: "#1a1a1a")
    static let textMuted = Color(hex: "#666666")
    static let textLight = Color.white
    static let border = Color(hex: "#e0e0e0")
    static let error = Color(hex: "#e74c3c")
    static let success = Color(hex: "#27ae60")
}

// MARK: - Publication colors

let PUBLICATION_COLORS: [String: Color] = [
    "demo": Color(hex: "#00b894"),
]

private let AD_HOC_COLORS: [Color] = [
    Color(hex: "#74b9ff"),
    Color(hex: "#a29bfe"),
    Color(hex: "#55efc4"),
    Color(hex: "#fab1a0"),
    Color(hex: "#dfe6e9"),
]

@MainActor
final class PublicationColorStore {
    static let shared = PublicationColorStore()
    private var colors: [String: Color] = PUBLICATION_COLORS
    private var adHocIdx = 0

    private init() {}

    func color(for key: String) -> Color {
        colors[key] ?? Colors.accent
    }

    func set(_ color: Color, for key: String) {
        colors[key] = color
    }

    func nextAdHocColor() -> Color {
        let color = AD_HOC_COLORS[adHocIdx % AD_HOC_COLORS.count]
        adHocIdx += 1
        return color
    }
}

@MainActor
func publicationColor(for key: String) -> Color {
    PublicationColorStore.shared.color(for: key)
}

// MARK: - Spacing (matches RN theme.ts)

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Font sizes (matches RN theme.ts)

enum FontSize {
    static let xs: CGFloat = 10
    static let sm: CGFloat = 12
    static let md: CGFloat = 14
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let title: CGFloat = 36
}

// MARK: - Radius (matches RN theme.ts)

enum Radius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let pill: CGFloat = 9999
}
