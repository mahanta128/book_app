import Foundation
import Observation

@MainActor
@Observable
final class WishListViewModel {
    var snapshot: WishListSnapshot?
    var isLoading = false
    var errorMessage: String?
    var amazonURLString = ""
    var manualPasteText = ""

    private let service: any WishListServicing

    init(service: any WishListServicing = AppDependencies.makeWishListService()) {
        self.service = service
    }

    func loadOnAppear() async {
        if AppDependencies.useDemoMode, snapshot == nil {
            snapshot = DemoWishListFixture.snapshot()
            return
        }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            snapshot = try await service.loadSnapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadDemo() {
        snapshot = DemoWishListFixture.snapshot()
    }

    func importAmazonURL() async {
        guard let url = URL(string: amazonURLString.trimmingCharacters(in: .whitespacesAndNewlines)),
              !amazonURLString.isEmpty else {
            errorMessage = WishListImportError.invalidURL.localizedDescription
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            snapshot = try await service.importFromPublicAmazonURL(url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importManualPaste() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            snapshot = try await service.importFromManualText(manualPasteText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var items: [WishListItem] {
        snapshot?.items ?? []
    }
}
