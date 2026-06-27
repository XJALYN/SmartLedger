import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case system
    case english
    case chinese

    var id: String { rawValue }

    var localeIdentifier: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .chinese: return "zh-Hans"
        }
    }

    var locale: Locale {
        if let id = localeIdentifier {
            return Locale(identifier: id)
        }
        return resolvedSystemLocale()
    }

    var localizationKey: String {
        "language.\(rawValue)"
    }

    var isChinese: Bool {
        switch self {
        case .chinese: return true
        case .system: return Self.resolveFromSystem() == .chinese
        case .english: return false
        }
    }

    static func resolveFromSystem() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh") { return .chinese }
        return .english
    }

    private func resolvedSystemLocale() -> Locale {
        Self.resolveFromSystem().locale
    }
}

struct CreditRechargeOption: Identifiable {
    let productID: String
    let credits: Int
    let fallbackPriceKey: String
    let accessibilityID: String

    var id: String { productID }

    static let all: [CreditRechargeOption] = [
        CreditRechargeOption(
            productID: "com.smartledger.app.credits.100",
            credits: 100,
            fallbackPriceKey: "settings.credits.pack.small",
            accessibilityID: "credits_100"
        ),
        CreditRechargeOption(
            productID: "com.smartledger.app.credits.500",
            credits: 500,
            fallbackPriceKey: "settings.credits.pack.large",
            accessibilityID: "credits_500"
        )
    ]

