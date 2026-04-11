import SwiftUI

@main
struct ChannelExampleApp: App {
    @State private var screen: Screen = .browser

    var body: some Scene {
        WindowGroup {
            Group {
                switch screen {
                case .browser:
                    ChannelBrowserView(
                        onSelectChannel: { url, name, host in
                            screen = .viewer(channelUrl: url, channelName: name, publicationHost: host)
                        },
                        onOpenSettings: { screen = .settings }
                    )
                case .viewer(let url, let name, _):
                    ChannelViewerView(
                        channelUrl: url,
                        channelName: name,
                        onBack: { screen = .browser }
                    )
                case .settings:
                    SettingsView(onBack: { screen = .browser })
                }
            }
        }
    }
}
