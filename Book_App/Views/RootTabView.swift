import SwiftUI

private enum AppTab: Hashable {
    case scan
    case wishList
}

struct RootTabView: View {
    @State private var appMode: AppModeController
    @State private var wishListVM: WishListViewModel
    @State private var scanVM: ShelfScanViewModel
    @State private var selectedTab: AppTab = .scan
    @State private var scanQuickActionToken = 0

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
        TabView(selection: $selectedTab) {
            ScanView(
                viewModel: scanVM,
                appMode: appMode,
                quickActionToken: scanQuickActionToken
            )
            .tabItem {
                Label("Scan", systemImage: "camera.viewfinder")
            }
            .tag(AppTab.scan)

            WishListImportView(viewModel: wishListVM, appMode: appMode)
                .tabItem {
                    Label("Wish list", systemImage: "list.bullet")
                }
                .tag(AppTab.wishList)
        }
        .overlay(alignment: .bottomTrailing) {
            ScanFloatingActionButton {
                openScanFlow()
            }
            .padding(.trailing, 20)
            .padding(.bottom, 72)
        }
        .task {
            await applyRunMode(isDemo: appMode.isDemoMode)
        }
        .onChange(of: appMode.mode) { _, _ in
            Task { await applyRunMode(isDemo: appMode.isDemoMode) }
        }
    }

    private func openScanFlow() {
        selectedTab = .scan
        scanQuickActionToken += 1
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
