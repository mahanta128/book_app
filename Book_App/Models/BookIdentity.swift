import Foundation

enum MetadataSource: String, Codable, Sendable {
    case openLibrary
    case googleBooks
    case manualConfirmation
    case unresolvedOCR
}

/// Normalized book identity after OCR clustering + metadata lookup.
struct BookIdentity: Identifiable, Codable, Hashable, Sendable {
    /// Stable ID from metadata provider (Open Library work/edition key, etc.).
    let id: String
    let title: String
    let authors: [String]
    let volumeNumber: Int?
    let seriesTitle: String?
    let isbn13: String?
    let editionNote: String?
    /// 0…1 confidence in this identity vs. noisy shelf conditions.
    let matchConfidence: Double
    let source: MetadataSource
    /// OCR strings that contributed to this match (audit / re-scan).
    let rawOCRHints: [String]

    var displayAuthors: String {
        authors.isEmpty ? "Unknown author" : authors.joined(separator: ", ")
    }

    var volumeLabel: String? {
        guard let volumeNumber else { return nil }
        return "Vol. \(volumeNumber)"
    }
}

/// Intermediate spine cluster before metadata resolution.
struct SpineCandidate: Sendable {
    let mergedText: String
    let fragments: [OCRFragment]
    let averageConfidence: Float
}
