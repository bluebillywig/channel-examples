import SwiftUI

struct SettingsView: View {
    let onBack: () -> Void

    @AppStorage("channel_example_viewer_settings") private var settingsData: Data = {
        (try? JSONEncoder().encode(ChannelSettings.default)) ?? Data()
    }()

    private var settings: ChannelSettings {
        (try? JSONDecoder().decode(ChannelSettings.self, from: settingsData)) ?? .default
    }

    private func set(_ s: ChannelSettings) {
        if let data = try? JSONEncoder().encode(s) {
            settingsData = data
        }
    }

    private func update<V>(_ keyPath: WritableKeyPath<ChannelSettings, V>, _ value: V) {
        var s = settings
        s[keyPath: keyPath] = value
        set(s)
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                title: "Settings",
                subtitle: "Global defaults",
                onBack: onBack
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Environment picker
                    EnvironmentPickerView(
                        selected: settings.environment,
                        onSelect: { update(\.environment, $0) },
                        customUrl: settings.customBundleUrl,
                        onCustomUrlChange: { update(\.customBundleUrl, $0) }
                    )

                    // Display mode
                    HStack {
                        Text("Display mode")
                            .font(.system(size: FontSize.md, weight: .medium))
                            .foregroundColor(Colors.text)

                        Spacer()

                        HStack(spacing: 0) {
                            ForEach(DisplayMode.allCases, id: \.self) { mode in
                                Button { update(\.displayMode, mode) } label: {
                                    Text(mode.rawValue)
                                        .font(.system(size: FontSize.sm, weight: settings.displayMode == mode ? .semibold : .regular))
                                        .foregroundColor(settings.displayMode == mode ? Colors.textLight : Colors.textMuted)
                                        .padding(.horizontal, Spacing.lg)
                                        .padding(.vertical, Spacing.sm)
                                        .background(settings.displayMode == mode ? Colors.accent : Colors.surface)
                                        .overlay(
                                            Rectangle()
                                                .stroke(settings.displayMode == mode ? Colors.accent : Colors.border, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.bottom, Spacing.lg)

                    // autoPlay toggle
                    HStack {
                        Text("autoPlay")
                            .font(.system(size: FontSize.md, weight: .medium))
                            .foregroundColor(Colors.text)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settings.autoPlay },
                            set: { update(\.autoPlay, $0) }
                        ))
                        .labelsHidden()
                        .tint(Colors.accent)
                    }
                    .padding(.bottom, Spacing.md)

                    // noStats toggle
                    HStack {
                        Text("noStats")
                            .font(.system(size: FontSize.md, weight: .medium))
                            .foregroundColor(Colors.text)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settings.noStats },
                            set: { update(\.noStats, $0) }
                        ))
                        .labelsHidden()
                        .tint(Colors.accent)
                    }
                    .padding(.bottom, Spacing.md)

                    // Reset button
                    HStack {
                        Spacer()
                        Button { set(.default) } label: {
                            Text("Reset to Defaults")
                                .font(.system(size: FontSize.md, weight: .semibold))
                                .foregroundColor(Colors.textLight)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.md)
                                .background(Colors.error)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, Spacing.xxl)
                }
                .padding(Spacing.xl)
            }
        }
        .background(Colors.background)
        .preferredColorScheme(.light)
    }
}
