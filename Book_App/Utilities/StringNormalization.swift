import Foundation

enum StringNormalization {
    static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: #"[^\p{L}\p{N}\s]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func tokenSet(_ text: String) -> Set<String> {
        Set(normalize(text).split(separator: " ").map(String.init).filter { $0.count > 1 })
    }

    /// Jaccard similarity on word tokens.
    static func tokenSimilarity(_ a: String, _ b: String) -> Double {
        let left = tokenSet(a)
        let right = tokenSet(b)
        guard !left.isEmpty, !right.isEmpty else { return 0 }
        let intersection = left.intersection(right).count
        let union = left.union(right).count
        return Double(intersection) / Double(union)
    }

    /// Extracts "Vol. 3", "Volume III", "#12" style numbers from titles.
    static func parseVolumeNumber(from title: String) -> Int? {
        let patterns: [String] = [
            #"(?i)\bvol(?:ume)?\.?\s*#?(\d+)\b"#,
            #"(?i)\bbook\s*#?(\d+)\b"#,
            #"(?i)#(\d+)\b"#,
            #"(?i)\b(\d+)\s*of\s*\d+\b"#
        ]
        for pattern in patterns {
            if let match = title.range(of: pattern, options: .regularExpression) {
                let snippet = String(title[match])
                if let digits = snippet.range(of: #"\d+"#, options: .regularExpression) {
                    return Int(title[digits])
                }
            }
        }
        return nil
    }

    static func parseSeriesTitle(from title: String) -> String? {
        let separators = [" - ", ": ", " — "]
        for sep in separators {
            if let range = title.range(of: sep) {
                let head = String(title[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                if head.count > 3 { return head }
            }
        }
        return nil
    }
}
