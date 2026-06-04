import Foundation
import Observation

@MainActor
@Observable
final class AppModeController {
    private static let storageKey = "shelfScout.runMode"

    var mode: AppRunMode {
        didSet {
            guard oldValue != mode else { return }
            UserDefaults.standard.set(mode.rawValue, forKey: Self.storageKey)
        }
    }

    var isDemoMode: Bool { mode == .demo }

    init() {
        if ProcessInfo.processInfo.environment["BOOK_APP_DEMO"] == "1" {
            mode = .demo
        } else if ProcessInfo.processInfo.environment["BOOK_APP_LIVE"] == "1" {
            mode = .live
        } else if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
                  let saved = AppRunMode(rawValue: raw) {
            mode = saved
        } else {
            // Simulator and device default to live; demo is opt-in via picker.
            mode = .live
        }
    }
}
