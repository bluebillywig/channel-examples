import SwiftUI

struct HeaderView<Right: View>: View {
    let title: String
    var subtitle: String?
    var onBack: (() -> Void)?
    @ViewBuilder var right: () -> Right

    init(
        title: String,
        subtitle: String? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder right: @escaping () -> Right = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
        self.right = right
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 0)
                .background(Colors.dark)
                .ignoresSafeArea(.container, edges: .top)

            HStack(alignment: .center) {
                if let onBack = onBack {
                    Button { onBack() } label: {
                        Text("<")
                            .font(.system(size: FontSize.lg, weight: .bold))
                            .foregroundColor(Colors.textLight)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: FontSize.lg, weight: .bold))
                        .foregroundColor(Colors.textLight)
                        .lineLimit(1)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: FontSize.xs))
                            .foregroundColor(Color.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, Spacing.sm)

                Spacer()

                right()
                    .frame(width: 36, alignment: .center)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
        }
        .background(Colors.dark)
    }
}
