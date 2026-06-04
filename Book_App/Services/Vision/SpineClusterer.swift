import CoreGraphics
import Foundation

/// Groups horizontally adjacent OCR boxes into spine-level candidates.
enum SpineClusterer {
    private static let horizontalGapThreshold: CGFloat = 0.04
    private static let minConfidence: Float = 0.25

    static func cluster(_ fragments: [OCRFragment]) -> [SpineCandidate] {
        let filtered = fragments
            .filter { $0.confidence >= minConfidence && $0.rawText.count >= 2 }
            .sorted { $0.boundingBox.x < $1.boundingBox.x }

        guard !filtered.isEmpty else { return [] }

        var groups: [[OCRFragment]] = []
        var current: [OCRFragment] = [filtered[0]]

        for fragment in filtered.dropFirst() {
            let previous = current.last!
            let gap = fragment.boundingBox.x - (previous.boundingBox.x + previous.boundingBox.width)
            if gap <= horizontalGapThreshold {
                current.append(fragment)
            } else {
                groups.append(current)
                current = [fragment]
            }
        }
        groups.append(current)

        return groups.map { group in
            let merged = group
                .sorted { $0.boundingBox.y > $1.boundingBox.y }
                .map(\.rawText)
                .joined(separator: " ")
            let avg = group.map(\.confidence).reduce(0, +) / Float(group.count)
            return SpineCandidate(mergedText: merged, fragments: group, averageConfidence: avg)
        }
    }
}
