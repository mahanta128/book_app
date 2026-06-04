# Shelf Scout (Book_App)

Photograph bookshelves → recognize spines → compare to wish list → surface **wish-list-not-owned** and **series-gap** missing items.

## Requirements

- **Xcode** 16+ (project created with Xcode 26.5; iOS 17.0 deployment target)
- **Device**: iPhone for camera capture; Simulator defaults to **Live** mode (network + Open Library)
- **API keys**: none required for MVP (Open Library Search is keyless). Optional `GOOGLE_BOOKS_API_KEY` in Info.plist for a future Google Books provider.

## Run

1. Open `Book_App.xcodeproj` in Xcode.
2. Select an iPhone simulator or device.
3. **Product → Run** (⌘R).
4. **Live** (default in Simulator): use the segmented **Live / Demo** control at the top of **Scan** or **Wish list**. Pick a shelf photo and tap **Scan shelf**, or import a real wish list. Uses on-device Vision OCR + Open Library (network required).
5. **Demo**: switch the picker to **Demo** for offline sample data and **Run demo scan** (no photo required). Switch back to **Live** to reload your saved wish list from disk.

### Scheme overrides (optional)

- `BOOK_APP_DEMO` = `1` — force Demo on launch
- `BOOK_APP_LIVE` = `1` — force Live on launch

## Info.plist privacy keys

Generated Info.plist includes (via build settings):

- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

## Architecture

See inline code under `Book_App/`:

- `Models/` — `BookIdentity`, `WishListItem`, `MissingItem`
- `Services/Protocols/` — swappable boundaries
- `Services/Vision/` — `VisionBookRecognitionService`
- `Services/Metadata/` — `OpenLibraryMetadataService` / `StubBookMetadataService`
- `Services/WishList/` — `FileBackedWishListService`, `AmazonWishListParserService`
- `Services/Matching/` — `MissingAnalysisService`, `SeriesGapDetector`
