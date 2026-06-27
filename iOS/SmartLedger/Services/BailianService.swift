import Foundation

enum BailianError: LocalizedError, Equatable {
    case missingAPIKey
    case insufficientCredits
    case invalidResponse
    case network(String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return String(localized: "error.missing_api_key")
        case .insufficientCredits: return String(localized: "error.insufficient_credits")
        case .invalidResponse: return String(localized: "error.invalid_response")
        case .network(let message): return message
        case .parsingFailed: return String(localized: "error.parsing_failed")
        }
    }
}

struct BailianService {
    private let session: URLSession
    private let textModel = "qwen-plus"
    private let visionModel = "qwen-vl-max"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func extractExpense(from text: String, apiKey: String) async throws -> ExtractedExpense {
        let systemPrompt = """
        You are SmartLedger AI. Extract expense details from user input.
        Respond ONLY with valid JSON using keys: title, amount, merchant, category, notes, dateISO (ISO8601 optional), subtotal, tax.
        Amounts must be numbers without currency symbols.
        """
        let content = try await chatCompletion(
            apiKey: apiKey,
            model: textModel,
            messages: [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ]
        )
        return try parseExtractedExpense(from: content)
    }

    func extractExpense(from imageData: Data, apiKey: String, hint: String = "") async throws -> ExtractedExpense {
        let base64 = imageData.base64EncodedString()
        let prompt = """
        Read this receipt image and extract expense fields.
        Return ONLY JSON with keys: title, amount, merchant, category, notes, dateISO, subtotal, tax.
        User hint: \(hint)
        """
        let content = try await visionCompletion(
            apiKey: apiKey,
            model: visionModel,
            imageBase64: base64,
            prompt: prompt
        )
        return try parseExtractedExpense(from: content)
    }

    private func chatCompletion(apiKey: String, model: String, messages: [[String: String]]) async throws -> String {
        guard !apiKey.isEmpty else { throw BailianError.missingAPIKey }

        var request = URLRequest(url: URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.2,
            "max_tokens": 800
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP error"
            throw BailianError.network(message)
        }
        return try extractAssistantContent(from: data)
    }

    private func visionCompletion(apiKey: String, model: String, imageBase64: String, prompt: String) async throws -> String {
        guard !apiKey.isEmpty else { throw BailianError.missingAPIKey }

        var request = URLRequest(url: URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(imageBase64)"]]
                ]
            ]
        ]

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.2,
            "max_tokens": 800
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP error"
            throw BailianError.network(message)
        }
        return try extractAssistantContent(from: data)
    }

    private func extractAssistantContent(from data: Data) throws -> String {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw BailianError.invalidResponse
        }
        return content
    }

    func parseExtractedExpense(from content: String) throws -> ExtractedExpense {
        let trimmed = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let start = trimmed.firstIndex(of: "{"), let end = trimmed.lastIndex(of: "}") else {
            throw BailianError.parsingFailed
        }
        let jsonString = String(trimmed[start...end])
        guard let data = jsonString.data(using: .utf8) else { throw BailianError.parsingFailed }
        let decoder = JSONDecoder()
        return try decoder.decode(ExtractedExpense.self, from: data)
    }

    /// Offline fallback when API key is missing or network fails
    func mockExtract(from text: String) -> ExtractedExpense {
        let lower = text.lowercased()
        var amount = 0.0
        let pattern = #"(?:¥|￥|\$|元|块)?\s*(\d+(?:\.\d{1,2})?)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            amount = Double(text[range]) ?? 0
        }

        var merchant = "Unknown"
        if lower.contains("blue bottle") { merchant = "Blue Bottle Cafe" }
        else if lower.contains("starbucks") { merchant = "Starbucks" }
        else if lower.contains("trader joe") { merchant = "Trader Joe's" }
        else if lower.contains("coffee") { merchant = "Coffee Shop" }

        let category: String
        if lower.contains("groc") { category = "Groceries" }
        else if lower.contains("gas") || lower.contains("transport") { category = "Transport" }
        else if lower.contains("lunch") || lower.contains("dining") || lower.contains("dinner") { category = "Dining" }
        else if lower.contains("coffee") { category = "Food & Drink" }
        else { category = "Other" }

        return ExtractedExpense(
            title: merchant,
            amount: amount > 0 ? amount : 10,
            merchant: merchant,
            category: category,
            notes: text,
            dateISO: ISO8601DateFormatter().string(from: Date()),
            subtotal: nil,
            tax: nil
        )
    }
}
