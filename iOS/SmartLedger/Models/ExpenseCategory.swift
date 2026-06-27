import Foundation
import SwiftUI

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case foodAndDrink
    case groceries
    case transport
    case home
    case entertainment
    case dining
    case shopping
    case utilities
    case personal
    case other

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .foodAndDrink: return "☕"
        case .groceries: return "🛒"
        case .transport: return "🚗"
        case .home: return "🏠"
        case .entertainment: return "🎬"
        case .dining: return "🍽️"
        case .shopping: return "🛍️"
        case .utilities: return "💡"
        case .personal: return "💇"
        case .other: return "📦"
        }
    }

    var localizationKey: String {
        "category.\(rawValue)"
    }

    var subtitleKey: String {
        "category.\(rawValue).subtitle"
    }

    var backgroundTint: Color {
        switch self {
        case .foodAndDrink: return Color(red: 1.0, green: 0.95, blue: 0.88)
        case .groceries: return Color(red: 1.0, green: 0.93, blue: 0.85)
        case .transport: return Color(red: 0.88, green: 0.94, blue: 1.0)
        case .home: return Color(red: 0.88, green: 0.98, blue: 0.91)
        case .entertainment: return Color(red: 0.95, green: 0.88, blue: 0.98)
        case .dining: return Color(red: 1.0, green: 0.90, blue: 0.90)
        case .shopping: return Color(red: 0.90, green: 0.90, blue: 0.98)
        case .utilities: return Color(red: 0.95, green: 0.98, blue: 0.88)
        case .personal: return Color(red: 1.0, green: 0.90, blue: 0.95)
        case .other: return Color(red: 0.94, green: 0.94, blue: 0.94)
        }
    }

    static func fromAIValue(_ value: String) -> ExpenseCategory {
        let normalized = value.lowercased()
        if normalized.contains("groc") || normalized.contains("超市") || normalized.contains("杂货") { return .groceries }
        if normalized.contains("transport") || normalized.contains("gas") || normalized.contains("交通") || normalized.contains("出行") { return .transport }
        if normalized.contains("home") || normalized.contains("util") || normalized.contains("水电") || normalized.contains("居家") { return .utilities }
        if normalized.contains("entertain") || normalized.contains("netflix") || normalized.contains("娱乐") { return .entertainment }
        if normalized.contains("shop") || normalized.contains("amazon") || normalized.contains("购物") { return .shopping }
        if normalized.contains("dining") || normalized.contains("restaurant") || normalized.contains("餐饮") || normalized.contains("午餐") || normalized.contains("晚餐") { return .dining }
        if normalized.contains("coffee") || normalized.contains("food") || normalized.contains("drink") || normalized.contains("咖啡") || normalized.contains("饮品") { return .foodAndDrink }
        if normalized.contains("personal") || normalized.contains("个人") { return .personal }
        return .other
    }
}

enum AppCurrency: String, CaseIterable, Codable, Identifiable {
    case cny, usd

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .cny: return "¥"
        case .usd: return "$"
        }
    }

    var code: String {
        rawValue.uppercased()
    }

    var localizationKey: String {
        "currency.\(rawValue)"
    }

    static func available(for language: AppLanguage) -> [AppCurrency] {
        switch language {
        case .chinese: return [.cny]
        default: return [.cny, .usd]
        }
    }

    static func normalized(_ stored: AppCurrency?, for language: AppLanguage) -> AppCurrency {
        let available = available(for: language)
        if let stored, available.contains(stored) { return stored }
        return .cny
    }
}
