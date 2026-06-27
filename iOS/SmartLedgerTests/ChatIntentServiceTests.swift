import XCTest
@testable import SmartLedger

final class ChatIntentServiceTests: XCTestCase {
    private let intentService = ChatIntentService()
    private let queryService = SpendingQueryService()

    func testDetectQueryIntentChinese() {
        XCTAssertEqual(intentService.detectIntent(from: "这个月我花了多少钱", hasImage: false), .querySpending)
        XCTAssertEqual(intentService.detectIntent(from: "今天花了多少", hasImage: false), .querySpending)
    }

    func testDetectQueryIntentEnglish() {
        XCTAssertEqual(intentService.detectIntent(from: "How much did I spend this month?", hasImage: false), .querySpending)
    }

    func testDetectRecordIntent() {
        XCTAssertEqual(intentService.detectIntent(from: "午餐花了35元", hasImage: false), .recordExpense)
        XCTAssertEqual(intentService.detectIntent(from: "Paid 12 dollars for coffee", hasImage: false), .recordExpense)
    }

    func testImageAlwaysRecordIntent() {
        XCTAssertEqual(intentService.detectIntent(from: "随便说点什么", hasImage: true), .recordExpense)
    }

    func testQueryAnswerUsesLocalData() {
        let expense = Expense(title: "Lunch", amount: 35, category: .dining, merchant: "Cafe")
        let answer = queryService.answer(
            text: "这个月花了多少",
            expenses: [expense],
            currency: .cny,
            isChinese: true
        )
        XCTAssertTrue(answer.contains("35"))
    }
}
