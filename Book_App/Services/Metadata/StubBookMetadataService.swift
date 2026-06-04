import Foundation

/// Deterministic metadata for Simulator/demo without network.
final class StubBookMetadataService: BookMetadataServicing, Sendable {
    func resolve(candidate: SpineCandidate) async throws -> BookIdentity? {
        let text = candidate.mergedText
        guard text.count >= 2 else { return nil }

        let fixtures: [(needle: String, book: BookIdentity)] = [
            (
                "Naruto",
                BookIdentity(
                    id: "demo-naruto-1",
                    title: "Naruto, Vol. 1",
                    authors: ["Masashi Kishimoto"],
                    volumeNumber: 1,
                    seriesTitle: "Naruto",
                    isbn13: nil,
                    editionNote: nil,
                    matchConfidence: 0.92,
                    source: .manualConfirmation,
                    rawOCRHints: [text]
                )
            ),
            (
                "Naruto",
                BookIdentity(
                    id: "demo-naruto-2",
                    title: "Naruto, Vol. 2",
                    authors: ["Masashi Kishimoto"],
                    volumeNumber: 2,
                    seriesTitle: "Naruto",
                    isbn13: nil,
                    editionNote: nil,
                    matchConfidence: 0.91,
                    source: .manualConfirmation,
                    rawOCRHints: [text]
                )
            ),
            (
                "Naruto",
                BookIdentity(
                    id: "demo-naruto-4",
                    title: "Naruto, Vol. 4",
                    authors: ["Masashi Kishimoto"],
                    volumeNumber: 4,
                    seriesTitle: "Naruto",
                    isbn13: nil,
                    editionNote: nil,
                    matchConfidence: 0.9,
                    source: .manualConfirmation,
                    rawOCRHints: [text]
                )
            ),
            (
                "Designing Data",
                BookIdentity(
                    id: "demo-ddia",
                    title: "Designing Data-Intensive Applications",
                    authors: ["Martin Kleppmann"],
                    volumeNumber: nil,
                    seriesTitle: nil,
                    isbn13: "9781449373320",
                    editionNote: nil,
                    matchConfidence: 0.88,
                    source: .manualConfirmation,
                    rawOCRHints: [text]
                )
            )
        ]

        for fixture in fixtures where text.localizedCaseInsensitiveContains(fixture.needle) {
            let book = fixture.book
            return BookIdentity(
                id: book.id,
                title: book.title,
                authors: book.authors,
                volumeNumber: book.volumeNumber ?? StringNormalization.parseVolumeNumber(from: text),
                seriesTitle: book.seriesTitle,
                isbn13: book.isbn13,
                editionNote: book.editionNote,
                matchConfidence: book.matchConfidence,
                source: book.source,
                rawOCRHints: [text]
            )
        }

        return BookIdentity(
            id: "stub-\(UUID().uuidString)",
            title: text,
            authors: [],
            volumeNumber: StringNormalization.parseVolumeNumber(from: text),
            seriesTitle: StringNormalization.parseSeriesTitle(from: text),
            isbn13: nil,
            editionNote: "Stub match",
            matchConfidence: Double(candidate.averageConfidence) * 0.6,
            source: .unresolvedOCR,
            rawOCRHints: [text]
        )
    }
}
