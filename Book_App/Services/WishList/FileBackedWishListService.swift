import Foundation

final class FileBackedWishListService: WishListServicing, @unchecked Sendable {
    private let parser = AmazonWishListParserService()
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "wishlist_snapshot.json") {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = dir.appendingPathComponent(filename)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadSnapshot() async throws -> WishListSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(WishListSnapshot.self, from: data)
    }

    func saveSnapshot(_ snapshot: WishListSnapshot) async throws {
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }

    func importFromPublicAmazonURL(_ url: URL) async throws -> WishListSnapshot {
        let items = try await parser.fetchItems(from: url)
        let snapshot = WishListSnapshot(
            importedAt: .now,
            source: .amazonPublicURL,
            sourceLabel: url.absoluteString,
            items: items
        )
        try await saveSnapshot(snapshot)
        return snapshot
    }

    func importFromManualText(_ text: String) async throws -> WishListSnapshot {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let items = lines.enumerated().map { index, line in
            WishListItem(
                id: "manual-\(index)-\(line.hashValue)",
                title: line,
                authors: [],
                asin: nil,
                seriesTitle: StringNormalization.parseSeriesTitle(from: line),
                expectedVolume: StringNormalization.parseVolumeNumber(from: line),
                listSource: .manualPaste,
                amazonURL: nil
            )
        }

        guard !items.isEmpty else {
            throw WishListImportError.parseFailed
        }

        let snapshot = WishListSnapshot(
            importedAt: .now,
            source: .manualPaste,
            sourceLabel: "Pasted list (\(items.count) items)",
            items: items
        )
        try await saveSnapshot(snapshot)
        return snapshot
    }
}
