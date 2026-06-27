import XCTest
@testable import SmartLedger

@MainActor
final class ExpenseStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ExpenseStore.shared.resetForTesting()
    }

    func testAddExpense() {
        let expense = Expense(title: "Coffee", amount: 5.5, category: .foodAndDrink, merchant: "Cafe")
        ExpenseStore.shared.add(expense)
        XCTAssertEqual(ExpenseStore.shared.expenses.count, 1)
        XCTAssertEqual(ExpenseStore.shared.expenses.first?.title, "Coffee")
    }

    func testDeleteExpense() {
        let expense = Expense(title: "Test", amount: 1, category: .other, merchant: "Shop")
        ExpenseStore.shared.add(expense)
        ExpenseStore.shared.delete(expense)
        XCTAssertTrue(ExpenseStore.shared.expenses.isEmpty)
    }

    func testSearchByTitle() {
        ExpenseStore.shared.add(Expense(title: "Starbucks", amount: 6, category: .foodAndDrink, merchant: "Starbucks"))
        ExpenseStore.shared.add(Expense(title: "Shell", amount: 40, category: .transport, merchant: "Shell"))
        let results = ExpenseStore.shared.expenses(matching: "star", category: nil)
        XCTAssertEqual(results.count, 1)
    }

    func testFilterByCategory() {
        ExpenseStore.shared.add(Expense(title: "A", amount: 1, category: .groceries, merchant: "A"))
        ExpenseStore.shared.add(Expense(title: "B", amount: 2, category: .transport, merchant: "B"))
        let results = ExpenseStore.shared.expenses(matching: "", category: .groceries)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.category, .groceries)
    }

    func testGroupedByDay() {
        ExpenseStore.shared.add(Expense(title: "Today", amount: 10, date: Date(), category: .other, merchant: "X"))
        let groups = ExpenseStore.shared.groupedByDay(ExpenseStore.shared.expenses)
        XCTAssertFalse(groups.isEmpty)
    }

    func testExpensesInWeekRange() {
        ExpenseStore.shared.add(Expense(title: "Recent", amount: 12, date: Date(), category: .other, merchant: "X"))
        let week = ExpenseStore.shared.expenses(in: .week)
        XCTAssertEqual(week.count, 1)
    }

    func testExpensesLastMonthsFiltersRollingWindow() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let reference = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
        let inWindow = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 7, day: 1)))
        let outOfWindow = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 5, day: 31)))

        ExpenseStore.shared.add(Expense(title: "In", amount: 1, date: inWindow, category: .other, merchant: "A"))
        ExpenseStore.shared.add(Expense(title: "Out", amount: 2, date: outOfWindow, category: .other, merchant: "B"))

        let results = ExpenseStore.shared.expenses(lastMonths: 12, reference: reference)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "In")
    }

    func testExpensesLastYearsFiltersRollingWindow() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let reference = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
        let inWindow = try XCTUnwrap(calendar.date(from: DateComponents(year: 2017, month: 1, day: 1)))
        let outOfWindow = try XCTUnwrap(calendar.date(from: DateComponents(year: 2016, month: 12, day: 31)))

        ExpenseStore.shared.add(Expense(title: "In", amount: 1, date: inWindow, category: .other, merchant: "A"))
        ExpenseStore.shared.add(Expense(title: "Out", amount: 2, date: outOfWindow, category: .other, merchant: "B"))

        let results = ExpenseStore.shared.expenses(lastYears: 10, reference: reference)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "In")
    }
}
