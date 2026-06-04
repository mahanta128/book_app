import Foundation

enum AppRunMode: String, CaseIterable, Identifiable, Sendable {
    case live
    case demo

    var id: String { rawValue }

    var label: String {
        switch self {
        case .live: "Live"
        case .demo: "Demo"
        }
    }

    var subtitle: String {
        switch self {
        case .live: "Vision OCR + Open Library lookup"
        case .demo: "Offline fixtures + instant demo scan"
        }
    }
}
