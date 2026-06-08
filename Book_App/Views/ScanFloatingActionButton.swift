import SwiftUI

struct ScanFloatingActionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Scan", systemImage: "camera.viewfinder")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.accentColor, in: Capsule())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.22), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan shelf")
        .accessibilityHint("Opens the shelf scanner")
    }
}
