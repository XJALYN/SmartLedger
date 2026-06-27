import XCTest
@testable import SmartLedger

final class AppSettingsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AppSettings.shared.resetForTesting()
    }

    func testDefaultLanguageIsSystem() {
        XCTAssertEqual(AppSettings.shared.language, .system)
    }

    func testSetLanguageToEnglish() {
        AppSettings.shared.language = .english
        XCTAssertEqual(AppSettings.shared.language, .english)
    }

    func testSetLanguageToChinese() {
        AppSettings.shared.language = .chinese
        XCTAssertEqual(AppSettings.shared.effectiveLanguage, .chinese)
    }

    func testAllLanguagesHaveLocales() {
        for language in AppLanguage.allCases where language != .system {
            XCTAssertFalse(language.locale.identifier.isEmpty)
        }
    }

    func testLanguagePersists() {
        AppSettings.shared.language = .chinese
        XCTAssertEqual(AppSettings.shared.language, .chinese)
    }

    func testShouldNotShowRatingPromptOnFirstLaunch() {
        AppSettings.shared.recordLaunchIfNeeded()
        XCTAssertFalse(AppSettings.shared.shouldShowRatingPrompt())
    }

    func testShouldShowRatingPromptAfterOneDay() {
        AppSettings.shared.recordLaunchIfNeeded()
        AppSettings.shared.setFirstLaunchDate(daysAgo: 2)
        XCTAssertTrue(AppSettings.shared.shouldShowRatingPrompt())
    }

    func testShouldNotShowRatingPromptIfAlreadyShown() {
        AppSettings.shared.setFirstLaunchDate(daysAgo: 2)
        AppSettings.shared.markRatingPromptShown()
        XCTAssertFalse(AppSettings.shared.shouldShowRatingPrompt())
    }

    func testShouldNotShowRatingPromptIfAlreadyRated() {
        AppSettings.shared.setFirstLaunchDate(daysAgo: 2)
        AppSettings.shared.markRated()
        XCTAssertFalse(AppSettings.shared.shouldShowRatingPrompt())
    }

    func testConsumeCredits() {
        AppSettings.shared.credits = 50
        XCTAssertTrue(AppSettings.shared.consumeCredits(10))
        XCTAssertEqual(AppSettings.shared.credits, 40)
    }

    func testConsumeCreditsFailsWhenInsufficient() {
        AppSettings.shared.credits = 3
        XCTAssertFalse(AppSettings.shared.consumeCredits(10))
        XCTAssertEqual(AppSettings.shared.credits, 3)
    }

    func testRechargeCredits() {
        AppSettings.shared.credits = 400
        AppSettings.shared.creditLimit = 500
        AppSettings.shared.rechargeCredits(100)
        XCTAssertEqual(AppSettings.shared.credits, 500)
    }

    func testThemeColorsUpdateWithTheme() {
        AppSettings.shared.theme = .sky
        XCTAssertEqual(AppSettings.shared.theme, .sky)
        XCTAssertNotNil(AppSettings.shared.themeColors.primary)
    }

    func testDaysSinceFirstLaunch() {
        AppSettings.shared.recordLaunchIfNeeded()
        AppSettings.shared.setFirstLaunchDate(daysAgo: 5)
        XCTAssertEqual(AppSettings.shared.daysSinceFirstLaunch(), 5)
    }
}
