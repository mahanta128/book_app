import SwiftUI

struct RunModePicker: View {
    @Bindable var appMode: AppModeController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("Run mode", selection: $appMode.mode) {
                ForEach(AppRunMode.allCases) { runMode in
                    Text(runMode.label).tag(runMode)
                }
            }
            .pickerStyle(.segmented)

            Text(appMode.mode.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
