import SwiftUI

struct OverwriteConfigurationBanner: View {
    let fileURL: URL
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 8) {
            Label("Overwrite detected", systemImage: "doc.badge.gearshape")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.orange)
            Toggle("Apply overwrite configuration", isOn: $isEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
                .tint(.orange)
                .accessibilityLabel("Apply overwrite configuration")
                .accessibilityValue(isEnabled ? "On" : "Off")
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.orange.opacity(0.25)))
        .help("Overwrite file: \(fileURL.path)\n" +
              (isEnabled ? "Applied instead of the base configuration." : "Detected but disabled. Using the base configuration."))
    }
}
