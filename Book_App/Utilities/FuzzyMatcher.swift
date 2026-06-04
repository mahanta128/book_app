import Foundation

enum FuzzyMatcher {
    /// Threshold for treating a wish-list title as "owned" on shelf.
    static let ownedMatchThreshold: Double = 0.72
    static let seriesTitleThreshold: Double = 0.65

    static func isOwned(wishListItem: WishListItem, in owned: [BookIdentity]) -> (matched: Bool, book: BookIdentity?, score: Double) {
        var best: (BookIdentity, Double)?
        for book in owned {
            let titleScore = StringNormalization.tokenSimilarity(wishListItem.title, book.title)
            var authorBoost = 0.0
            if !wishListItem.authors.isEmpty, !book.authors.isEmpty {
                let wishAuthor = wishListItem.authors.joined(separator: " ")
                let bookAuthor = book.authors.joined(separator: " ")
                authorBoost = StringNormalization.tokenSimilarity(wishAuthor, bookAuthor) * 0.2
            }
            var volumePenalty = 0.0
            if let expected = wishListItem.expectedVolume, let ownedVol = book.volumeNumber, expected != ownedVol {
                volumePenalty = 0.35
            }
            let score = min(1.0, titleScore + authorBoost - volumePenalty)
            if score > (best?.1 ?? 0) {
                best = (book, score)
            }
        }
        guard let best, best.1 >= ownedMatchThreshold else {
            return (false, nil, best?.1 ?? 0)
        }
        return (true, best.0, best.1)
    }

    static func sameSeries(_ a: String, _ b: String) -> Bool {
        StringNormalization.tokenSimilarity(a, b) >= seriesTitleThreshold
    }
}
