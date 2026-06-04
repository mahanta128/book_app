import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ScanView: View {
    @Bindable var viewModel: ShelfScanViewModel
    @Bindable var appMode: AppModeController
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
                        .buttonStyle(.bordered)
                    } else {
                        Text("Live mode uses real OCR and Open Library. Pick a shelf photo above, or switch to Demo for an offline walkthrough.")
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
        }
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
