import Foundation

struct CategoryBreakdown: Identifiable, Equatable {
    let category: ExpenseCategory
    let amount: Decimal
    let percentage: Double

    var id: String { category.rawValue }
}

struct DailySpending: Identifiable, Equatable {
    let label: String
    let amount: Decimal
    let normalizedHeight: Double

    var id: String { label }
}

struct SpendingSummary: Equatable {
    let total: Decimal
    let previousTotal: Decimal
    let topCategory: ExpenseCategory?
    let topCategoryAmount: Decimal
    let transactionCount: Int
    let percentChange: Double?
}

struct AnalyticsService {
    func summary(for expenses: [Expense], previous: [Expense]) -> SpendingSummary {
        let total = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        let previousTotal = previous.reduce(Decimal.zero) { $0 + $1.amount }
        let grouped = Dictionary(grouping: expenses, by: \.category)
        let top = grouped.max { lhs, rhs in
            lhs.value.reduce(Decimal.zero) { $0 + $1.amount } < rhs.value.reduce(Decimal.zero) { $0 + $1.amount }
        }
        let topAmount = top?.value.reduce(Decimal.zero) { $0 + $1.amount } ?? 0
        let change: Double?
        if previousTotal > 0 {
            let current = NSDecimalNumber(decimal: total).doubleValue
            let prev = NSDecimalNumber(decimal: previousTotal).doubleValue
            change = ((current - prev) / prev) * 100
        } else {
            change = nil
        }
        return SpendingSummary(
            total: total,
            previousTotal: previousTotal,
            topCategory: top?.key,
            topCategoryAmount: topAmount,
            transactionCount: expenses.count,
            percentChange: change
        )
    }

    func categoryBreakdown(for expenses: [Expense]) -> [CategoryBreakdown] {
        let total = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        guard total > 0 else { return [] }
        let grouped = Dictionary(grouping: expenses, by: \.category)
        return grouped.map { category, items in
            let amount = items.reduce(Decimal.zero) { $0 + $1.amount }
            let pct = (NSDecimalNumber(decimal: amount).doubleValue / NSDecimalNumber(decimal: total).doubleValue) * 100
            return CategoryBreakdown(category: category, amount: amount, percentage: pct)
        }
        .sorted { $0.amount > $1.amount }
    }

    func dailySpending(for expenses: [Expense], days: Int = 7, reference: Date = Date()) -> [DailySpending] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = days > 14 ? "M/d" : "EEE"
        formatter.locale = Locale.current

        let buckets = (0..<days).reversed().map { offset -> (String, Decimal) in
            let day = calendar.date(byAdding: .day, value: -offset, to: reference) ?? reference
            let start = calendar.startOfDay(for: day)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? day
            let amount = expenses.filter { $0.date >= start && $0.date < end }
                .reduce(Decimal.zero) { $0 + $1.amount }
            return (formatter.string(from: day), amount)
        }

        return chartPoints(from: buckets)
    }

    func monthlySpending(for expenses: [Expense], months: Int = 12, reference: Date = Date()) -> [DailySpending] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        formatter.locale = Locale.current

        let buckets = (0..<months).reversed().map { offset -> (String, Decimal) in
            let monthDate = calendar.date(byAdding: .month, value: -offset, to: reference) ?? reference
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) ?? monthDate
            let end = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: start) ?? monthDate
            let amount = expenses.filter { $0.date >= start && $0.date <= end }
                .reduce(Decimal.zero) { $0 + $1.amount }
            return (formatter.string(from: monthDate), amount)
        }

        return chartPoints(from: buckets)
    }

    func yearlySpending(for expenses: [Expense], years: Int = 10, reference: Date = Date()) -> [DailySpending] {
        let calendar = Calendar.current

        let buckets = (0..<years).reversed().map { offset -> (String, Decimal) in
            let year = calendar.component(.year, from: reference) - offset
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1
            let start = calendar.date(from: startComponents) ?? reference

            var endComponents = DateComponents()
            endComponents.year = year
            endComponents.month = 12
            endComponents.day = 31
            endComponents.hour = 23
            endComponents.minute = 59
            endComponents.second = 59
            let end = calendar.date(from: endComponents) ?? reference

            let amount = expenses.filter { $0.date >= start && $0.date <= end }
                .reduce(Decimal.zero) { $0 + $1.amount }
            return (String(year), amount)
        }

        return chartPoints(from: buckets)
    }

    private func chartPoints(from buckets: [(label: String, amount: Decimal)]) -> [DailySpending] {
        let maxValue = buckets.map { NSDecimalNumber(decimal: $0.amount).doubleValue }.max() ?? 1
        return buckets.map { label, amount in
            let height = maxValue > 0 ? NSDecimalNumber(decimal: amount).doubleValue / maxValue : 0
            return DailySpending(label: label, amount: amount, normalizedHeight: height)
        }
    }

    func budgetProgress(total: Decimal, budget: Decimal) -> Double {
        guard budget > 0 else { return 0 }
        return min(1, NSDecimalNumber(decimal: total / budget).doubleValue)
    }
}
