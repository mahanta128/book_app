import SwiftUI

struct RootTabView: View {
    @State private var wishListVM = WishListViewModel()
    @State private var scanVM: ShelfScanViewModel

    init() {
        let wishListVM = WishListViewModel()
        _wishListVM = State(initialValue: wishListVM)
        _scanVM = State(
            initialValue: ShelfScanViewModel(
                wishListProvider: {
                    if let snapshot = try? await AppDependencies.makeWishListService().loadSnapshot() {
                        return snapshot.items
                    }
                    return DemoWishListFixture.snapshot().items
                }
            )
        )
    }

    var body: some View {
        TabView {
            ScanView(viewModel: scanVM)
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }

            WishListImportView(viewModel: wishListVM)
                .tabItem {
                    Label("Wish list", systemImage: "list.bullet")
                }
        }
    }
}
