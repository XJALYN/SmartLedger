import XCTest
@testable import SmartLedger

final class BailianServiceTests: XCTestCase {
    private let service = BailianService()

    func testMockExtractFindsAmount() {
        let result = service.mockExtract(from: "Lunch at Blue Bottle Cafe with Sarah, $34.50")
        XCTAssertEqual(result.amount, 34.5, accuracy: 0.01)
        XCTAssertEqual(result.merchant, "Blue Bottle Cafe")
    }

    func testMockExtractCategoryDining() {
        let result = service.mockExtract(from: "Dinner at Nopa $89.50")
        XCTAssertEqual(result.category, "Dining")
    }

    func testParseExtractedExpenseFromJSON() throws {
        let json = """
        {"title":"Coffee","amount":6.5,"merchant":"Starbucks","category":"Food & Drink","notes":"","dateISO":"2024-11-14T08:42:00Z"}
        """
        let extracted = try service.parseExtractedExpense(from: json)
        XCTAssertEqual(extracted.title, "Coffee")
        XCTAssertEqual(extracted.amount, 6.5, accuracy: 0.01)
    }

    func testParseExtractedExpenseFromMarkdownJSON() throws {
        let content = """
        ```json
        {"title":"Tea","amount":3,"merchant":"Shop","category":"Other","notes":""}
        ```
        """
        let extracted = try service.parseExtractedExpense(from: content)
        XCTAssertEqual(extracted.title, "Tea")
    }

    func testParseFailsForInvalidContent() {
        XCTAssertThrowsError(try service.parseExtractedExpense(from: "not json"))
    }

    func testExtractedExpenseToDraft() {
        let extracted = ExtractedExpense(title: "Lunch", amount: 12, merchant: "Cafe", category: "Dining", notes: "with Alex", dateISO: nil, subtotal: nil, tax: nil)
        let draft = extracted.toDraft()
        XCTAssertEqual(draft.title, "Lunch")
        XCTAssertEqual(draft.category, .dining)
    }
}
