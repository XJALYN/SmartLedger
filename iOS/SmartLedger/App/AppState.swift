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
    @Published var pendingConfirmMessageID: UUID?
    @Published var showRatingPrompt = false
    @Published var chatMessages: [ChatMessage] = []
    @Published var isProcessingAI = false

    func navigateToConfirm(with draft: ExpenseDraft, fromMessageID: UUID? = nil) {
        pendingConfirmMessageID = fromMessageID
        pendingDraft = draft
    }

    func openManualEntry() {
        pendingConfirmMessageID = nil
        pendingDraft = ExpenseDraft.empty
    }

    func markChatExpenseSaved(messageID: UUID) {
        guard let index = chatMessages.firstIndex(where: { $0.id == messageID }) else { return }
        chatMessages[index].expenseSaved = true
    }

    func clearPendingConfirm() {
        pendingConfirmMessageID = nil
    }

    func resetChatIfNeeded() {
        if chatMessages.isEmpty {
            chatMessages = [
                ChatMessage(role: .assistant, text: String(localized: "chat.welcome"))
            ]
        }
    }
}
