import Foundation
import UIKit

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv, json, pdf

    var id: String { rawValue }

    var localizationKey: String {
        "export.format.\(rawValue)"
    }
}

struct ExportService {
    func export(expenses: [Expense], format: ExportFormat, currency: AppCurrency) throws -> URL {
        switch format {
        case .csv: return try exportCSV(expenses: expenses, currency: currency)
        case .json: return try exportJSON(expenses: expenses)
        case .pdf: return try exportPDF(expenses: expenses, currency: currency)
        }
    }

    private func exportCSV(expenses: [Expense], currency: AppCurrency) throws -> URL {
        var lines = ["Date,Title,Merchant,Category,Amount,Notes"]
        let formatter = ISO8601DateFormatter()
        for expense in expenses {
            let amount = NSDecimalNumber(decimal: expense.amount).stringValue
            let row = [
                formatter.string(from: expense.date),
                csvEscape(expense.title),
                csvEscape(expense.merchant),
                csvEscape(expense.category.rawValue),
                amount,
                csvEscape(expense.notes)
            ].joined(separator: ",")
            lines.append(row)
        }
        return try writeTemporaryFile(named: "smartledger-export.csv", content: lines.joined(separator: "\n"))
    }

    private func exportJSON(expenses: [Expense]) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(expenses)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("smartledger-export.json")
        try data.write(to: url)
        return url
    }

    private func exportPDF(expenses: [Expense], currency: AppCurrency) throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let data = renderer.pdfData { context in
            context.beginPage()
            let title = "SmartLedger Export"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20)
            ]
            title.draw(at: CGPoint(x: 40, y: 40), withAttributes: attrs)

            var y: CGFloat = 80
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]
            for expense in expenses.prefix(40) {
                let line = "\(expense.date.formatted(date: .abbreviated, time: .omitted)) · \(expense.title) · \(currency.symbol)\(NSDecimalNumber(decimal: expense.amount))"
                line.draw(at: CGPoint(x: 40, y: y), withAttributes: bodyAttrs)
                y += 18
                if y > 740 {
                    context.beginPage()
                    y = 40
                }
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("smartledger-export.pdf")
        try data.write(to: url)
        return url
    }

    private func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func writeTemporaryFile(named: String, content: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(named)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
