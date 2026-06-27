import XCTest
@testable import SmartLedger

final class AnalyticsServiceTests: XCTestCase {
    private let service = AnalyticsService()

    func testSummaryCalculatesTotal() {
        let expenses = [
            Expense(title: "A", amount: 10, category: .dining, merchant: "A"),
            Expense(title: "B", amount: 20, category: .groceries, merchant: "B")
        ]
        let summary = service.summary(for: expenses, previous: [])
        XCTAssertEqual(summary.total, 30)
        XCTAssertEqual(summary.transactionCount, 2)
    }

    func testCategoryBreakdownPercentages() {
        let expenses = [
            Expense(title: "A", amount: 75, category: .dining, merchant: "A"),
            Expense(title: "B", amount: 25, category: .groceries, merchant: "B")
        ]
        let breakdown = service.categoryBreakdown(for: expenses)
        XCTAssertEqual(breakdown.count, 2)
        if let first = breakdown.first {
            XCTAssertEqual(first.percentage, 75, accuracy: 0.1)
        }
    }

    func testDailySpendingReturnsSevenDays() {
        let daily = service.dailySpending(for: [])
        XCTAssertEqual(daily.count, 7)
    }

    func testMonthlySpendingReturnsTwelveMonths() {
        let monthly = service.monthlySpending(for: [])
        XCTAssertEqual(monthly.count, 12)
    }

    func testYearlySpendingReturnsTenYears() {
        let yearly = service.yearlySpending(for: [])
        XCTAssertEqual(yearly.count, 10)
    }

    func testMonthlySpendingAggregatesWithinMonth() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let reference = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
        let inMonth = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 10)))
        let outOfWindow = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 5, day: 10)))

        let expenses = [
            Expense(title: "Current", amount: 30, date: inMonth, category: .dining, merchant: "A"),
            Expense(title: "Old", amount: 99, date: outOfWindow, category: .dining, merchant: "B")
        ]

        let monthly = service.monthlySpending(for: expenses, months: 12, reference: reference)
        XCTAssertEqual(monthly.count, 12)
        XCTAssertEqual(monthly.last?.amount, 30)
        XCTAssertTrue(monthly.dropLast().allSatisfy { $0.amount == 0 })
    }

    func testYearlySpendingAggregatesWithinYear() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let reference = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
        let inYear = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 10)))
        let outOfWindow = try XCTUnwrap(calendar.date(from: DateComponents(year: 2015, month: 3, day: 10)))

        let expenses = [
            Expense(title: "Current", amount: 40, date: inYear, category: .dining, merchant: "A"),
            Expense(title: "Old", amount: 99, date: outOfWindow, category: .dining, merchant: "B")
        ]

        let yearly = service.yearlySpending(for: expenses, years: 10, reference: reference)
        XCTAssertEqual(yearly.count, 10)
        XCTAssertEqual(yearly.last?.label, "2026")
        XCTAssertEqual(yearly.last?.amount, 40)
        XCTAssertTrue(yearly.dropLast().allSatisfy { $0.amount == 0 })
    }

    func testBudgetProgress() {
        XCTAssertEqual(service.budgetProgress(total: 500, budget: 1000), 0.5, accuracy: 0.01)
        XCTAssertEqual(service.budgetProgress(total: 1500, budget: 1000), 1.0, accuracy: 0.01)
    }
}
