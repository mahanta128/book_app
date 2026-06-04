import SwiftUI

struct WishListImportView: View {
    @Bindable var viewModel: WishListViewModel

    var body: some View {
        NavigationStack {
            Form {
                if AppDependencies.useDemoMode {
                    Section("Demo") {
                        Text("Simulator uses demo data by default. Set environment variable BOOK_APP_LIVE=1 for live Open Library + network.")
                            .font(.caption)
                        Button("Reload demo wish list") {
                            viewModel.loadDemo()
                        }
                    }
                }

                Section("Amazon public URL") {
                    TextField("https://www.amazon.com/hz/wishlist/ls/…", text: $viewModel.amazonURLString)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    Button("Import (best-effort HTML parse)") {
                        Task { await viewModel.importAmazonURL() }
                    }
                    Text("Amazon provides no official wish-list API. Only **public** share links work, and parsing may break when Amazon changes their site. Manual paste is more reliable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Manual paste") {
                    TextEditor(text: $viewModel.manualPasteText)
                        .frame(minHeight: 120)
                    Button("Import one title per line") {
                        Task { await viewModel.importManualPaste() }
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }

                Section("Current list (\(viewModel.items.count) items)") {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.items.isEmpty {
                        Text("No wish list loaded yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.items) { item in
                            VStack(alignment: .leading) {
                                Text(item.title)
                                if !item.displayAuthors.isEmpty {
                                    Text(item.displayAuthors)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wish list")
            .task { await viewModel.loadOnAppear() }
            .refreshable { await viewModel.refresh() }
        }
    }
}