    static func credits(for productID: String) -> Int? {
        all.first { $0.productID == productID }?.credits
    }
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let language = "sl.language"
        static let theme = "sl.theme"
        static let currency = "sl.currency"
        static let notificationsEnabled = "sl.notifications"
        static let monthlyBudget = "sl.monthlyBudget"
        static let credits = "sl.credits"
        static let creditLimit = "sl.creditLimit"
        static let apiKey = "sl.dashscopeApiKey"
        static let userName = "sl.userName"
        static let userEmail = "sl.userEmail"
        static let firstLaunchDate = "sl.firstLaunchDate"
        static let hasRated = "sl.hasRated"
        static let ratingPromptShown = "sl.ratingPromptShown"
        static let faceIDEnabled = "sl.faceIDEnabled"
        static let fulfilledTransactions = "sl.fulfilledTransactions"
    }

    @Published var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Key.language)
            clampCurrencyForLanguage()
        }
    }

    @Published var theme: AppThemeColor {
        didSet { defaults.set(theme.rawValue, forKey: Key.theme) }
    }

    @Published var currency: AppCurrency {
        didSet { defaults.set(currency.rawValue, forKey: Key.currency) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Key.notificationsEnabled) }
    }

    @Published var monthlyBudget: Decimal {
        didSet { defaults.set(NSDecimalNumber(decimal: monthlyBudget).doubleValue, forKey: Key.monthlyBudget) }
    }

    @Published var credits: Int {
        didSet { defaults.set(credits, forKey: Key.credits) }
    }

    @Published var creditLimit: Int {
        didSet { defaults.set(creditLimit, forKey: Key.creditLimit) }
    }

    @Published var dashscopeAPIKey: String {
        didSet { defaults.set(dashscopeAPIKey, forKey: Key.apiKey) }
    }

    @Published var userName: String {
        didSet { defaults.set(userName, forKey: Key.userName) }
    }

    @Published var userEmail: String {
        didSet { defaults.set(userEmail, forKey: Key.userEmail) }
    }

    @Published var hasRated: Bool {
        didSet { defaults.set(hasRated, forKey: Key.hasRated) }
    }

    @Published var ratingPromptShown: Bool {
        didSet { defaults.set(ratingPromptShown, forKey: Key.ratingPromptShown) }
    }

    @Published var faceIDEnabled: Bool {
        didSet { defaults.set(faceIDEnabled, forKey: Key.faceIDEnabled) }
    }

    var firstLaunchDate: Date? {
        defaults.object(forKey: Key.firstLaunchDate) as? Date
    }

    var effectiveLanguage: AppLanguage {
        language == .system ? AppLanguage.resolveFromSystem() : language
    }

    var activeLocale: Locale {
        effectiveLanguage.locale
    }

    var themeColors: ThemeColors {
        ThemeColors.palette(for: theme)
    }

    var availableCurrencies: [AppCurrency] {
        AppCurrency.available(for: effectiveLanguage)
    }

    private init() {
        let loadedLanguage = AppLanguage(rawValue: defaults.string(forKey: Key.language) ?? AppLanguage.system.rawValue) ?? .system
        language = loadedLanguage
        theme = AppThemeColor(rawValue: defaults.string(forKey: Key.theme) ?? AppThemeColor.mint.rawValue) ?? .mint
        let effectiveLang = loadedLanguage == .system ? AppLanguage.resolveFromSystem() : loadedLanguage
        let storedCurrency = AppCurrency(rawValue: defaults.string(forKey: Key.currency) ?? AppCurrency.cny.rawValue)
        currency = AppCurrency.normalized(storedCurrency, for: effectiveLang)
        notificationsEnabled = defaults.object(forKey: Key.notificationsEnabled) as? Bool ?? true
        monthlyBudget = Decimal(defaults.object(forKey: Key.monthlyBudget) as? Double ?? 2000)
        credits = defaults.object(forKey: Key.credits) as? Int ?? 240
        creditLimit = defaults.object(forKey: Key.creditLimit) as? Int ?? 500
        let storedAPIKey = defaults.string(forKey: Key.apiKey) ?? ""
        dashscopeAPIKey = storedAPIKey.isEmpty ? (SecretsLoader.dashscopeAPIKeyFromBundle() ?? "") : storedAPIKey
        userName = defaults.string(forKey: Key.userName) ?? "Alex Morgan"
        userEmail = defaults.string(forKey: Key.userEmail) ?? "alex.morgan@smartledger.app"
        hasRated = defaults.bool(forKey: Key.hasRated)
        ratingPromptShown = defaults.bool(forKey: Key.ratingPromptShown)
        faceIDEnabled = defaults.bool(forKey: Key.faceIDEnabled)
    }

    func recordLaunchIfNeeded() {
        if firstLaunchDate == nil {
            defaults.set(Date(), forKey: Key.firstLaunchDate)
        }
    }

    func shouldShowRatingPrompt() -> Bool {
        guard let firstLaunch = firstLaunchDate else { return false }
        guard !ratingPromptShown, !hasRated else { return false }
        return Date().timeIntervalSince(firstLaunch) >= 24 * 60 * 60
    }

    func daysSinceFirstLaunch() -> Int {
        guard let firstLaunch = firstLaunchDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
    }

    func markRatingPromptShown() { ratingPromptShown = true }
    func markRated() { hasRated = true; ratingPromptShown = true }
    func declineRating() { ratingPromptShown = true }

    func scheduleRatingReminder() {
        ratingPromptShown = false
        defaults.set(Date(), forKey: Key.firstLaunchDate)
    }

    func consumeCredits(_ amount: Int) -> Bool {
        guard credits >= amount else { return false }
        credits -= amount
        return true
    }

    func rechargeCredits(_ amount: Int = 100) {
        credits = min(creditLimit, credits + amount)
    }

    func hasFulfilledTransaction(_ transactionID: String) -> Bool {
        fulfilledTransactionIDs.contains(transactionID)
    }

    func markTransactionFulfilled(_ transactionID: String) {
        fulfilledTransactionIDs.insert(transactionID)
    }

    private var fulfilledTransactionIDs: Set<String> {
        get {
            Set(defaults.stringArray(forKey: Key.fulfilledTransactions) ?? [])
        }
        set {
            defaults.set(Array(newValue), forKey: Key.fulfilledTransactions)
        }
    }

    private func clampCurrencyForLanguage() {
        currency = AppCurrency.normalized(currency, for: effectiveLanguage)
    }

    func resetForTesting() {
        [Key.language, Key.theme, Key.currency, Key.notificationsEnabled, Key.monthlyBudget,
         Key.credits, Key.creditLimit, Key.apiKey, Key.userName, Key.userEmail,
         Key.firstLaunchDate, Key.hasRated, Key.ratingPromptShown, Key.faceIDEnabled,
         Key.fulfilledTransactions].forEach {
            defaults.removeObject(forKey: $0)
        }
        language = .system
        theme = .mint
        currency = .cny
        notificationsEnabled = true
        monthlyBudget = 2000
        credits = 240
        creditLimit = 500
        dashscopeAPIKey = ""
        userName = "Alex Morgan"
        userEmail = "alex.morgan@smartledger.app"
        hasRated = false
        ratingPromptShown = false
        faceIDEnabled = false
    }

    func setFirstLaunchDate(daysAgo: Int) {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        defaults.set(date, forKey: Key.firstLaunchDate)
    }
}
