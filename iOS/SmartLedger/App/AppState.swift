import Foundation
import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case chat, ledger, stats, settings

    var id: Int { rawValue }

    var localizationKey: String {
        switch self {
        case .chat: return "tab.chat"
        case .ledger: return "tab.ledger"
        case .stats: return "tab.stats"
        case .settings: return "tab.settings"
        }
    }

    var systemImage: String {
        switch self {
        case .chat: return "cpu"
        case .ledger: return "doc.text"
        case .stats: return "chart.bar"
        case .settings: return "gearshape"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .chat
    @Published var pendingDraft: ExpenseDraft?
    @Published var showRatingPrompt = false
    @Published var chatMessages: [ChatMessage] = []
    @Published var isProcessingAI = false

    func navigateToConfirm(with draft: ExpenseDraft) {
        pendingDraft = draft
    }

    func openManualEntry() {
        pendingDraft = ExpenseDraft.empty
    }

    func resetChatIfNeeded() {
        if chatMessages.isEmpty {
            chatMessages = [
                ChatMessage(role: .assistant, text: String(localized: "chat.welcome"))
            ]
        }
    }
}
