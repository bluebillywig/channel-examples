import SwiftUI

struct SettingsPanelView: View {
    @Binding var settings: ChannelSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Display mode
                HStack {
                    Text("Display mode")
                        .font(.system(size: FontSize.sm, weight: .semibold))
                        .foregroundColor(Colors.textMuted)

                    Spacer()

                    HStack(spacing: 0) {
                        ForEach(DisplayMode.allCases, id: \.self) { mode in
                            Button { settings.displayMode = mode } label: {
                                Text(mode.rawValue)
                                    .font(.system(size: FontSize.sm, weight: settings.displayMode == mode ? .semibold : .regular))
                                    .foregroundColor(settings.displayMode == mode ? Colors.textLight : Colors.textMuted)
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.vertical, Spacing.sm)
                                    .background(settings.displayMode == mode ? Colors.accent : Colors.background)
                                    .overlay(
                                        Rectangle()
                                            .stroke(settings.displayMode == mode ? Colors.accent : Colors.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.bottom, Spacing.md)

                // Environment picker
                EnvironmentPickerView(
                    selected: settings.environment,
                    onSelect: { settings.environment = $0 },
                    customUrl: settings.customBundleUrl,
                    onCustomUrlChange: { settings.customBundleUrl = $0 }
                )

                // JWT
                Text("JWT")
                    .font(.system(size: FontSize.sm, weight: .semibold))
                    .foregroundColor(Colors.textMuted)
                    .padding(.bottom, Spacing.xs)

                TextField("Optional JWT token...", text: $settings.jwt)
                    .font(.system(size: FontSize.xs))
                    .foregroundColor(Colors.text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Colors.background)
                    .cornerRadius(Radius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .stroke(Colors.border, lineWidth: 1)
                    )
                    .padding(.bottom, Spacing.md)

                // autoPlay toggle
                HStack {
                    Text("autoPlay")
                        .font(.system(size: FontSize.sm, weight: .semibold))
                        .foregroundColor(Colors.textMuted)
                    Spacer()
                    Toggle("", isOn: $settings.autoPlay)
                        .labelsHidden()
                        .tint(Colors.accent)
                }
                .padding(.bottom, Spacing.sm)

                // noStats toggle
                HStack {
                    Text("noStats")
                        .font(.system(size: FontSize.sm, weight: .semibold))
                        .foregroundColor(Colors.textMuted)
                    Spacer()
                    Toggle("", isOn: $settings.noStats)
                        .labelsHidden()
                        .tint(Colors.accent)
                }
                .padding(.bottom, Spacing.sm)

                // useBundledJS toggle
                HStack {
                    Text("Bundled JS")
                        .font(.system(size: FontSize.sm, weight: .semibold))
                        .foregroundColor(Colors.textMuted)
                    Spacer()
                    Toggle("", isOn: $settings.useBundledJS)
                        .labelsHidden()
                        .tint(Colors.accent)
                }
            }
            .padding(Spacing.lg)
        }
        .frame(maxHeight: 320)
        .background(Colors.surface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Colors.border),
            alignment: .bottom
        )
    }
}
