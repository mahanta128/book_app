import Foundation

enum WishListImportError: LocalizedError {
    case invalidURL
    case fetchFailed
    case secureConnectionFailed
    case parseFailed
    case notPublicList
    case termsRisk

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "That doesn't look like an Amazon wish-list URL. Use a public share link (amazon.com, amazon.in, etc.)."
        case .fetchFailed:
            "Could not download the list. Check the URL, your network, and that the list is public."
        case .secureConnectionFailed:
            """
            Secure connection to Amazon failed (TLS). This is common in the iOS Simulator—try a physical device, switch to Demo mode for offline testing, or paste titles manually below instead of importing the URL.
            """
        case .parseFailed:
            "Could not parse items from the page. Amazon may have changed their HTML—try manual paste."
        case .notPublicList:
            "This list doesn't appear to be public. Share it from Amazon first."
        case .termsRisk:
            "Automated scraping may violate Amazon's Terms of Service. Prefer manual export."
        }
    }
}

/// Parses a **public** Amazon wish-list HTML page. Fragile by design — no official API exists.
/// Production apps should treat this as best-effort and offer manual import as primary.
final class AmazonWishListParserService: NSObject, @unchecked Sendable {
    private let session: URLSession

    override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        config.httpShouldUsePipelining = false
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
        super.init()
    }

    init(session: URLSession) {
        self.session = session
        super.init()
    }

    func fetchItems(from url: URL) async throws -> [WishListItem] {
        let normalized = normalizeWishListURL(url)
        guard isLikelyAmazonWishListURL(normalized) else { throw WishListImportError.invalidURL }

        var request = URLRequest(url: normalized)
        request.httpMethod = "GET"
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("text/html,application/xhtml+xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw mapFetchError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw WishListImportError.fetchFailed
        }

        if (300...399).contains(http.statusCode), let location = http.value(forHTTPHeaderField: "Location"),
           let redirectURL = URL(string: location, relativeTo: normalized) {
            return try await fetchItems(from: redirectURL.absoluteURL)
        }

        guard (200...299).contains(http.statusCode) else {
            throw WishListImportError.fetchFailed
        }

        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw WishListImportError.parseFailed
        }

        if html.localizedCaseInsensitiveContains("Sign in") && html.contains("ap_email") {
            throw WishListImportError.notPublicList
        }

        let items = parseItems(fromHTML: html, sourceURL: normalized)
        guard !items.isEmpty else { throw WishListImportError.parseFailed }
        return items
    }

    func isLikelyAmazonWishListURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("amazon.") &&
            (url.path.localizedCaseInsensitiveContains("wishlist") ||
                url.path.localizedCaseInsensitiveContains("/gp/registry/") ||
                url.absoluteString.localizedCaseInsensitiveContains("wishlist"))
    }

    private func normalizeWishListURL(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }

        if components.scheme?.lowercased() == "http" {
            components.scheme = "https"
        }

        if let host = components.host?.lowercased(), host.hasPrefix("www.") == false, host.contains("amazon.") {
            components.host = "www.\(host)"
        }

        return components.url ?? url
    }

    private func mapFetchError(_ error: Error) -> WishListImportError {
        if let importError = error as? WishListImportError { return importError }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .secureConnectionFailed,
                 .serverCertificateUntrusted,
                 .clientCertificateRejected,
                 .clientCertificateRequired,
                 .cannotLoadFromNetwork:
                return .secureConnectionFailed
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost:
                return .fetchFailed
            default:
                let message = urlError.localizedDescription.lowercased()
                if message.contains("tls") || message.contains("secure connection") {
                    return .secureConnectionFailed
                }
            }
        }

        let message = error.localizedDescription.lowercased()
        if message.contains("tls") || message.contains("secure connection") {
            return .secureConnectionFailed
        }

        return .fetchFailed
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
