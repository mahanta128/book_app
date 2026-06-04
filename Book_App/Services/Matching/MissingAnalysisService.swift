import Foundation

final class MissingAnalysisService: MissingAnalysisServicing, Sendable {
    func analyze(owned: [BookIdentity], wishList: [WishListItem]) -> ShelfScanResult {
        let highConfidence = owned.filter { $0.matchConfidence >= 0.45 }
        let lowConfidence = owned.filter { $0.matchConfidence < 0.45 }

        var missing: [MissingItem] = []

        for item in wishList {
            let (isOwned, _, score) = FuzzyMatcher.isOwned(wishListItem: item, in: highConfidence)
            if isOwned { continue }
            missing.append(
                MissingItem(
                    kind: .wishListNotOwned,
                    displayTitle: item.title,
                    detail: "On your wish list but not detected on shelf (match score \(String(format: "%.0f", score * 100))%).",
                    relatedWishListItem: item,
                    seriesTitle: item.seriesTitle,
                    missingVolumes: item.expectedVolume.map { [$0] } ?? [],
                    ownedVolumes: [],
                    confidence: max(0.5, 1.0 - score)
                )
            )
        }

        missing.append(contentsOf: SeriesGapDetector.detectGaps(in: highConfidence))

        let shelfOnly = shelfOnlyBooks(owned: highConfidence, wishList: wishList)

        return ShelfScanResult(
            ownedBooks: highConfidence,
            lowConfidenceBooks: lowConfidence,
            missing: missing.sorted { lhs, rhs in
                if lhs.kind == rhs.kind { return lhs.displayTitle < rhs.displayTitle }
                return lhs.kind.rawValue < rhs.kind.rawValue
            },
            shelfOnlyBooks: shelfOnly
        )
    }

    /// Books recognized on shelf with no wish-list correspondence (informational, not "missing").
    private func shelfOnlyBooks(owned: [BookIdentity], wishList: [WishListItem]) -> [BookIdentity] {
        owned.filter { book in
            !wishList.contains { item in
                FuzzyMatcher.isOwned(wishListItem: item, in: [book]).matched
            }
        }
    }
}
