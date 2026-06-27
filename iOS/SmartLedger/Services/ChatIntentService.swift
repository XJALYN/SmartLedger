import Foundation

enum ChatUserIntent: Equatable {
    case recordExpense
    case querySpending
    case general
}

enum SpendingQueryRange: Equatable {
    case today
    case yesterday
    case thisWeek
    case thisMonth
    case thisYear
    case lastWeek
    case lastMonth
    case lastYear
    case allTime
}

struct ChatIntentService {
    func detectIntent(from text: String, hasImage: Bool) -> ChatUserIntent {
        if hasImage { return .recordExpense }

        let lower = text.lowercased()

        if isQueryIntent(lower) { return .querySpending }
        if isRecordIntent(text: text, lower: lower) { return .recordExpense }

        return .general
    }

    private func isQueryIntent(_ lower: String) -> Bool {
        let queryKeywords = [
            "花了多少", "消费多少", "支出多少", "多少钱", "多少元", "总共多少", "合计多少",
            "花了多少钱", "消费情况", "支出情况", "消费总结", "支出总结", "统计", "查询", "查看消费",
            "how much", "total spent", "spending summary", "how much did i spend", "what did i spend",
            "show my spending", "spending this"
        ]
        if queryKeywords.contains(where: { lower.contains($0) }) { return true }

        let timeHints = ["今天", "本周", "本月", "今年", "上周", "上月", "去年", "这个月", "这个月",
                         "today", "this week", "this month", "this year", "last week", "last month", "last year"]
        let questionHints = ["多少", "how much", "total", "summary", "统计", "总结"]
        let hasTime = timeHints.contains(where: { lower.contains($0) })
        let hasQuestion = questionHints.contains(where: { lower.contains($0) })
        return hasTime && hasQuestion
    }

    private func isRecordIntent(text: String, lower: String) -> Bool {
        let recordKeywords = [
            "买了", "花了", "支付", "付款", "消费了", "付了", "记账", "支出", "刚买",
            "spent", "paid", "bought", "purchase", "cost me", "just paid"
        ]
        let hasAmount = text.range(of: #"(?:¥|￥|\$|元|块)?\s*\d+(?:\.\d{1,2})?"#, options: .regularExpression) != nil

        if recordKeywords.contains(where: { lower.contains($0) }) && hasAmount { return true }
        if hasAmount && (lower.contains("元") || lower.contains("块") || lower.contains("¥") || lower.contains("￥")) {
            return true
        }
        return hasAmount && text.count <= 60
    }

    func parseQueryRange(from text: String) -> SpendingQueryRange {
        let lower = text.lowercased()
        if lower.contains("昨天") || lower.contains("yesterday") { return .yesterday }
        if lower.contains("上周") || lower.contains("last week") { return .lastWeek }
        if lower.contains("上月") || lower.contains("上个月") || lower.contains("last month") { return .lastMonth }
        if lower.contains("去年") || lower.contains("last year") { return .lastYear }
        if lower.contains("今天") || lower.contains("today") { return .today }
        if lower.contains("本周") || lower.contains("这周") || lower.contains("this week") { return .thisWeek }
        if lower.contains("本月") || lower.contains("这个月") || lower.contains("this month") { return .thisMonth }
        if lower.contains("今年") || lower.contains("this year") { return .thisYear }
        if lower.contains("全部") || lower.contains("所有") || lower.contains("all time") || lower.contains("overall") {
            return .allTime
        }
        return .thisMonth
    }
}

struct SpendingQueryService {
    private let calendar = Calendar.current

