import Foundation

enum DemoWishListFixture {
    static func snapshot() -> WishListSnapshot {
        WishListSnapshot(
            importedAt: .now,
            source: .demoFixture,
            sourceLabel: "Demo wish list",
            items: [
                WishListItem(
                    id: "wish-ddia",
                    title: "Designing Data-Intensive Applications",
                    authors: ["Martin Kleppmann"],
                    asin: nil,
                    seriesTitle: nil,
                    expectedVolume: nil,
                    listSource: .demoFixture,
                    amazonURL: nil
                ),
                WishListItem(
                    id: "wish-naruto-3",
                    title: "Naruto, Vol. 3",
                    authors: ["Masashi Kishimoto"],
                    asin: nil,
                    seriesTitle: "Naruto",
                    expectedVolume: 3,
                    listSource: .demoFixture,
                    amazonURL: nil
                ),
                WishListItem(
                    id: "wish-sandman",
                    title: "The Sandman Vol. 1: Preludes & Nocturnes",
                    authors: ["Neil Gaiman"],
                    asin: nil,
                    seriesTitle: "The Sandman",
                    expectedVolume: 1,
                    listSource: .demoFixture,
                    amazonURL: nil
                )
            ]
        )
    }
}
