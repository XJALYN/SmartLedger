import Foundation

/// Loads DashScope API key from bundled `LocalSecrets.plist` (gitignored).
/// Copy `Secrets.example.plist` → `LocalSecrets.plist` and fill in your key.
enum SecretsLoader {
    private static let plistName = "LocalSecrets"
    private static let keyName = "DashScopeAPIKey"

    static func dashscopeAPIKeyFromBundle() -> String? {
        guard
            let url = Bundle.main.url(forResource: plistName, withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = dict[keyName] as? String,
            !key.isEmpty,
            key != "YOUR_DASHSCOPE_API_KEY_HERE"
        else {
            return nil
        }
        return key
    }
}
