import Foundation

// MARK: - Precise definitions of "missing"

/// **Wish-list-not-owned**: a wish-list item that does not fuzzy-match any
/// normalized `BookIdentity` on the shelf scan (owned set).
///
/// **Series-gap**: for a series where the user owns at least two numbered volumes,
/// any integer volume strictly between min and max owned, or consecutive gaps
/// when only sparse volumes are detected, that is not present in the owned set.
enum MissingKind: String, Codable, Sendable {
    case wishListNotOwned
    case seriesGap
}

struct MissingItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let kind: MissingKind
    let displayTitle: String
    let detail: String
    let relatedWishListItemID: String?
    let seriesTitle: String?
    let missingVolumes: [Int]
    let ownedVolumes: [Int]
    let confidence: Double

    init(
        id: UUID = UUID(),
        kind: MissingKind,
        displayTitle: String,
        detail: String,
        relatedWishListItem: WishListItem? = nil,
        seriesTitle: String? = nil,
        missingVolumes: [Int] = [],
        ownedVolumes: [Int] = [],
        confidence: Double = 1.0
    ) {
        self.id = id
        self.kind = kind
        self.displayTitle = displayTitle
        self.detail = detail
        self.relatedWishListItemID = relatedWishListItem?.id
        self.seriesTitle = seriesTitle
        self.missingVolumes = missingVolumes
        self.ownedVolumes = ownedVolumes
        self.confidence = confidence
    }
}

struct ShelfScanResult: Identifiable, Sendable {
    let id: UUID
    let scannedAt: Date
    let ownedBooks: [BookIdentity]
    let lowConfidenceBooks: [BookIdentity]
    let unrecognizedFragments: [OCRFragment]
    let missing: [MissingItem]
    let shelfOnlyBooks: [BookIdentity]

    init(
        id: UUID = UUID(),
        scannedAt: Date = .now,
        ownedBooks: [BookIdentity],
        lowConfidenceBooks: [BookIdentity] = [],
        unrecognizedFragments: [OCRFragment] = [],
        missing: [MissingItem],
        shelfOnlyBooks: [BookIdentity] = []
    ) {
        self.id = id
        self.scannedAt = scannedAt
        self.ownedBooks = ownedBooks
        self.lowConfidenceBooks = lowConfidenceBooks
        self.unrecognizedFragments = unrecognizedFragments
        self.missing = missing
        self.shelfOnlyBooks = shelfOnlyBooks
    }
}
