import SwiftUI

struct LedgerView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var expenseStore: ExpenseStore
    @EnvironmentObject var appState: AppState

    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var selectedExpense: Expense?

    private var filtered: [Expense] {
        expenseStore.expenses(matching: searchText, category: selectedCategory)
    }

    private var monthTotal: Decimal {
        expenseStore.expenses(in: .month).reduce(Decimal.zero) { $0 + $1.amount }
    }

    var body: some View {
        let theme = settings.themeColors

        VStack(spacing: 0) {
            header(theme: theme)
            searchSection(theme: theme)
            summaryCard(theme: theme)
            listSection(theme: theme)
        }
        .background(Color.appBackground)
        .sheet(item: $selectedExpense) { expense in
            ExpenseDetailSheet(expense: expense)
        }
    }

    private func header(theme: ThemeColors) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textMuted)
                Text("ledger.title")
                    .font(.system(size: 18, weight: .semibold))
                    .accessibilityIdentifier("ledger.title")
            }
            Spacer()
            CreditsBadge(credits: settings.credits, theme: theme) {
                appState.selectedTab = .settings
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color.white)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.borderLight).frame(height: 1) }
    }

    private func searchSection(theme: ThemeColors) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textMuted)
                TextField("ledger.search", text: $searchText)
                    .accessibilityIdentifier("ledger.search")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLight, lineWidth: 1))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: String(localized: "ledger.filter.all"), selected: selectedCategory == nil, theme: theme) {
                        selectedCategory = nil
                    }
                    ForEach([ExpenseCategory.foodAndDrink, .groceries, .transport, .home, .entertainment]) { category in
                        filterChip(
                            title: "\(category.emoji) \(String(localized: String.LocalizationValue(category.localizationKey)))",
                            selected: selectedCategory == category,
                            theme: theme
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func filterChip(title: String, selected: Bool, theme: ThemeColors, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: selected ? .semibold : .medium))
                .foregroundColor(selected ? .white : .textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selected ? theme.primary : Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.borderLight, lineWidth: selected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }

    private func summaryCard(theme: ThemeColors) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("ledger.month_total")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                Text(MoneyFormatter.string(monthTotal, currency: settings.currency))
                    .font(.system(size: 18, weight: .semibold))
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("ledger.transactions")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                Text("\(expenseStore.expenses(in: .month).count)")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .padding(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .roundedCard()
        .padding(.horizontal, 16)
    }

    private func listSection(theme: ThemeColors) -> some View {
        Group {
            if filtered.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(theme.primary)
                    Text("ledger.empty.title")
                        .font(.system(size: 16, weight: .semibold))
                    Text("ledger.empty.message")
                        .font(.system(size: 14))
                        .foregroundColor(.textMuted)
                        .multilineTextAlignment(.center)
                    Button {
                        appState.selectedTab = .chat
                    } label: {
                        Text("ledger.empty.action")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(theme.primary)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(24)
                .accessibilityIdentifier("ledger.empty")
            } else {
                List {
                    ForEach(expenseStore.groupedByDay(filtered), id: \.0) { section, items in
                        Section {
                            ForEach(items) { expense in
                                expenseRow(expense)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .onTapGesture { selectedExpense = expense }
                            }
                        } header: {
                            HStack {
                                Text(section.uppercased())
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.textMuted)
                                Spacer()
                                Text("-\(MoneyFormatter.string(items.reduce(Decimal.zero) { $0 + $1.amount }, currency: settings.currency))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.textMuted)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    expenseStore.load()
                }
            }
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            Text(expense.category.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(expense.category.backgroundTint)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text("\(String(localized: String.LocalizationValue(expense.category.localizationKey))) · \(expense.date.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }
            Spacer()
            Text("-\(MoneyFormatter.string(expense.amount, currency: settings.currency))")
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(14)
        .roundedCard()
        .accessibilityIdentifier("ledger.row.\(expense.id.uuidString)")
    }
}

struct ExpenseDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var expenseStore: ExpenseStore
    let expense: Expense
    @State private var showShare = false
    @State private var shareURL: URL?

    var body: some View {
        NavigationStack {
            List {
                LabeledContent("confirm.field.title", value: expense.title)
                LabeledContent("confirm.field.amount", value: MoneyFormatter.string(expense.amount, currency: settings.currency))
                LabeledContent("confirm.field.merchant", value: expense.merchant)
                LabeledContent("confirm.field.category") {
                    Text(LocalizedStringKey(expense.category.localizationKey))
                }
                if !expense.notes.isEmpty {
                    LabeledContent("confirm.field.notes", value: expense.notes)
                }
            }
            .navigationTitle(expense.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "common.close")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("ledger.share")
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        expenseStore.delete(expense)
                        dismiss()
                    } label: {
                        Text("ledger.delete")
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private var shareText: String {
        "\(expense.title) · \(MoneyFormatter.string(expense.amount, currency: settings.currency)) · \(expense.merchant)"
    }
}
