import SwiftUI

struct StatsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var expenseStore: ExpenseStore

    @State private var filter = StatsDateFilter.default
    private let analytics = AnalyticsService()

    private var currentExpenses: [Expense] {
        expenseStore.expenses(filter: filter)
    }

    private var previousExpenses: [Expense] {
        expenseStore.previousExpenses(for: filter)
    }

    private var availableYears: [Int] {
        expenseStore.availableYears()
    }

    var body: some View {
        let theme = settings.themeColors
        let summary = analytics.summary(for: currentExpenses, previous: previousExpenses)
        let breakdown = analytics.categoryBreakdown(for: currentExpenses)
        let chartData = chartSpending

        ScrollView {
            VStack(spacing: 20) {
                header(theme: theme)
                rangePicker(theme: theme)
                if filter.mode == .year {
                    yearPicker(theme: theme)
                }
                if filter.mode == .custom {
                    customDatePicker(theme: theme)
                }
                summaryCard(summary: summary, theme: theme)
                donutCard(breakdown: breakdown, theme: theme)
                barChartCard(chartData: chartData, theme: theme)
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
    }

    private var chartSpending: [DailySpending] {
        switch filter.mode {
        case .week:
            return analytics.dailySpending(for: currentExpenses, days: 7)
        case .month:
            return analytics.monthlySpending(for: expenseStore.expenses(lastMonths: 12), months: 12)
        case .year:
            return analytics.yearlySpending(for: expenseStore.expenses(lastYears: 10), years: 10)
        case .custom:
            return analytics.dailySpending(for: currentExpenses, days: 7)
        }
    }

    private var chartTitleKey: String {
        switch filter.mode {
        case .week, .custom: return "stats.daily_spending"
        case .month: return "stats.monthly_spending"
        case .year: return "stats.yearly_spending"
        }
    }

    private var chartPeriodLabel: String {
        switch filter.mode {
        case .week: return String(localized: "stats.this_week")
        case .month: return String(localized: "stats.last_12_months")
        case .year: return String(localized: "stats.last_10_years")
        case .custom: return String(localized: "stats.custom_range")
        }
    }

    private var chartAverageSuffix: String {
        switch filter.mode {
        case .week, .custom: return String(localized: "stats.per_day")
        case .month: return String(localized: "stats.per_month")
        case .year: return String(localized: "stats.per_year")
        }
    }

    private func header(theme: ThemeColors) -> some View {
        HStack {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.primary)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.white)
                    }
                VStack(alignment: .leading) {
                    Text("stats.overview")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                    Text("stats.title")
                        .font(.system(size: 16, weight: .semibold))
                        .accessibilityIdentifier("stats.title")
                }
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    private func rangePicker(theme: ThemeColors) -> some View {
        HStack(spacing: 4) {
            ForEach(StatsTimeRange.allCases) { item in
                Button {
                    filter.mode = item
                    if item == .year && !availableYears.contains(filter.selectedYear) {
                        filter.selectedYear = availableYears.first ?? Calendar.current.component(.year, from: Date())
                    }
                } label: {
                    Text(LocalizedStringKey(item.localizationKey))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(filter.mode == item ? .white : .textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(filter.mode == item ? theme.primary : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .accessibilityIdentifier("stats.range.\(item.rawValue)")
            }
        }
        .padding(4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLight, lineWidth: 1))
    }

    private func yearPicker(theme: ThemeColors) -> some View {
        HStack {
            Text("stats.select_year")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)
            Spacer()
            Picker("", selection: $filter.selectedYear) {
                ForEach(availableYears, id: \.self) { year in
                    Text(String(format: "%lld", year)).tag(year)
                }
            }
            .pickerStyle(.menu)
            .tint(theme.primaryDark)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLight, lineWidth: 1))
    }

    private func customDatePicker(theme: ThemeColors) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("stats.start_date")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                Spacer()
                DatePicker("", selection: $filter.customStart, displayedComponents: .date)
                    .labelsHidden()
                    .tint(theme.primary)
            }
            Divider()
            HStack {
                Text("stats.end_date")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                Spacer()
                DatePicker("", selection: $filter.customEnd, displayedComponents: .date)
                    .labelsHidden()
                    .tint(theme.primary)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLight, lineWidth: 1))
    }

    private func summaryCard(summary: SpendingSummary, theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("stats.total_spent")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textMuted)
                    .textCase(.uppercase)
                Spacer()
                if let change = summary.percentChange {
                    Text(change >= 0 ? "↑ \(Int(abs(change)))%" : "↓ \(Int(abs(change)))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(change >= 0 ? .red : theme.primaryDark)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((change >= 0 ? Color.red : theme.primary).opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text(MoneyFormatter.string(summary.total, currency: settings.currency))
                        .font(.system(size: 28, weight: .bold))
                    Text(String(format: String(localized: "stats.vs_previous %@"), MoneyFormatter.string(summary.previousTotal, currency: settings.currency)))
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
                Spacer()
                if let top = summary.topCategory {
                    VStack(alignment: .trailing) {
                        Text("stats.top_category")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                        Text("\(top.emoji) \(String(localized: String.LocalizationValue(top.localizationKey)))")
                            .font(.system(size: 13, weight: .semibold))
                        Text(MoneyFormatter.string(summary.topCategoryAmount, currency: settings.currency))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.primaryDark)
                    }
                }
            }
        }
        .padding(20)
        .roundedCard()
    }

    private func donutCard(breakdown: [CategoryBreakdown], theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("stats.category_breakdown")
                .font(.system(size: 14, weight: .semibold))
            HStack(alignment: .center, spacing: 20) {
                DonutChartView(breakdown: breakdown, theme: theme)
                    .frame(width: 140, height: 140)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(breakdown.prefix(5)) { item in
                        HStack {
                            Circle().fill(theme.primary.opacity(0.3 + item.percentage / 200)).frame(width: 10, height: 10)
                            Text(LocalizedStringKey(item.category.localizationKey))
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text("\(Int(item.percentage))%")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                }
            }
        }
        .padding(20)
        .roundedCard()
    }

    private func barChartCard(chartData: [DailySpending], theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(LocalizedStringKey(chartTitleKey))
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Label(chartPeriodLabel, systemImage: "calendar")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }
            HStack(alignment: .bottom, spacing: filter.mode == .year ? 4 : 8) {
                ForEach(chartData) { point in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(theme.primary.opacity(point.normalizedHeight > 0.8 ? 1 : 0.7))
                            .frame(height: max(8, 120 * point.normalizedHeight))
                        Text(point.label)
                            .font(.system(size: filter.mode == .year ? 9 : 10))
                            .foregroundColor(.textMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150, alignment: .bottom)
            if let highest = chartData.max(by: { $0.amount < $1.amount }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("stats.highest")
                            .font(.system(size: 10))
                            .foregroundColor(.textMuted)
                        Text("\(highest.label) · \(MoneyFormatter.compact(highest.amount, currency: settings.currency))")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("stats.average")
                            .font(.system(size: 10))
                            .foregroundColor(.textMuted)
                        let avg = chartData.isEmpty ? Decimal.zero : chartData.map(\.amount).reduce(Decimal.zero, +) / Decimal(chartData.count)
                        Text("\(MoneyFormatter.compact(avg, currency: settings.currency))\(chartAverageSuffix)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
            }
        }
        .padding(20)
        .roundedCard()
    }
}

struct DonutChartView: View {
    let breakdown: [CategoryBreakdown]
    let theme: ThemeColors

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(red: 0.95, green: 0.96, blue: 0.96), lineWidth: 18)
            ForEach(Array(breakdown.enumerated()), id: \.offset) { index, item in
                Circle()
                    .trim(from: startAngle(index: index), to: endAngle(index: index))
                    .stroke(theme.primary.opacity(1.0 - Double(index) * 0.15), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 2) {
                Text("\(breakdown.count)")
                    .font(.system(size: 18, weight: .bold))
                Text("stats.categories")
                    .font(.system(size: 10))
                    .foregroundColor(.textMuted)
            }
        }
    }

    private func startAngle(index: Int) -> CGFloat {
        let total = breakdown.map(\.percentage).reduce(0, +)
        guard total > 0 else { return 0 }
        let prior = breakdown.prefix(index).map(\.percentage).reduce(0, +)
        return CGFloat(prior / total)
    }

    private func endAngle(index: Int) -> CGFloat {
        let total = breakdown.map(\.percentage).reduce(0, +)
        guard total > 0 else { return 0 }
        let prior = breakdown.prefix(index + 1).map(\.percentage).reduce(0, +)
        return CGFloat(prior / total)
    }
}
