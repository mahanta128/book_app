import SwiftUI

struct RootTabView: View {
    @State private var appMode = AppModeController()
    @State private var wishListVM = WishListViewModel()
    @State private var scanVM: ShelfScanViewModel

    init() {
        _scanVM = State(
            initialValue: ShelfScanViewModel(
                demoMode: false,
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
            await wishListVM.loadOnAppear(isDemo: appMode.isDemoMode)
            scanVM.syncRunMode(isDemo: appMode.isDemoMode)
        }
        .onChange(of: appMode.mode) { _, _ in
            scanVM.syncRunMode(isDemo: appMode.isDemoMode)
            Task { await wishListVM.syncRunMode(isDemo: appMode.isDemoMode) }
        }
    }
}