    func answer(
        text: String,
        expenses: [Expense],
        currency: AppCurrency,
        isChinese: Bool
    ) -> String {
        let intentService = ChatIntentService()
        let range = intentService.parseQueryRange(from: text)
        let filtered = filter(expenses, range: range)
        let total = filtered.reduce(Decimal.zero) { $0 + $1.amount }
        let count = filtered.count
        let formattedTotal = MoneyFormatter.string(total, currency: currency)
        let periodLabel = periodName(for: range, isChinese: isChinese)

        if count == 0 {
            return isChinese
                ? "\(periodLabel)暂无支出记录。"
                : "No expenses recorded for \(periodLabel)."
        }

        let grouped = Dictionary(grouping: filtered, by: \.category)
        let top = grouped.max { lhs, rhs in
            lhs.value.reduce(Decimal.zero) { $0 + $1.amount } < rhs.value.reduce(Decimal.zero) { $0 + $1.amount }
        }
        let topCategoryName: String
        if let topCategory = top?.key {
            topCategoryName = String(localized: String.LocalizationValue(topCategory.localizationKey))
        } else {
            topCategoryName = isChinese ? "其他" : "Other"
        }
        let topAmount = top?.value.reduce(Decimal.zero) { $0 + $1.amount } ?? 0

        if isChinese {
            return "\(periodLabel)共支出 \(formattedTotal)，共 \(count) 笔交易。最高分类是\(topCategoryName)，\(MoneyFormatter.string(topAmount, currency: currency))。"
        }
        return "For \(periodLabel), you spent \(formattedTotal) across \(count) transactions. Top category: \(topCategoryName) at \(MoneyFormatter.string(topAmount, currency: currency))."
    }

    func filter(_ expenses: [Expense], range: SpendingQueryRange, reference: Date = Date()) -> [Expense] {
        guard let interval = dateInterval(for: range, reference: reference) else {
            return expenses
        }
        return expenses.filter { $0.date >= interval.start && $0.date <= interval.end }
    }

    private func dateInterval(for range: SpendingQueryRange, reference: Date) -> DateInterval? {
        switch range {
        case .allTime:
            return nil
        case .today:
            let start = calendar.startOfDay(for: reference)
            let end = calendar.date(byAdding: .day, value: 1, to: start)?.addingTimeInterval(-1) ?? reference
            return DateInterval(start: start, end: end)
        case .yesterday:
            let todayStart = calendar.startOfDay(for: reference)
            let start = calendar.date(byAdding: .day, value: -1, to: todayStart) ?? reference
            let end = todayStart.addingTimeInterval(-1)
            return DateInterval(start: start, end: end)
        case .thisWeek:
            let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: reference)) ?? reference
            return DateInterval(start: start, end: reference)
        case .lastWeek:
            let thisWeekStart = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: reference)) ?? reference
            let start = calendar.date(byAdding: .day, value: -7, to: thisWeekStart) ?? reference
            let end = thisWeekStart.addingTimeInterval(-1)
            return DateInterval(start: start, end: end)
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: reference)) ?? reference
            return DateInterval(start: start, end: reference)
        case .lastMonth:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: reference)) ?? reference
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) ?? reference
            let end = thisMonthStart.addingTimeInterval(-1)
            return DateInterval(start: start, end: end)
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: reference)) ?? reference
            return DateInterval(start: start, end: reference)
        case .lastYear:
            let thisYearStart = calendar.date(from: calendar.dateComponents([.year], from: reference)) ?? reference
            let start = calendar.date(byAdding: .year, value: -1, to: thisYearStart) ?? reference
            let end = thisYearStart.addingTimeInterval(-1)
            return DateInterval(start: start, end: end)
        }
    }

    private func periodName(for range: SpendingQueryRange, isChinese: Bool) -> String {
        switch range {
        case .today: return isChinese ? "今天" : "today"
        case .yesterday: return isChinese ? "昨天" : "yesterday"
        case .thisWeek: return isChinese ? "本周" : "this week"
        case .lastWeek: return isChinese ? "上周" : "last week"
        case .thisMonth: return isChinese ? "本月" : "this month"
        case .lastMonth: return isChinese ? "上月" : "last month"
        case .thisYear: return isChinese ? "今年" : "this year"
        case .lastYear: return isChinese ? "去年" : "last year"
        case .allTime: return isChinese ? "全部时间" : "all time"
        }
    }
}
