import Foundation

struct ExpenseDraft: Equatable, Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var amount: Decimal
    var date: Date
    var category: ExpenseCategory
    var merchant: String
    var notes: String
    var receiptImageData: Data?
    var subtotal: Decimal?
    var tax: Decimal?

    static var empty: ExpenseDraft {
        ExpenseDraft(
            title: "",
            amount: 0,
            date: Date(),
            category: .foodAndDrink,
            merchant: "",
            notes: "",
            receiptImageData: nil,
            subtotal: nil,
            tax: nil
        )
    }
}

struct Expense: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var amount: Decimal
    var date: Date
    var category: ExpenseCategory
    var merchant: String
    var notes: String
    var receiptImageData: Data?
    var subtotal: Decimal?
    var tax: Decimal?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        date: Date = Date(),
        category: ExpenseCategory,
        merchant: String,
        notes: String = "",
        receiptImageData: Data? = nil,
        subtotal: Decimal? = nil,
        tax: Decimal? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.merchant = merchant
        self.notes = notes
        self.receiptImageData = receiptImageData
        self.subtotal = subtotal
        self.tax = tax
        self.createdAt = createdAt
    }

    init(draft: ExpenseDraft) {
        self.init(
            title: draft.title.isEmpty ? draft.merchant : draft.title,
            amount: draft.amount,
            date: draft.date,
            category: draft.category,
            merchant: draft.merchant,
            notes: draft.notes,
            receiptImageData: draft.receiptImageData,
            subtotal: draft.subtotal,
            tax: draft.tax
        )
    }

    var searchableText: String {
        [title, merchant, notes, category.rawValue].joined(separator: " ").lowercased()
    }
}

struct ExtractedExpense: Codable, Equatable {
    var title: String
    var amount: Double
    var merchant: String
    var category: String
    var notes: String
    var dateISO: String?
    var subtotal: Double?
    var tax: Double?

    func toDraft(fallbackDate: Date = Date()) -> ExpenseDraft {
        let parsedDate: Date
        if let dateISO, let date = ISO8601DateFormatter().date(from: dateISO) {
            parsedDate = date
        } else {
            parsedDate = fallbackDate
        }
        return ExpenseDraft(
            title: title,
            amount: Decimal(amount),
            date: parsedDate,
            category: ExpenseCategory.fromAIValue(category),
            merchant: merchant,
            notes: notes,
            receiptImageData: nil,
            subtotal: subtotal.map { Decimal($0) },
            tax: tax.map { Decimal($0) }
        )
    }
}

enum ChatMessageRole: String, Codable {
    case user, assistant, system
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: ChatMessageRole
    let text: String
    let imageData: Data?
    let extractedExpense: ExtractedExpense?
    let createdAt: Date
    let isTyping: Bool

    init(
        id: UUID = UUID(),
        role: ChatMessageRole,
        text: String,
        imageData: Data? = nil,
        extractedExpense: ExtractedExpense? = nil,
        createdAt: Date = Date(),
        isTyping: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.imageData = imageData
        self.extractedExpense = extractedExpense
        self.createdAt = createdAt
        self.isTyping = isTyping
    }
}

enum StatsTimeRange: String, CaseIterable, Identifiable {
    case week, month, year, custom

    var id: String { rawValue }

    var localizationKey: String {
        "stats.range.\(rawValue)"
    }
}

struct StatsDateFilter: Equatable {
    var mode: StatsTimeRange = .month
    var selectedYear: Int = Calendar.current.component(.year, from: Date())
    var customStart: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    var customEnd: Date = Date()

    static var `default`: StatsDateFilter { StatsDateFilter() }
}
