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
        case .live:
            "Real camera OCR, Open Library, and optional Amazon import (needs network)."
        case .demo:
            "Offline sample wish list and demo scan—no camera or Amazon required."
        }
    }
}
