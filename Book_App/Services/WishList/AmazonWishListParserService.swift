import Foundation

enum WishListImportError: LocalizedError {
    case invalidURL
    case fetchFailed
    case parseFailed
    case notPublicList
    case termsRisk

    var errorDescription: String? {
        switch self {
        case .invalidURL: "That doesn't look like an Amazon wish-list URL."
        case .fetchFailed: "Could not download the list. Check the URL and network."
        case .parseFailed: "Could not parse items from the page. Amazon may have changed their HTML."
        case .notPublicList: "This list doesn't appear to be public. Share it from Amazon first."
        case .termsRisk: "Automated scraping may violate Amazon's Terms of Service. Prefer manual export."
        }
    }
}

/// Parses a **public** Amazon wish-list HTML page. Fragile by design — no official API exists.
/// Production apps should treat this as best-effort and offer manual import as primary.
final class AmazonWishListParserService: @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchItems(from url: URL) async throws -> [WishListItem] {
        guard isLikelyAmazonWishListURL(url) else { throw WishListImportError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw WishListImportError.fetchFailed
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw WishListImportError.parseFailed
        }

        if html.localizedCaseInsensitiveContains("Sign in") && html.contains("ap_email") {
            throw WishListImportError.notPublicList
        }

        let items = parseItems(fromHTML: html, sourceURL: url)
        guard !items.isEmpty else { throw WishListImportError.parseFailed }
        return items
    }

    func isLikelyAmazonWishListURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("amazon.") &&
            (url.path.localizedCaseInsensitiveContains("wishlist") ||
                url.absoluteString.localizedCaseInsensitiveContains("wishlist"))
    }

    private func parseItems(fromHTML html: String, sourceURL: URL) -> [WishListItem] {
        var items: [WishListItem] = []

        // Heuristic: data attributes and title spans vary by locale/layout.
        let patterns = [
            #"data-item-title="([^"]+)""#,
            #"<span[^>]*class="[^"]*a-text-normal[^"]*"[^>]*>([^<]{4,120})</span>"#
        ]

        var seenTitles = Set<String>()
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let range = NSRange(html.startIndex..., in: html)
            regex.enumerateMatches(in: html, options: [], range: range) { match, _, _ in
                guard let match, match.numberOfRanges > 1,
                      let titleRange = Range(match.range(at: 1), in: html) else { return }
                let title = String(html[titleRange])
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let key = StringNormalization.normalize(title)
                guard title.count > 3, seenTitles.insert(key).inserted else { return }

                items.append(
                    WishListItem(
                        id: "amz-\(key.hashValue)",
                        title: title,
                        authors: [],
                        asin: nil,
                        seriesTitle: StringNormalization.parseSeriesTitle(from: title),
                        expectedVolume: StringNormalization.parseVolumeNumber(from: title),
                        listSource: .amazonPublicURL,
                        amazonURL: sourceURL
                    )
                )
            }
        }

        return items
    }
}
