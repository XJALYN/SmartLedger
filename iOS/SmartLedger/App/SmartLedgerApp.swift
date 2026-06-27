import SwiftUI

@main
struct SmartLedgerApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var settings = AppSettings.shared
    @StateObject private var expenseStore = ExpenseStore.shared
    @StateObject private var storeKit = StoreKitManager.shared

    init() {
        UIView.appearance().overrideUserInterfaceStyle = .light
        AppSettings.shared.recordLaunchIfNeeded()
        StoreKitManager.shared.start(settings: AppSettings.shared)
        if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
            AppSettings.shared.ratingPromptShown = true
            ExpenseStore.shared.resetForTesting()
            ExpenseStore.shared.seedSampleDataIfEmpty()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(settings)
                .environmentObject(expenseStore)
                .environmentObject(storeKit)
                .environment(\.locale, settings.activeLocale)
                .preferredColorScheme(.light)
        }
    }
}
