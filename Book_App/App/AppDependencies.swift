import Foundation

/// Composition root — swap stubs for production implementations here.
enum AppDependencies {
    static let useDemoMode: Bool = {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["BOOK_APP_LIVE"] != "1"
        #else
        return false
        #endif
    }()

    static func makeMetadataService() -> any BookMetadataServicing {
        if useDemoMode {
            StubBookMetadataService()
        } else {
            OpenLibraryMetadataService(useNetwork: true)
        }
    }

    static func makeRecognitionService() -> any BookRecognitionServicing {
        VisionBookRecognitionService(metadataService: makeMetadataService())
    }

    static func makeWishListService() -> any WishListServicing {
        FileBackedWishListService()
    }

    static func makeMissingAnalysisService() -> any MissingAnalysisServicing {
        MissingAnalysisService()
    }
}
