import XCTest
@testable import SmartLedger

final class LocalizationTests: XCTestCase {
    private let requiredKeys = [
        "tab.chat", "tab.ledger", "tab.stats", "tab.settings",
        "chat.welcome", "confirm.save", "ledger.title", "stats.title", "settings.title",
        "rating.title", "error.insufficient_credits"
    ]

    private let locales = ["en", "zh-Hans"]

    private var resourcesRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("SmartLedger/Resources")
    }

    func testAllLocalesHaveRequiredKeys() {
        for locale in locales {
            let url = resourcesRoot.appendingPathComponent("\(locale).lproj/Localizable.strings")
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Missing locale file: \(locale)")
            let dict = NSDictionary(contentsOf: url) as? [String: String] ?? [:]
            for key in requiredKeys {
                XCTAssertNotNil(dict[key], "Missing key \(key) in \(locale)")
            }
        }
    }

    func testAllLocalesHaveSameKeyCount() {
        var counts: [Int] = []
        for locale in locales {
            let url = resourcesRoot.appendingPathComponent("\(locale).lproj/Localizable.strings")
            let dict = NSDictionary(contentsOf: url) as? [String: String] ?? [:]
            counts.append(dict.count)
        }
        XCTAssertEqual(Set(counts).count, 1, "Locale key counts differ: \(counts)")
    }

    func testAppLanguageResolveFromSystem() {
        let resolved = AppLanguage.resolveFromSystem()
        XCTAssertNotEqual(resolved, .system)
    }

    func testMoneyFormatterCNY() {
        let formatted = MoneyFormatter.string(Decimal(string: "34.5")!, currency: .cny)
        XCTAssertTrue(formatted.contains("34"))
        XCTAssertTrue(formatted.contains("¥"))
    }
}
