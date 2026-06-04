# Shelf Scout (Book_App)

Photograph bookshelves → recognize spines → compare to wish list → surface **wish-list-not-owned** and **series-gap** missing items.

## Requirements

- **Xcode** 16+ (project created with Xcode 26.5; iOS 17.0 deployment target)
- **Device**: iPhone for camera capture; Simulator runs **demo mode** without network
- **API keys**: none required for MVP (Open Library Search is keyless). Optional `GOOGLE_BOOKS_API_KEY` in Info.plist for a future Google Books provider.

## Run

1. Open `Book_App.xcodeproj` in Xcode.
2. Select an iPhone simulator or device.
3. **Product → Run** (⌘R).
4. In Simulator: **Wish list** tab loads demo data; **Scan** tab → **Run demo scan** for end-to-end missing results without a photo.
5. On device: import wish list (paste or public Amazon URL), capture shelf photo, tap **Scan shelf**.

### Live network on Simulator

Edit the scheme → **Run** → **Arguments** → Environment Variables: `BOOK_APP_LIVE` = `1` to use Vision + Open Library instead of stubs.

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
