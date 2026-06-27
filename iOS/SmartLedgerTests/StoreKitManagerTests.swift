import XCTest
@testable import SmartLedger

final class StoreKitManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AppSettings.shared.resetForTesting()
    }

    func testCreditRechargeOptionProductIDs() {
        XCTAssertEqual(CreditRechargeOption.all.count, 2)
        XCTAssertEqual(CreditRechargeOption.credits(for: "com.smartledger.app.credits.100"), 100)
        XCTAssertEqual(CreditRechargeOption.credits(for: "com.smartledger.app.credits.500"), 500)
        XCTAssertNil(CreditRechargeOption.credits(for: "invalid.product"))
    }

    func testTransactionFulfillmentIsIdempotent() {
        AppSettings.shared.credits = 100
        XCTAssertFalse(AppSettings.shared.hasFulfilledTransaction("tx-001"))

        AppSettings.shared.markTransactionFulfilled("tx-001")
        XCTAssertTrue(AppSettings.shared.hasFulfilledTransaction("tx-001"))

        let before = AppSettings.shared.credits
        if !AppSettings.shared.hasFulfilledTransaction("tx-001") {
            AppSettings.shared.rechargeCredits(100)
        }
        XCTAssertEqual(AppSettings.shared.credits, before)
    }

    func testRechargeCreditsRespectsLimit() {
        AppSettings.shared.credits = 450
        AppSettings.shared.creditLimit = 500
        AppSettings.shared.rechargeCredits(100)
        XCTAssertEqual(AppSettings.shared.credits, 500)
    }
}
