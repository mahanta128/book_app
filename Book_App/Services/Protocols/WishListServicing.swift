import Foundation

protocol WishListServicing: Sendable {
    func loadSnapshot() async throws -> WishListSnapshot?
    func saveSnapshot(_ snapshot: WishListSnapshot) async throws
    func importFromPublicAmazonURL(_ url: URL) async throws -> WishListSnapshot
    func importFromManualText(_ text: String) async throws -> WishListSnapshot
}
