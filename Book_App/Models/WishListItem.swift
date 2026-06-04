import Foundation

enum WishListSource: String, Codable, Sendable {
    case amazonPublicURL
    case manualPaste
    case importedJSON
    case demoFixture
}

struct WishListItem: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let authors: [String]
    let asin: String?
    let seriesTitle: String?
    /// When known from wish-list title parsing (e.g. "Volume 3").
    let expectedVolume: Int?
    let listSource: WishListSource
    let amazonURL: URL?

    var displayAuthors: String {
        authors.isEmpty ? "" : authors.joined(separator: ", ")
    }
}

struct WishListSnapshot: Codable, Sendable {
    let importedAt: Date
    let source: WishListSource
    let sourceLabel: String
    let items: [WishListItem]
}
