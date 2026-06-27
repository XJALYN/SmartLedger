import SwiftUI

/// Design tokens matching HTML mockups — mint green primary on light gray/white
extension Color {
    static let mintPrimary = Color(red: 0.29, green: 0.87, blue: 0.50)       // #4ADE80
    static let mintDark = Color(red: 0.13, green: 0.77, blue: 0.37)          // green-500
    static let appBackground = Color(red: 0.98, green: 0.98, blue: 0.98)   // gray-50
    static let cardBackground = Color.white
    static let textPrimary = Color(red: 0.07, green: 0.09, blue: 0.15)       // gray-900
    static let textSecondary = Color(red: 0.42, green: 0.45, blue: 0.50)     // gray-500
    static let textMuted = Color(red: 0.61, green: 0.64, blue: 0.69)         // gray-400
    static let borderLight = Color(red: 0.95, green: 0.96, blue: 0.96)       // gray-100
}

enum AppThemeColor: String, CaseIterable, Codable, Identifiable {
    case mint, sky, violet, rose, amber

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .mint: return Color(red: 0.29, green: 0.87, blue: 0.50)
        case .sky: return Color(red: 0.38, green: 0.71, blue: 0.94)
        case .violet: return Color(red: 0.65, green: 0.55, blue: 0.98)
        case .rose: return Color(red: 0.98, green: 0.45, blue: 0.57)
        case .amber: return Color(red: 0.98, green: 0.75, blue: 0.25)
        }
    }

    var localizedNameKey: String {
        "theme.\(rawValue)"
    }
}

struct ThemeColors {
    let primary: Color
    let primaryDark: Color
    let tintBackground: Color

    static func palette(for theme: AppThemeColor) -> ThemeColors {
        let base = theme.color
        return ThemeColors(
            primary: base,
            primaryDark: base.opacity(0.85),
            tintBackground: base.opacity(0.12)
        )
    }
}

struct RoundedCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.borderLight, lineWidth: 1)
            )
    }
}

extension View {
    func roundedCard() -> some View {
        modifier(RoundedCardStyle())
    }
}
