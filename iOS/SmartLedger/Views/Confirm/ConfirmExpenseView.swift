import SwiftUI

struct ConfirmExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var expenseStore: ExpenseStore

    @State private var draft: ExpenseDraft
    @State private var showCategoryPicker = false
    @State private var showReceiptPreview = false
    @State private var amountText: String

    init(draft: ExpenseDraft) {
        _draft = State(initialValue: draft)
        _amountText = State(initialValue: "\(draft.amount)")
    }

    var body: some View {
        let theme = settings.themeColors

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if draft.receiptImageData != nil {
                        receiptSection(theme: theme)
                    }
                    insightBanner(theme: theme)
                    formSection(theme: theme)
                    if draft.subtotal != nil || draft.tax != nil {
                        breakdownSection(theme: theme)
                    }
                }
                .padding(20)
                .padding(.bottom, 120)
            }
            .background(Color.appBackground)
            .safeAreaInset(edge: .bottom) {
                actionBar(theme: theme)
            }
            .navigationTitle("confirm.title")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("confirm.screen")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 6) {
                        Circle().fill(theme.primary).frame(width: 6, height: 6)
                        Text("confirm.ai_extracted")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(theme.primaryDark)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.tintBackground)
                    .clipShape(Capsule())
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerSheet(selected: $draft.category)
            }
            .sheet(isPresented: $showReceiptPreview) {
                if let data = draft.receiptImageData, let image = UIImage(data: data) {
                    NavigationStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding()
                            .navigationTitle("confirm.receipt")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button(String(localized: "common.done")) { showReceiptPreview = false }
                                }
                            }
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func receiptSection(theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("confirm.receipt_captured", systemImage: "doc")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button("common.view") { showReceiptPreview = true }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.primaryDark)
            }
            if let data = draft.receiptImageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        Label("confirm.ocr_complete", systemImage: "checkmark")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(8)
                    }
            }
        }
        .padding(16)
        .roundedCard()
    }

    private func insightBanner(theme: ThemeColors) -> some View {
        HStack(alignment: .top, spacing: 10) {
            AIAssistantAvatar(theme: theme, size: 24)
            Text(String(format: String(localized: "confirm.ai_insight %@"), draft.merchant.isEmpty ? draft.title : draft.merchant))
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.08, green: 0.35, blue: 0.18))
        }
        .padding(12)
        .background(theme.tintBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.primary.opacity(0.2), lineWidth: 1))
    }

    private func formSection(theme: ThemeColors) -> some View {
        VStack(spacing: 16) {
            field("confirm.field.title") {
                TextField("", text: $draft.title)
                    .accessibilityIdentifier("confirm.titleField")
            }
            field("confirm.field.amount") {
                HStack {
                    Text(settings.currency.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textMuted)
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 18, weight: .semibold))
                    Text(settings.currency.code)
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }
            }
            HStack(spacing: 12) {
                field("confirm.field.date") {
                    DatePicker("", selection: $draft.date, displayedComponents: .date)
                        .labelsHidden()
                }
                field("confirm.field.time") {
                    DatePicker("", selection: $draft.date, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
            field("confirm.field.category") {
                Button { showCategoryPicker = true } label: {
                    HStack {
                        Text(draft.category.emoji)
                            .font(.title3)
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey(draft.category.localizationKey))
                                .font(.system(size: 14, weight: .semibold))
                            Text(LocalizedStringKey(draft.category.subtitleKey))
                                .font(.system(size: 11))
                                .foregroundColor(.textMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.textMuted)
                    }
                }
                .buttonStyle(.plain)
            }
            field("confirm.field.merchant") {
                TextField("", text: $draft.merchant)
            }
            field("confirm.field.notes") {
                TextField("confirm.notes_placeholder", text: $draft.notes, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .padding(20)
        .roundedCard()
    }

    private func breakdownSection(theme: ThemeColors) -> some View {
        VStack(spacing: 8) {
            if let subtotal = draft.subtotal {
                row("confirm.subtotal", MoneyFormatter.string(subtotal, currency: settings.currency))
            }
            if let tax = draft.tax {
                row("confirm.tax", MoneyFormatter.string(tax, currency: settings.currency))
            }
            Divider()
            row("confirm.total", MoneyFormatter.string(parsedAmount, currency: settings.currency), bold: true, color: theme.primaryDark)
        }
        .padding(20)
        .roundedCard()
    }

    private func row(_ key: String, _ value: String, bold: Bool = false, color: Color = .textPrimary) -> some View {
        HStack {
            Text(LocalizedStringKey(key))
                .foregroundColor(.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: bold ? .bold : .medium))
                .foregroundColor(color)
        }
        .font(.system(size: 14))
    }

    private func field<Content: View>(_ titleKey: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textMuted)
                .textCase(.uppercase)
            content()
                .padding(12)
                .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func actionBar(theme: ThemeColors) -> some View {
        VStack(spacing: 8) {
            Button {
                saveExpense()
            } label: {
                Label("confirm.save", systemImage: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: theme.primary.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("confirm.saveButton")

            Button("confirm.discard") { dismiss() }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textMuted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    private var parsedAmount: Decimal {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) ?? draft.amount
    }

    private func saveExpense() {
        draft.amount = parsedAmount
        expenseStore.add(Expense(draft: draft))
        if let messageID = appState.pendingConfirmMessageID {
            appState.markChatExpenseSaved(messageID: messageID)
        }
        appState.clearPendingConfirm()
        appState.pendingDraft = nil
        appState.selectedTab = .ledger
        dismiss()
    }
}

struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: ExpenseCategory

    var body: some View {
        NavigationStack {
            List(ExpenseCategory.allCases) { category in
                Button {
                    selected = category
                    dismiss()
                } label: {
                    HStack {
                        Text(category.emoji)
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey(category.localizationKey))
                            Text(LocalizedStringKey(category.subtitleKey))
                                .font(.caption)
                                .foregroundColor(.textMuted)
                        }
                        Spacer()
                        if selected == category {
                            Image(systemName: "checkmark")
                                .foregroundColor(.mintPrimary)
                        }
                    }
                }
            }
            .navigationTitle("confirm.select_category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.done")) { dismiss() }
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
