import XCTest
@testable import SmartLedger

final class ExportServiceTests: XCTestCase {
    private let service = ExportService()
    private let sample = [
        Expense(title: "Coffee", amount: 5.5, category: .foodAndDrink, merchant: "Cafe"),
        Expense(title: "Gas", amount: 40, category: .transport, merchant: "Shell")
    ]

    func testExportCSVCreatesFile() throws {
        let url = try service.export(expenses: sample, format: .csv, currency: .usd)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("Coffee"))
    }

    func testExportJSONCreatesFile() throws {
        let url = try service.export(expenses: sample, format: .json, currency: .usd)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testExportPDFCreatesFile() throws {
        let url = try service.export(expenses: sample, format: .pdf, currency: .usd)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
}
