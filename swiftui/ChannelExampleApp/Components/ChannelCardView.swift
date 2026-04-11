import SwiftUI

struct ChannelCardView: View {
    let channel: ChannelItem
    let accentColor: Color
    let onPress: () -> Void

    var body: some View {
        Button {
            onPress()
        } label: {
            HStack(spacing: 0) {
                // Colored accent bar
                accentColor
                    .frame(width: 4)

                // Body
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(.system(size: FontSize.md, weight: .semibold))
                        .foregroundColor(Colors.text)
                        .lineLimit(1)

                    Text("ID: \(channel.id) | \(channel.status)")
                        .font(.system(size: FontSize.xs))
                        .foregroundColor(Colors.textMuted)
                }
                .padding(.vertical, Spacing.md)
                .padding(.horizontal, Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Arrow
                Text(">")
                    .font(.system(size: FontSize.lg))
                    .foregroundColor(Colors.textMuted)
                    .padding(.trailing, Spacing.lg)
            }
            .background(Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
    }
}
