import CoreGraphics
import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class ShelfScanViewModel {
    var isProcessing = false
    var lastResult: ShelfScanResult?
    var errorMessage: String?
    #if canImport(UIKit)
    var selectedImage: UIImage?
    #endif

    private var recognitionService: any BookRecognitionServicing
    private let missingService: any MissingAnalysisServicing
    private let wishListProvider: () async throws -> [WishListItem]

    init(
        demoMode: Bool = false,
        recognitionService: (any BookRecognitionServicing)? = nil,
        missingService: any MissingAnalysisServicing = AppDependencies.makeMissingAnalysisService(),
        wishListProvider: @escaping () async throws -> [WishListItem]
    ) {
        self.recognitionService = recognitionService
            ?? AppDependencies.makeRecognitionService(demoMode: demoMode)
        self.missingService = missingService
        self.wishListProvider = wishListProvider
    }

    func syncRunMode(isDemo: Bool) {
        recognitionService = AppDependencies.makeRecognitionService(demoMode: isDemo)
        lastResult = nil
        errorMessage = nil
    }

    func processSelectedImage() async {
        #if canImport(UIKit)
        guard let image = selectedImage, let cgImage = image.cgImage else {
            errorMessage = "No image to scan."
            return
        }
        await runScan(cgImage: cgImage)
        #else
        errorMessage = "Photo capture is only available on iOS."
        #endif
    }

    func runDemoScan() async {
        #if canImport(UIKit)
        if let image = UIImage(named: "DemoShelf")?.cgImage {
            await runScan(cgImage: image)
            return
        }
        #endif
        await runSyntheticDemo()
    }

    private func runScan(cgImage: CGImage) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let output = try await recognitionService.recognizeShelf(from: cgImage)
            let wishList = try await wishListProvider()
            let owned = output.identities + output.lowConfidence
            var result = missingService.analyze(owned: owned, wishList: wishList)
            result = ShelfScanResult(
                id: result.id,
                scannedAt: result.scannedAt,
                ownedBooks: output.identities,
                lowConfidenceBooks: output.lowConfidence,
                unrecognizedFragments: output.unrecognizedFragments,
                missing: result.missing,
                shelfOnlyBooks: result.shelfOnlyBooks
            )
            lastResult = result
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func runSyntheticDemo() async {
        let owned: [BookIdentity] = [
            BookIdentity(
                id: "demo-naruto-1",
                title: "Naruto, Vol. 1",
                authors: ["Masashi Kishimoto"],
                volumeNumber: 1,
                seriesTitle: "Naruto",
                isbn13: nil,
                editionNote: nil,
                matchConfidence: 0.92,
                source: .manualConfirmation,
                rawOCRHints: []
            ),
            BookIdentity(
                id: "demo-naruto-2",
                title: "Naruto, Vol. 2",
                authors: ["Masashi Kishimoto"],
                volumeNumber: 2,
                seriesTitle: "Naruto",
                isbn13: nil,
                editionNote: nil,
                matchConfidence: 0.91,
                source: .manualConfirmation,
                rawOCRHints: []
            ),
            BookIdentity(
                id: "demo-naruto-4",
                title: "Naruto, Vol. 4",
                authors: ["Masashi Kishimoto"],
                volumeNumber: 4,
                seriesTitle: "Naruto",
                isbn13: nil,
                editionNote: nil,
                matchConfidence: 0.9,
                source: .manualConfirmation,
                rawOCRHints: []
            )
        ]
        let wishList = try? await wishListProvider()
        lastResult = missingService.analyze(
            owned: owned,
            wishList: wishList ?? DemoWishListFixture.snapshot().items
        )
    }
}
