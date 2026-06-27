import XCTest
@testable import SmartLedger

final class ExpenseCategoryTests: XCTestCase {
    func testAllCategoriesHaveEmoji() {
        for category in ExpenseCategory.allCases {
            XCTAssertFalse(category.emoji.isEmpty)
        }
    }

    func testFromAIValueGroceries() {
        XCTAssertEqual(ExpenseCategory.fromAIValue("Groceries"), .groceries)
    }

    func testFromAIValueTransport() {
        XCTAssertEqual(ExpenseCategory.fromAIValue("Gas station transport"), .transport)
    }

    func testFromAIValueDining() {
        XCTAssertEqual(ExpenseCategory.fromAIValue("Restaurant dining"), .dining)
    }

    func testFromAIValueChineseDining() {
        XCTAssertEqual(ExpenseCategory.fromAIValue("餐饮"), .dining)
    }

    func testCurrencySymbols() {
        XCTAssertEqual(AppCurrency.cny.symbol, "¥")
        XCTAssertEqual(AppCurrency.usd.symbol, "$")
    }

    func testStatsTimeRanges() {
        XCTAssertEqual(StatsTimeRange.allCases.count, 4)
    }

    func testAvailableCurrenciesForChinese() {
        XCTAssertEqual(AppCurrency.available(for: .chinese), [.cny])
    }

    func testAvailableCurrenciesForEnglish() {
        XCTAssertEqual(AppCurrency.available(for: .english), [.cny, .usd])
    }

    func testThemeColorsCount() {
        XCTAssertEqual(AppThemeColor.allCases.count, 5)
    }
}
