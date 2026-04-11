import SwiftUI

private enum InspectorDisplayMode {
    case hidden, collapsed, expanded
}

private let CATEGORY_COLORS: [EventCategory: Color] = [
    .lifecycle: Colors.success,
    .navigation: Colors.accent,
    .player: Color(hex: "#f1c40f"),
    .error: Colors.error,
    .analytics: Colors.textMuted,
]

struct EventInspectorView: View {
    var eventLog: EventLog
    let onClear: () -> Void

    private var events: [EventEntry] { eventLog.events }

    @State private var mode: InspectorDisplayMode = .collapsed
    @State private var filter: String = ""
    @State private var expandedId: Int?

    private var filtered: [EventEntry] {
        if filter.isEmpty { return events }
        let q = filter.lowercased()
        return events.filter { $0.type.lowercased().contains(q) }
    }

    private func cycle() {
        switch mode {
        case .hidden: mode = .collapsed
        case .collapsed: mode = .expanded
        case .expanded: mode = .hidden
        }
    }

    var body: some View {
        if mode == .hidden {
            // Floating pill badge
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button { cycle() } label: {
                        Text("Events \(events.count)")
                            .font(.system(size: FontSize.xs, weight: .semibold))
                            .foregroundColor(Colors.textLight)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Colors.dark)
                            .clipShape(Capsule())
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                }
            }
        } else {
            VStack(spacing: 0) {
                // Header bar
                Button { cycle() } label: {
                    HStack {
                        Text("Events \(filtered.count)/\(events.count)")
                            .font(.system(size: FontSize.sm, weight: .semibold))
                            .foregroundColor(Colors.textLight)

                        Spacer()

                        Button { onClear() } label: {
                            Text("Clear")
                                .font(.system(size: FontSize.sm))
                                .foregroundColor(Colors.error)
                        }

                        Text(mode == .expanded ? "v" : "^")
                            .font(.system(size: FontSize.md, weight: .bold))
                            .foregroundColor(Colors.textLight)
                            .padding(.leading, Spacing.md)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)

                Divider().background(Color.white.opacity(0.08))

                // Filter (expanded only)
                if mode == .expanded {
                    TextField("Filter by event type...", text: $filter)
                        .font(.system(size: FontSize.xs))
                        .foregroundColor(Colors.textLight)
                        .autocapitalization(.none)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(Radius.sm)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                }

                // Event list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { event in
                            EventRowView(
                                event: event,
                                isExpanded: expandedId == event.id,
                                onTap: {
                                    expandedId = expandedId == event.id ? nil : event.id
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.sm)
                }
            }
            .frame(height: mode == .expanded ? nil : 140)
            .frame(maxHeight: mode == .expanded ? 300 : 140)
            .background(Colors.dark)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.white.opacity(0.1)),
                alignment: .top
            )
        }
    }
}

private struct EventRowView: View {
    let event: EventEntry
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button { onTap() } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Spacing.sm) {
                    Text(event.time)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.4))

                    Text(event.type)
                        .font(.system(size: FontSize.xs, weight: .semibold))
                        .foregroundColor(CATEGORY_COLORS[event.category] ?? Colors.textMuted)
                        .frame(minWidth: 60, alignment: .leading)

                    Text(event.summary)
                        .font(.system(size: FontSize.xs, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.6))
                        .lineLimit(isExpanded ? nil : 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isExpanded, let detail = event.detail {
                    Text(detail)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.5))
                        .padding(.top, Spacing.xs)
                        .padding(.leading, Spacing.xl)
                }
            }
            .padding(.vertical, Spacing.xs)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.white.opacity(0.06)),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}
