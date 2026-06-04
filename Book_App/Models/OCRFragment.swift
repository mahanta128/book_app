import CoreGraphics
import Foundation

/// Raw text observation from Vision before metadata normalization.
struct OCRFragment: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let rawText: String
    let confidence: Float
    /// Normalized Vision bounding box (origin bottom-left, 0…1).
    let boundingBox: CodableRect

    init(
        id: UUID = UUID(),
        rawText: String,
        confidence: Float,
        boundingBox: CGRect
    ) {
        self.id = id
        self.rawText = rawText
        self.confidence = confidence
        self.boundingBox = CodableRect(rect: boundingBox)
    }
}

/// CGRect wrapper for Codable persistence.
struct CodableRect: Codable, Hashable, Sendable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    init(rect: CGRect) {
        x = Double(rect.origin.x)
        y = Double(rect.origin.y)
        width = Double(rect.size.width)
        height = Double(rect.size.height)
    }

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}
