import Foundation

enum MetadataServiceError: LocalizedError {
    case network(Error)
    case noMatch
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .network(let error): error.localizedDescription
        case .noMatch: "No catalog match for spine text."
        case .invalidResponse: "Unexpected metadata response."
        }
    }
}

/// Resolves spine OCR against Open Library Search API (no API key required).
final class OpenLibraryMetadataService: BookMetadataServicing, @unchecked Sendable {
    private let session: URLSession
    private let useNetwork: Bool

    init(session: URLSession = .shared, useNetwork: Bool = true) {
        self.session = session
        self.useNetwork = useNetwork
    }

    func resolve(candidate: SpineCandidate) async throws -> BookIdentity? {
        let query = StringNormalization.normalize(candidate.mergedText)
        guard query.count >= 3 else { return unresolved(candidate: candidate, reason: query) }

        if !useNetwork {
            return heuristicIdentity(from: candidate)
        }

        var components = URLComponents(string: "https://openlibrary.org/search.json")!
        components.queryItems = [
            URLQueryItem(name: "q", value: candidate.mergedText),
            URLQueryItem(name: "limit", value: "5")
        ]
        guard let url = components.url else { throw MetadataServiceError.invalidResponse }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw MetadataServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(OpenLibrarySearchResponse.self, from: data)
        guard let best = pickBestMatch(docs: decoded.docs, ocr: candidate.mergedText) else {
            return heuristicIdentity(from: candidate)
        }

        let resolvedTitle = best.title ?? candidate.mergedText
        let volume = StringNormalization.parseVolumeNumber(from: resolvedTitle)
            ?? StringNormalization.parseVolumeNumber(from: candidate.mergedText)
        let series = best.series?.first ?? StringNormalization.parseSeriesTitle(from: resolvedTitle)

        let confidence = matchScore(ocr: candidate.mergedText, doc: best, ocrConfidence: candidate.averageConfidence)

        return BookIdentity(
            id: best.key ?? UUID().uuidString,
            title: resolvedTitle,
            authors: best.authorName ?? [],
            volumeNumber: volume,
            seriesTitle: series,
            isbn13: best.isbn?.first,
            editionNote: best.editionCount.map { "\($0) editions" },
            matchConfidence: confidence,
            source: .openLibrary,
            rawOCRHints: [candidate.mergedText]
        )
    }

    private func pickBestMatch(docs: [OpenLibraryDoc], ocr: String) -> OpenLibraryDoc? {
        docs
            .filter { ($0.title ?? "").count > 2 }
            .max { lhs, rhs in
                matchScore(ocr: ocr, doc: lhs, ocrConfidence: 1) < matchScore(ocr: ocr, doc: rhs, ocrConfidence: 1)
            }
    }

    private func matchScore(ocr: String, doc: OpenLibraryDoc, ocrConfidence: Float) -> Double {
        let titleScore = StringNormalization.tokenSimilarity(ocr, doc.title ?? "")
        let authorScore: Double
        if let authors = doc.authorName?.joined(separator: " ") {
            authorScore = StringNormalization.tokenSimilarity(ocr, authors) * 0.15
        } else {
            authorScore = 0
        }
        let ocrBoost = Double(ocrConfidence) * 0.1
        return min(1.0, titleScore + authorScore + ocrBoost)
    }

    private func heuristicIdentity(from candidate: SpineCandidate) -> BookIdentity {
        let title = candidate.mergedText.trimmingCharacters(in: .whitespacesAndNewlines)
        return BookIdentity(
            id: "ocr-\(UUID().uuidString)",
            title: title,
            authors: [],
            volumeNumber: StringNormalization.parseVolumeNumber(from: title),
            seriesTitle: StringNormalization.parseSeriesTitle(from: title),
            isbn13: nil,
            editionNote: nil,
            matchConfidence: Double(candidate.averageConfidence) * 0.5,
            source: .unresolvedOCR,
            rawOCRHints: [candidate.mergedText]
        )
    }

    private func unresolved(candidate: SpineCandidate, reason: String) -> BookIdentity? {
        guard !reason.isEmpty else { return nil }
        return heuristicIdentity(from: candidate)
    }
}

// MARK: - Open Library JSON

private struct OpenLibrarySearchResponse: Decodable {
    let docs: [OpenLibraryDoc]
}

private struct OpenLibraryDoc: Decodable {
    let key: String?
    let title: String?
    let authorName: [String]?
    let isbn: [String]?
    let editionCount: Int?
    let series: [String]?

    enum CodingKeys: String, CodingKey {
        case key, title, isbn, series
        case authorName = "author_name"
        case editionCount = "edition_count"
    }
}
