import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var expenseStore: ExpenseStore
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var storeKit: StoreKitManager

    @State private var showLanguagePicker = false
    @State private var showCurrencyPicker = false
    @State private var showExportPicker = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var alertMessage: String?
    @State private var isRestoringPurchases = false

    var body: some View {
        let theme = settings.themeColors

        ScrollView {
            VStack(spacing: 24) {
                header
                creditsCard(theme: theme)
                themePicker(theme: theme)
                preferencesSection(theme: theme)
                dataSection(theme: theme)
                Text("settings.version")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showLanguagePicker) { LanguagePickerView() }
        .sheet(isPresented: $showCurrencyPicker) { CurrencyPickerView() }
        .sheet(isPresented: $showExportPicker) { ExportPickerView(onExport: exportLedger) }
        .sheet(isPresented: $showShareSheet) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .alert(String(localized: "common.notice"), isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Button { appState.selectedTab = .chat } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 36)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.97))
                    .clipShape(Circle())
            }
            Text("settings.title")
                .font(.system(size: 18, weight: .semibold))
                .accessibilityIdentifier("settings.title")
            Spacer()
        }
        .padding(.top, 4)
    }

    private func creditsCard(theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("settings.credits.title", systemImage: "bolt.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(settings.credits)")
                    .font(.system(size: 36, weight: .bold))
                Text("/ \(settings.creditLimit)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            Text("settings.credits.subtitle")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
            VStack(spacing: 8) {
                ForEach(CreditRechargeOption.all) { option in
                    Button {
                        Task { await purchase(option) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: String(localized: "settings.credits.pack.credits %lld"), option.credits))
                                    .font(.system(size: 14, weight: .semibold))
                                Text(storeKit.displayPrice(for: option))
                                    .font(.system(size: 11))
                                    .foregroundColor(.textMuted)
                            }
                            Spacer()
                            if storeKit.purchasingProductID == option.productID {
                                ProgressView()
                                    .tint(theme.primaryDark)
                            } else {
                                Image(systemName: "cart.fill")
                                    .font(.system(size: 14))
                            }
                        }
                        .foregroundColor(theme.primaryDark)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(storeKit.purchasingProductID != nil)
                    .accessibilityIdentifier("settings.recharge.\(option.accessibilityID)")
                }
            }
            Button {
                Task { await restorePurchases() }
            } label: {
                HStack(spacing: 6) {
                    if isRestoringPurchases {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white.opacity(0.9))
                    }
                    Text("settings.credits.restore")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
            }
            .disabled(isRestoringPurchases || storeKit.purchasingProductID != nil)
            .accessibilityIdentifier("settings.restorePurchases")
        }
        .padding(20)
        .background(LinearGradient(colors: [theme.primary, theme.primaryDark], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: theme.primary.opacity(0.25), radius: 12, y: 6)
        .task {
            await storeKit.loadProducts()
        }
    }

    private func purchase(_ option: CreditRechargeOption) async {
        do {
            let credits = try await storeKit.purchase(option: option)
            alertMessage = String(format: String(localized: "settings.credits.recharged %lld"), credits)
        } catch StoreKitError.purchaseCancelled {
            return
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func restorePurchases() async {
        isRestoringPurchases = true
        defer { isRestoringPurchases = false }
        let credits = await storeKit.restorePurchases()
        if credits > 0 {
            alertMessage = String(format: String(localized: "settings.credits.restored %lld"), credits)
        } else {
            alertMessage = String(localized: "settings.credits.nothing_to_restore")
        }
    }

    private func themePicker(theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("settings.theme.title")
                .font(.system(size: 14, weight: .semibold))
            Text("settings.theme.subtitle")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)
            HStack(spacing: 12) {
                ForEach(AppThemeColor.allCases) { item in
                    Button {
                        settings.theme = item
                    } label: {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(item.color)
                            .frame(height: 48)
                            .overlay {
                                if settings.theme == item {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(settings.theme == item ? item.color : Color.clear, lineWidth: 2)
                                    .padding(-3)
                            )
                    }
                    .accessibilityIdentifier("settings.theme.\(item.rawValue)")
                }
            }
            Text(LocalizedStringKey(settings.theme.localizedNameKey))
                .font(.system(size: 11))
                .foregroundColor(.textMuted)
                .frame(maxWidth: .infinity)
        }
        .padding(20)
        .roundedCard()
    }

    private func preferencesSection(theme: ThemeColors) -> some View {
        settingsGroup("settings.section.preferences") {
            toggleRow("settings.notifications.title", subtitle: "settings.notifications.subtitle", icon: "bell", theme: theme, isOn: $settings.notificationsEnabled)
            if settings.availableCurrencies.count > 1 {
                buttonRow("settings.currency.title", subtitle: settings.currency.code, icon: "yensign.circle", theme: theme) {
                    showCurrencyPicker = true
                }
            }
            buttonRow("settings.language.title", subtitle: String(localized: String.LocalizationValue(settings.language.localizationKey)), icon: "text.alignleft", theme: theme) {
                showLanguagePicker = true
            }
        }
    }

    private func dataSection(theme: ThemeColors) -> some View {
        settingsGroup("settings.section.data") {
            buttonRow("settings.export.title", subtitle: "settings.export.subtitle", icon: "square.and.arrow.down", theme: theme) {
                showExportPicker = true
            }
            .accessibilityIdentifier("settings.export")
            buttonRow("settings.privacy.title", subtitle: "settings.privacy.subtitle", icon: "lock", theme: theme) {
                settings.faceIDEnabled.toggle()
            }
        }
    }

    private func settingsGroup<Content: View>(_ titleKey: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textMuted)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
            VStack(spacing: 0) {
                content()
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLight, lineWidth: 1))
        }
    }

    private func settingsIcon(_ name: String, theme: ThemeColors) -> some View {
        Image(systemName: name)
            .foregroundColor(theme.primaryDark)
            .frame(width: 36, height: 36)
            .background(theme.tintBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func toggleRow(_ title: String, subtitle: String, icon: String, theme: ThemeColors, isOn: Binding<Bool>) -> some View {
        HStack {
            settingsIcon(icon, theme: theme)
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 14, weight: .medium))
                Text(LocalizedStringKey(subtitle))
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(theme.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func buttonRow(_ title: String, subtitle: String, icon: String, theme: ThemeColors, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                settingsIcon(icon, theme: theme)
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey(title))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textPrimary)
                    Text(LocalizedStringKey(subtitle))
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func exportLedger(format: ExportFormat) {
        do {
            exportURL = try ExportService().export(expenses: expenseStore.expenses, format: format, currency: settings.currency)
            showShareSheet = true
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct LanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        NavigationStack {
            List(AppLanguage.allCases) { language in
                Button {
                    settings.language = language
                    dismiss()
                } label: {
                    HStack {
                        Text(LocalizedStringKey(language.localizationKey))
                        Spacer()
                        if settings.language == language {
                            Image(systemName: "checkmark").foregroundColor(.mintPrimary)
                        }
                    }
                }
            }
            .navigationTitle("settings.language.title")
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

struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        NavigationStack {
            List(settings.availableCurrencies) { currency in
                Button {
                    settings.currency = currency
                    dismiss()
                } label: {
                    HStack {
                        Text(LocalizedStringKey(currency.localizationKey))
                        Spacer()
                        if settings.currency == currency {
                            Image(systemName: "checkmark").foregroundColor(.mintPrimary)
                        }
                    }
                }
            }
            .navigationTitle("settings.currency.title")
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

struct ExportPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onExport: (ExportFormat) -> Void

    var body: some View {
        NavigationStack {
            List(ExportFormat.allCases) { format in
                Button {
                    onExport(format)
                    dismiss()
                } label: {
                    Text(LocalizedStringKey(format.localizationKey))
                }
            }
            .navigationTitle("settings.export.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

struct RatingPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: AppSettings
    @State private var showThankYou = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if showThankYou {
                thankYou
            } else {
                prompt
            }
        }
        .preferredColorScheme(.light)
    }

    private var prompt: some View {
        VStack(spacing: 24) {
            Spacer()
            AIAssistantAvatar(theme: settings.themeColors, size: 96)
            Text("rating.title")
                .font(.system(size: 22, weight: .semibold))
                .multilineTextAlignment(.center)
            Text("rating.message")
                .font(.system(size: 14))
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
            VStack(spacing: 12) {
                Button { rateNow() } label: {
                    Text("rating.rate_now")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(settings.themeColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                Button {
                    settings.scheduleRatingReminder()
                    dismiss()
                } label: {
                    Text("rating.later")
                        .foregroundColor(.textMuted)
                }
                Button {
                    settings.declineRating()
                    dismiss()
                } label: {
                    Text("rating.never")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted.opacity(0.8))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private var thankYou: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "heart.fill")
                .font(.system(size: 48))
                .foregroundColor(settings.themeColors.primary)
            Text("rating.thank_you")
                .font(.system(size: 20, weight: .semibold))
            Spacer()
            Button { dismiss() } label: {
                Text("common.done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(settings.themeColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func rateNow() {
        settings.markRated()
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        showThankYou = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
    }
}
