import Foundation

enum MoneyFormatter {
    static func string(_ amount: Decimal, currency: AppCurrency) -> String {
        let number = NSDecimalNumber(decimal: amount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: number) ?? "\(currency.symbol)\(number)"
    }

    static func compact(_ amount: Decimal, currency: AppCurrency) -> String {
        let number = NSDecimalNumber(decimal: amount)
        if number.doubleValue >= 1000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return "\(currency.symbol)\(formatter.string(from: number) ?? number.stringValue)"
        }
        return string(amount, currency: currency)
    }
}

enum GreetingProvider {
    static func current() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return String(localized: "greeting.morning")
        case 12..<17: return String(localized: "greeting.afternoon")
        case 17..<22: return String(localized: "greeting.evening")
        default: return String(localized: "greeting.night")
        }
    }
}
