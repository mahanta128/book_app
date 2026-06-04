import Foundation

enum SeriesGapDetector {
    /// Minimum owned volumes in a series before reporting gaps (avoids single-book noise).
    static let minimumOwnedVolumesForGapAnalysis = 2

    static func detectGaps(in owned: [BookIdentity]) -> [MissingItem] {
        var bySeries: [String: [BookIdentity]] = [:]

        for book in owned {
            let seriesKey = resolvedSeriesKey(for: book)
            guard !seriesKey.isEmpty else { continue }
            bySeries[seriesKey, default: []].append(book)
        }

        var results: [MissingItem] = []

        for (seriesTitle, books) in bySeries {
            let volumes = Set(books.compactMap(\.volumeNumber)).sorted()
            guard volumes.count >= minimumOwnedVolumesForGapAnalysis else { continue }

            let missing = gaps(in: volumes)
            guard !missing.isEmpty else { continue }

            results.append(
                MissingItem(
                    kind: .seriesGap,
                    displayTitle: seriesTitle,
                    detail: "Own volumes \(volumes.map(String.init).joined(separator: ", ")); missing \(missing.map(String.init).joined(separator: ", ")).",
                    seriesTitle: seriesTitle,
                    missingVolumes: missing,
                    ownedVolumes: volumes,
                    confidence: 0.85
                )
            )
        }

        return results.sorted { $0.displayTitle < $1.displayTitle }
    }

    private static func resolvedSeriesKey(for book: BookIdentity) -> String {
        if let series = book.seriesTitle, !series.isEmpty {
            return StringNormalization.normalize(series)
        }
        if book.volumeNumber != nil,
           let base = StringNormalization.parseSeriesTitle(from: book.title) {
            return StringNormalization.normalize(base)
        }
        if book.volumeNumber != nil {
            return StringNormalization.normalize(book.title)
        }
        return ""
    }

    /// Fills integer holes between min and max owned volume (e.g. 1,2,4 → [3]).
    private static func gaps(in sortedVolumes: [Int]) -> [Int] {
        guard let minVol = sortedVolumes.first, let maxVol = sortedVolumes.last else { return [] }
        let owned = Set(sortedVolumes)
        return (minVol...maxVol).filter { !owned.contains($0) }
    }
}
