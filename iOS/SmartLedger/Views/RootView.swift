import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                tabContent
                MainTabBar(selectedTab: $appState.selectedTab, theme: settings.themeColors)
            }
        }
        .onAppear {
            appState.resetChatIfNeeded()
            if settings.shouldShowRatingPrompt() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    appState.showRatingPrompt = true
                    settings.markRatingPromptShown()
                }
            }
        }
        .sheet(item: $appState.pendingDraft) { draft in
            ConfirmExpenseView(draft: draft)
        }
        .fullScreenCover(isPresented: $appState.showRatingPrompt) {
            RatingPromptView()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch appState.selectedTab {
        case .chat: ChatView()
        case .ledger: LedgerView()
        case .stats: StatsView()
        case .settings: SettingsView()
        }
    }
}
