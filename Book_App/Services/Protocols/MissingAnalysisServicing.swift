import Foundation

protocol MissingAnalysisServicing: Sendable {
    func analyze(owned: [BookIdentity], wishList: [WishListItem]) -> ShelfScanResult
}
