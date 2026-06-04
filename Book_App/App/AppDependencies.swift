import Foundation

/// Composition root — swap stubs for production implementations here.
enum AppDependencies {
    static func makeMetadataService(demoMode: Bool) -> any BookMetadataServicing {
        if demoMode {
            StubBookMetadataService()
        } else {
            OpenLibraryMetadataService(useNetwork: true)
        }
    }

    static func makeRecognitionService(demoMode: Bool) -> any BookRecognitionServicing {
        VisionBookRecognitionService(metadataService: makeMetadataService(demoMode: demoMode))
    }

    static func makeWishListService() -> any WishListServicing {
        FileBackedWishListService()
    }

    static func makeMissingAnalysisService() -> any MissingAnalysisServicing {
        MissingAnalysisService()
    }
}
