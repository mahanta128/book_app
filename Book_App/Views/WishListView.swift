import SwiftUI

struct WishListImportView: View {
    @Bindable var viewModel: WishListViewModel
    @Bindable var appMode: AppModeController

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Step 1: Load your wish list here.")
                        .font(.subheadline.weight(.semibold))
                    Text("Step 2: Tap **Scan** (bottom-right button or Scan tab) to photograph a shelf and see what's missing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("How it works")
                }

                Section("Run mode") {
                    RunModePicker(appMode: appMode)

                    if appMode.isDemoMode {
                        Text("Demo loads sample titles offline. Use it to try the app without Amazon or a camera.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Load demo wish list") {
                            viewModel.loadDemo()
                        }
                    } else {
                        Text("Live mode uses your real wish list and camera on the Scan tab. Amazon import needs a network connection.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !appMode.isDemoMode {
                    Section("Amazon public URL") {
                        TextField("https://www.amazon.in/hz/wishlist/ls/…", text: $viewModel.amazonURLString)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                        Button("Import from URL") {
                            Task { await viewModel.importAmazonURL() }
                        }
                        .disabled(viewModel.isLoading)
                        Text("Best-effort only—Amazon has no official API. Public share links may work on a real device; if you see a TLS error in Simulator, paste titles manually instead.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Manual paste") {
                    Text("One book title per line. Works offline and is the most reliable import method.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $viewModel.manualPasteText)
                        .frame(minHeight: 120)
                    Button("Import pasted titles") {
                        Task { await viewModel.importManualPaste() }
                    }
                    .disabled(viewModel.isLoading)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }

                Section("Current list (\(viewModel.items.count) items)") {
                    if viewModel.isLoading {
                        ProgressView("Loading…")
                    } else if viewModel.items.isEmpty {
                        Text(appMode.isDemoMode
                             ? "Tap “Load demo wish list” above, or paste titles manually."
                             : "Import from Amazon, paste titles, or switch to Demo for a sample list.")
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
            .task { await viewModel.loadOnAppear(isDemo: appMode.isDemoMode) }
            .refreshable { await viewModel.refresh() }
        }
    }
}
