import SwiftUI

struct ChannelBrowserView: View {
    let onSelectChannel: (String, String, String) -> Void
    let onOpenSettings: () -> Void

    @StateObject private var viewModel = ChannelListViewModel(publications: PUBLICATIONS)
    @State private var customPubs: [Publication] = []
    @State private var showAddInput = false
    @State private var addValue = ""
    @AppStorage("channel_example_active_publication") private var activeTab: String = PUBLICATIONS[0].key
    @State private var search = ""

    private var allPubs: [Publication] {
        PUBLICATIONS + customPubs
    }

    private var tabChannels: [ChannelItem] {
        viewModel.channels[activeTab] ?? []
    }

    private var filtered: [ChannelItem] {
        if search.isEmpty { return tabChannels }
        let q = search.lowercased()
        return tabChannels.filter {
            $0.name.lowercased().contains(q) || String($0.id).contains(q)
        }
    }

    private var activePub: Publication {
        allPubs.first(where: { $0.key == activeTab }) ?? allPubs[0]
    }

    private var accentColor: Color {
        publicationColor(for: activeTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(
                title: "Channel SDK Example",
                subtitle: "Blue Billywig"
            ) {
                Button { onOpenSettings() } label: {
                    Text("*")
                        .font(.system(size: FontSize.xl, weight: .bold))
                        .foregroundColor(Colors.textLight)
                }
            }

            // Publication tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(Array(allPubs), id: \.key) { pub in
                        let isActive = pub.key == activeTab
                        let color = publicationColor(for: pub.key)
                        let count = viewModel.channels[pub.key]?.count ?? 0

                        Button {
                            activeTab = pub.key
                            search = ""
                        } label: {
                            Text("\(pub.key) (\(count))")
                                .font(.system(size: FontSize.sm, weight: .semibold))
                                .foregroundColor(isActive ? Colors.textLight : Colors.textMuted)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(isActive ? color : Colors.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(isActive ? color : Colors.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    // Add publication button / input
                    if showAddInput {
                        HStack(spacing: Spacing.xs) {
                            TextField("publication name", text: $addValue)
                                .font(.system(size: FontSize.sm))
                                .foregroundColor(Colors.text)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.xs)
                                .frame(minWidth: 140)
                                .background(Colors.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Colors.accent, lineWidth: 1)
                                )
                                .onSubmit { addCustomPub() }

                            Button { addCustomPub() } label: {
                                Text("OK")
                                    .font(.system(size: FontSize.sm, weight: .semibold))
                                    .foregroundColor(Colors.textLight)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.xs)
                                    .background(Colors.accent)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            Button {
                                showAddInput = false
                                addValue = ""
                            } label: {
                                Text("X")
                                    .font(.system(size: FontSize.md, weight: .semibold))
                                    .foregroundColor(Colors.textMuted)
                                    .padding(.horizontal, Spacing.sm)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button { showAddInput = true } label: {
                            Text("+")
                                .font(.system(size: FontSize.lg, weight: .semibold))
                                .foregroundColor(Colors.textMuted)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(Colors.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Colors.border, style: StrokeStyle(lineWidth: 1, dash: [4]))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .background(Colors.background)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Colors.border),
                alignment: .bottom
            )

            // Search bar
            SearchBarView(text: $search)

            // Channel list
            if viewModel.loading {
                Spacer()
                ProgressView()
                    .tint(Colors.accent)
                Text("Loading channels...")
                    .font(.system(size: FontSize.md))
                    .foregroundColor(Colors.textMuted)
                    .padding(.top, Spacing.md)
                Spacer()
            } else if filtered.isEmpty {
                Spacer()
                Text(search.isEmpty ? "No channels found" : "No channels match your filter")
                    .font(.system(size: FontSize.md))
                    .foregroundColor(Colors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(Spacing.xxl)
                Spacer()
            } else {
                List {
                    ForEach(filtered) { channel in
                        ChannelCardView(
                            channel: channel,
                            accentColor: accentColor,
                            onPress: {
                                onSelectChannel(
                                    getChannelUrl(host: activePub.host, id: channel.id),
                                    channel.name,
                                    activePub.host
                                )
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    viewModel.updatePublications(allPubs)
                    await viewModel.load(isRefresh: true)
                }
            }
        }
        .background(Colors.background)
        .task {
            viewModel.updatePublications(allPubs)
            await viewModel.load()
        }
    }

    private func addCustomPub() {
        let key = addValue.trimmingCharacters(in: .whitespaces).lowercased()
        guard !key.isEmpty, !allPubs.contains(where: { $0.key == key }) else {
            showAddInput = false
            addValue = ""
            return
        }
        let color = PublicationColorStore.shared.nextAdHocColor()
        PublicationColorStore.shared.set(color, for: key)
        let pub = publicationFromKey(key)
        customPubs.append(pub)
        activeTab = key
        showAddInput = false
        addValue = ""
        Task {
            viewModel.updatePublications(allPubs)
            await viewModel.load()
        }
    }
}
