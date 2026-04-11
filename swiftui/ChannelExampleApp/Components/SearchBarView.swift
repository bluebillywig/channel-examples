import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Filter channels..."

    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .font(.system(size: FontSize.md))
                .foregroundColor(Colors.text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Colors.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Colors.border, lineWidth: 1)
                )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Colors.background)
    }
}
