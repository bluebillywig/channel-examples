import SwiftUI

struct EnvironmentPickerView: View {
    let selected: Environment
    let onSelect: (Environment) -> Void
    let customUrl: String?
    let onCustomUrlChange: (String?) -> Void

    @State private var customUrlText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Environment")
                .font(.system(size: FontSize.sm, weight: .semibold))
                .foregroundColor(Colors.textMuted)

            // Environment pills
            HStack(spacing: Spacing.sm) {
                ForEach(Environment.allCases, id: \.self) { env in
                    let isActive = selected == env && (customUrl == nil || customUrl?.isEmpty == true)
                    Button {
                        onSelect(env)
                        onCustomUrlChange(nil)
                        customUrlText = ""
                    } label: {
                        Text(env.rawValue)
                            .font(.system(size: FontSize.sm, weight: .semibold))
                            .foregroundColor(isActive ? Colors.textLight : Colors.textMuted)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(isActive ? Colors.accent : Colors.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isActive ? Colors.accent : Colors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Custom URL input
            TextField("Custom bundle URL...", text: $customUrlText)
                .font(.system(size: FontSize.xs))
                .foregroundColor(Colors.text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Colors.surface)
                .cornerRadius(Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(
                            customUrl != nil && !(customUrl?.isEmpty ?? true)
                                ? Colors.accent
                                : Colors.border,
                            lineWidth: 1
                        )
                )
                .onChange(of: customUrlText) { newValue in
                    onCustomUrlChange(newValue.isEmpty ? nil : newValue)
                }
                .onAppear {
                    customUrlText = customUrl ?? ""
                }
        }
        .padding(.bottom, Spacing.md)
    }
}
