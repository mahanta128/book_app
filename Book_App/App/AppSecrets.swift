import Foundation

/// Optional API keys — Open Library needs none. Add Google Books here if you implement that provider.
enum AppSecrets {
    /// Google Books API key (optional). Not used by default MVP.
    static var googleBooksAPIKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "GOOGLE_BOOKS_API_KEY") as? String
    }
}
