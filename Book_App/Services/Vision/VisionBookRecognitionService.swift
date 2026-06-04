import CoreGraphics
import Foundation
import Vision

enum BookRecognitionError: LocalizedError {
    case invalidImage
    case visionFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage: "Could not process the shelf image."
        case .visionFailed(let underlying): "Text recognition failed: \(underlying.localizedDescription)"
        }
    }
}

/// On-device OCR via Vision; metadata resolution delegated to `BookMetadataServicing`.
final class VisionBookRecognitionService: BookRecognitionServicing, @unchecked Sendable {
    private let metadataService: any BookMetadataServicing
    private let lowConfidenceCutoff: Double

    init(
        metadataService: any BookMetadataServicing,
        lowConfidenceCutoff: Double = 0.45
    ) {
        self.metadataService = metadataService
        self.lowConfidenceCutoff = lowConfidenceCutoff
    }

    func recognizeShelf(from image: CGImage) async throws -> ShelfRecognitionOutput {
        let fragments = try await performOCR(on: image)
        let candidates = SpineClusterer.cluster(fragments)

        var identities: [BookIdentity] = []
        var lowConfidence: [BookIdentity] = []
        var consumedFragmentIDs = Set<UUID>()

        for candidate in candidates {
            if let book = try await metadataService.resolve(candidate: candidate) {
                consumedFragmentIDs.formUnion(candidate.fragments.map(\.id))
                if book.matchConfidence < lowConfidenceCutoff {
                    lowConfidence.append(book)
                } else {
                    identities.append(book)
                }
            }
        }

        let unrecognized = fragments.filter { !consumedFragmentIDs.contains($0.id) }
        let deduped = deduplicate(identities)
        let dedupedLow = deduplicate(lowConfidence)

        return ShelfRecognitionOutput(
            identities: deduped,
            lowConfidence: dedupedLow,
            unrecognizedFragments: unrecognized
        )
    }

    private func performOCR(on image: CGImage) async throws -> [OCRFragment] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: BookRecognitionError.visionFailed(underlying: error))
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                let fragments: [OCRFragment] = observations.compactMap { observation in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return OCRFragment(
                        rawText: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }
                continuation.resume(returning: fragments)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.012

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: BookRecognitionError.visionFailed(underlying: error))
            }
        }
    }

    private func deduplicate(_ books: [BookIdentity]) -> [BookIdentity] {
        var seen = Set<String>()
        var result: [BookIdentity] = []
        for book in books.sorted(by: { $0.matchConfidence > $1.matchConfidence }) {
            let key = book.isbn13 ?? "\(book.title)|\(book.volumeNumber ?? -1)"
            if seen.insert(key).inserted {
                result.append(book)
            }
        }
        return result
    }
}
