import Foundation

@MainActor
final class ExpenseStore: ObservableObject {
    static let shared = ExpenseStore()

    @Published private(set) var expenses: [Expense] = []

    private let storageKey = "sl.expenses"

    private init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Expense].self, from: data) else {
            expenses = []
            return
        }
        expenses = decoded.sorted { $0.date > $1.date }
    }

    func save() {
        if let data = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func add(_ expense: Expense) {
        expenses.insert(expense, at: 0)
        save()
    }

    func update(_ expense: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[index] = expense
        save()
    }

    func delete(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        save()
    }

    func delete(at offsets: IndexSet, in grouped: [Expense]) {
        let ids = offsets.map { grouped[$0].id }
        expenses.removeAll { ids.contains($0.id) }
        save()
    }

    func expenses(matching query: String, category: ExpenseCategory?) -> [Expense] {
        expenses.filter { expense in
            let categoryMatch = category == nil || expense.category == category
            let queryMatch = query.isEmpty || expense.searchableText.contains(query.lowercased())
            return categoryMatch && queryMatch
        }
    }

    func expenses(in range: StatsTimeRange, reference: Date = Date()) -> [Expense] {
        expenses(filter: StatsDateFilter(mode: range), reference: reference)
    }

    func expenses(filter: StatsDateFilter, reference: Date = Date()) -> [Expense] {
        guard let interval = dateInterval(for: filter, reference: reference) else { return expenses }
        return expenses.filter { $0.date >= interval.start && $0.date <= interval.end }
    }

    func expenses(lastMonths count: Int, reference: Date = Date()) -> [Expense] {
        guard count > 0 else { return [] }
        let calendar = Calendar.current
        guard let anchorMonth = calendar.date(byAdding: .month, value: -(count - 1), to: reference),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: anchorMonth)) else {
            return []
        }
        return expenses.filter { $0.date >= start && $0.date <= reference }
    }

    func expenses(lastYears count: Int, reference: Date = Date()) -> [Expense] {
        guard count > 0 else { return [] }
        let calendar = Calendar.current
        let endYear = calendar.component(.year, from: reference)
        let startYear = endYear - (count - 1)
        var components = DateComponents()
        components.year = startYear
        components.month = 1
        components.day = 1
        guard let start = calendar.date(from: components) else { return [] }
        return expenses.filter { $0.date >= start && $0.date <= reference }
    }

    func availableYears() -> [Int] {
        let years = Set(expenses.map { Calendar.current.component(.year, from: $0.date) })
        let currentYear = Calendar.current.component(.year, from: Date())
        var result = years
        result.insert(currentYear)
        return result.sorted(by: >)
    }

    private func dateInterval(for filter: StatsDateFilter, reference: Date) -> DateInterval? {
        let calendar = Calendar.current
        switch filter.mode {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: reference)) ?? reference
            return DateInterval(start: start, end: reference)
        case .month:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: reference)) ?? reference
            return DateInterval(start: start, end: reference)
        case .year:
            var components = DateComponents()
            components.year = filter.selectedYear
            let start = calendar.date(from: components) ?? reference
            let endComponents = DateComponents(year: filter.selectedYear, month: 12, day: 31, hour: 23, minute: 59, second: 59)
            let end = calendar.date(from: endComponents) ?? reference
            let currentYear = calendar.component(.year, from: reference)
            if filter.selectedYear == currentYear {
                return DateInterval(start: start, end: reference)
            }
            return DateInterval(start: start, end: end)
        case .custom:
            let start = calendar.startOfDay(for: filter.customStart)
            let endDay = calendar.startOfDay(for: filter.customEnd)
            let end = calendar.date(byAdding: .day, value: 1, to: endDay)?.addingTimeInterval(-1) ?? filter.customEnd
            return DateInterval(start: min(start, end), end: max(start, end))
        }
    }

    func previousExpenses(for filter: StatsDateFilter, reference: Date = Date()) -> [Expense] {
        let calendar = Calendar.current
        switch filter.mode {
        case .week:
            let ref = calendar.date(byAdding: .day, value: -7, to: reference) ?? reference
            return expenses(filter: StatsDateFilter(mode: .week), reference: ref)
        case .month:
            let ref = calendar.date(byAdding: .month, value: -1, to: reference) ?? reference
            return expenses(filter: StatsDateFilter(mode: .month), reference: ref)
        case .year:
            var previous = filter
            previous.selectedYear -= 1
            return expenses(filter: previous, reference: reference)
        case .custom:
            guard let interval = dateInterval(for: filter, reference: reference) else { return [] }
            let duration = interval.duration
            let previousEnd = interval.start.addingTimeInterval(-1)
            let previousStart = previousEnd.addingTimeInterval(-duration)
            return expenses.filter { $0.date >= previousStart && $0.date <= previousEnd }
        }
    }

    func groupedByDay(_ items: [Expense]) -> [(String, [Expense])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current

        let calendar = Calendar.current
        var groups: [String: [Expense]] = [:]
        var order: [String] = []

        for expense in items.sorted(by: { $0.date > $1.date }) {
            let key: String
            if calendar.isDateInToday(expense.date) {
                key = String(localized: "ledger.today")
            } else if calendar.isDateInYesterday(expense.date) {
                key = String(localized: "ledger.yesterday")
            } else {
                key = formatter.string(from: expense.date)
            }
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(expense)
        }
        return order.compactMap { key in
            guard let values = groups[key] else { return nil }
            return (key, values)
        }
    }

    func resetForTesting() {
        expenses = []
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    func seedSampleDataIfEmpty() {
        guard expenses.isEmpty else { return }
        let calendar = Calendar.current
        let today = Date()
        let samples: [(String, Decimal, ExpenseCategory, String, Int)] = [
            ("Blue Bottle Coffee", 6.50, .foodAndDrink, "Blue Bottle Coffee", 0),
            ("Trader Joe's", 52.80, .groceries, "Trader Joe's", 0),
            ("Shell Gas Station", 24.90, .transport, "Shell Gas", 0),
            ("Nopa Restaurant", 89.50, .dining, "Nopa Restaurant", -1),
            ("Netflix", 15.99, .entertainment, "Netflix", -1),
            ("PG&E Utility", 21.96, .home, "PG&E", -1)
        ]
        for sample in samples {
            let date = calendar.date(byAdding: .day, value: sample.4, to: today) ?? today
            add(Expense(
                title: sample.0,
                amount: sample.1,
                date: date,
                category: sample.2,
                merchant: sample.3
            ))
        }
    }
}
