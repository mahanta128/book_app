import SwiftUI

struct RootTabView: View {
    @State private var appMode: AppModeController
    @State private var wishListVM: WishListViewModel
    @State private var scanVM: ShelfScanViewModel

    init() {
        let modeController = AppModeController()
        let isDemo = modeController.isDemoMode

        _appMode = State(initialValue: modeController)
        _wishListVM = State(initialValue: WishListViewModel())
        _scanVM = State(
            initialValue: ShelfScanViewModel(
                demoMode: isDemo,
                wishListProvider: Self.wishListItems
            )
        )
    }

    var body: some View {
        TabView {
            ScanView(viewModel: scanVM, appMode: appMode)
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }

            WishListImportView(viewModel: wishListVM, appMode: appMode)
                .tabItem {
                    Label("Wish list", systemImage: "list.bullet")
                }
        }
        .task {
            await applyRunMode(isDemo: appMode.isDemoMode)
        }
        .onChange(of: appMode.mode) { _, _ in
            Task { await applyRunMode(isDemo: appMode.isDemoMode) }
        }
    }

    private func applyRunMode(isDemo: Bool) async {
        scanVM.syncRunMode(isDemo: isDemo)
        await wishListVM.syncRunMode(isDemo: isDemo)
    }

    private static func wishListItems() async throws -> [WishListItem] {
        if let snapshot = try await AppDependencies.makeWishListService().loadSnapshot() {
            return snapshot.items
        }
        return []
    }
}
