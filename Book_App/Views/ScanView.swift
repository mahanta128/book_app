import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ScanView: View {
    @Bindable var viewModel: ShelfScanViewModel
    @Bindable var appMode: AppModeController
    var quickActionToken: Int = 0
    @State private var showCamera = false
    @State private var showLibrary = false

    private var canScanPhoto: Bool {
        #if canImport(UIKit)
        viewModel.selectedImage != nil
        #else
        false
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Compare a shelf photo against your wish list. Load the list on the **Wish list** tab first.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    RunModePicker(appMode: appMode)

                    #if canImport(UIKit)
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    HStack {
                        Button("Camera") { showCamera = true }
                            .buttonStyle(.borderedProminent)
                        Button("Photos") { showLibrary = true }
                            .buttonStyle(.bordered)
                    }
                    #endif

                    Button {
                        Task { await viewModel.processSelectedImage() }
                    } label: {
                        Label("Scan shelf", systemImage: "text.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canScanPhoto || viewModel.isProcessing)

                    if appMode.isDemoMode {
                        Button("Run demo scan (no photo)") {
                            Task { await viewModel.runDemoScan() }
                        }
                        .buttonStyle(.borderedProminent)
                        Text("Demo scan runs offline with sample shelf data—no camera needed.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Live mode uses real OCR and Open Library. Pick a shelf photo above.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if viewModel.isProcessing {
                        ProgressView("Recognizing spines…")
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }

                    if let result = viewModel.lastResult {
                        ResultsSummaryView(result: result)
                    }
                }
                .padding()
            }
            .navigationTitle("Scan shelf")
            #if canImport(UIKit)
            .sheet(isPresented: $showCamera) {
                ImagePickerView(source: .camera, image: $viewModel.selectedImage)
            }
            .sheet(isPresented: $showLibrary) {
                ImagePickerView(source: .photoLibrary, image: $viewModel.selectedImage)
            }
            #endif
            .onChange(of: quickActionToken) { _, _ in
                handleQuickScanAction()
            }
        }
    }

    private func handleQuickScanAction() {
        if appMode.isDemoMode {
            Task { await viewModel.runDemoScan() }
            return
        }

        #if canImport(UIKit)
        if viewModel.selectedImage != nil {
            Task { await viewModel.processSelectedImage() }
        } else {
            showCamera = true
        }
        #endif
    }
}

struct ResultsSummaryView: View {
    let result: ShelfScanResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Results")
                .font(.title2.bold())

            Label("\(result.ownedBooks.count) books recognized", systemImage: "books.vertical")
            Label("\(result.missing.count) missing items", systemImage: "exclamationmark.circle")

            if !result.missing.isEmpty {
                ForEach(result.missing) { item in
                    MissingRowView(item: item)
                }
            }

            if !result.shelfOnlyBooks.isEmpty {
                Text("On shelf only (not on wish list): \(result.shelfOnlyBooks.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MissingRowView: View {
    let item: MissingItem

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: item.kind == .wishListNotOwned ? "heart" : "number")
                .foregroundStyle(item.kind == .wishListNotOwned ? .pink : .orange)
            VStack(alignment: .leading) {
                Text(item.displayTitle)
                    .font(.headline)
                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
