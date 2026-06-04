import CoreGraphics
import Foundation

/// OCR + spine clustering + metadata resolution pipeline.
protocol BookRecognitionServicing: Sendable {
    func recognizeShelf(from image: CGImage) async throws -> ShelfRecognitionOutput
}

struct ShelfRecognitionOutput: Sendable {
    let identities: [BookIdentity]
    let lowConfidence: [BookIdentity]
    let unrecognizedFragments: [OCRFragment]
}
