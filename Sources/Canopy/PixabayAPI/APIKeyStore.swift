import Foundation

/// Stores the user's own Pixabay API key in UserDefaults rather than
/// Keychain. Keychain access requires the OS to verify the requesting app's
/// code-signing identity against the item's ACL — during local development
/// (ad-hoc "Sign to Run Locally" signing) that identity changes on every
/// rebuild, so macOS re-prompts for the login password on every launch.
/// This key is a free-tier, rate-limited, easily-revocable Pixabay dev key —
/// not a payment credential — so the reduced protection is an acceptable
/// trade for not asking for a password every time the app opens.
enum APIKeyStore {
    private static let defaultsKey = "pixabayAPIKey"

    static func save(_ key: String) {
        UserDefaults.standard.set(key, forKey: defaultsKey)
    }

    static func load() -> String? {
        UserDefaults.standard.string(forKey: defaultsKey)
    }

    static func delete() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
