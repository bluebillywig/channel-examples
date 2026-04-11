import SwiftUI
import BBChannelSwiftUI
import BBNativePlayerKit
import BBNativePlayerKit_SwiftUI

private func ts() -> String {
    let d = Date()
    let cal = Calendar.current
    return String(format: "%02d:%02d:%02d.%03d",
        cal.component(.hour, from: d), cal.component(.minute, from: d),
        cal.component(.second, from: d), cal.component(.nanosecond, from: d) / 1_000_000)
}

private func categorize(_ type: String) -> EventCategory {
    if type == "error" || type.contains("Error") { return .error }
    if type.hasPrefix("analytics") { return .analytics }
    if type.contains("nav") || type.contains("Nav") || type == "canGoBack" { return .navigation }
    if type.contains("player") || type.contains("Player") || type.contains("media") ||
       type.contains("Media") || type.contains("clip") || type.contains("Clip") ||
       type.contains("ad") || type == "timeUpdate" { return .player }
    return .lifecycle
}

@Observable @MainActor
class EventLog {
    var events: [EventEntry] = []
    @ObservationIgnored private var eventIdCounter = 0
    @ObservationIgnored var lastLoggedSecond: Int = -1

    func log(_ type: String, _ summary: String, _ detail: String? = nil) {
        eventIdCounter += 1
        events.insert(EventEntry(id: eventIdCounter, time: ts(), type: type,
            category: categorize(type), summary: summary, detail: detail), at: 0)
        if events.count > 200 { events = Array(events.prefix(200)) }
    }
    func clear() { events.removeAll() }
}

struct ChannelViewerView: View {
    let channelUrl: String
    let channelName: String
    let onBack: () -> Void

    @AppStorage("channel_example_viewer_settings") private var settingsData: Data = {
        (try? JSONEncoder().encode(ChannelSettings.default)) ?? Data()
    }()

    @State private var showSettings = false
    @State private var eventLog = EventLog()
    @StateObject private var playerVM = BBChannelWithPlayerViewModel()
    @State private var settings: ChannelSettings = .default

    private var bundleUrl: String {
        getBundleUrl(env: settings.environment, customUrl: settings.customBundleUrl)
    }

    private var channelOptions: BBChannelOptions {
        BBChannelOptions(
            autoPlay: settings.autoPlay,
            noStats: settings.noStats,
            jwt: settings.jwt.isEmpty ? nil : settings.jwt,
            bundleUrl: settings.useBundledJS ? nil : bundleUrl,
            bundledNativeBridgeJS: settings.useBundledJS ? bundledNativeBridgeJS : nil,
            bundledChannelJS: settings.useBundledJS ? bundledChannelJS : nil
        )
    }

    private var callbacks: BBChannelCallbacks {
        BBChannelCallbacks(
            onReady: { [eventLog] in eventLog.log("ready", "Channel loaded") },
            onError: { [eventLog] e in eventLog.log("error", "[\(e.code)] \(e.message)") },
            onNavigate: { [eventLog] e in eventLog.log("navigate", e.pageType) },
            onNavigationStateChange: { [eventLog] state in eventLog.log("navState", state.pageType.rawValue) },
            onCanGoBackChange: { [eventLog] v in eventLog.log("canGoBack", String(v)) },
            onSearch: { [eventLog] e in eventLog.log("search", "\(e)") },
            onMediaPlay: { [eventLog] m in eventLog.log("mediaPlay", m.title ?? m.jsonUrl) },
            onMediaPause: { [eventLog] m in eventLog.log("mediaPause", m.title ?? m.jsonUrl) },
            onMediaEnd: { [eventLog] m in eventLog.log("mediaEnd", m.title ?? m.jsonUrl) },
            onFirstPlayerMedia: { [eventLog] m in eventLog.log("firstPlayerMedia", m.title ?? m.jsonUrl) },
            onPlayerEvent: { [eventLog] e in if e.type != "timeupdate" { eventLog.log("playerEvent", e.type) } },
            onPlayerStateChange: { [eventLog] e in eventLog.log("playerState", e.state) },
            onTimeUpdate: { [eventLog] e in
                let sec = Int(e.currentTime)
                if sec % 10 == 0 && sec != eventLog.lastLoggedSecond {
                    eventLog.lastLoggedSecond = sec
                    eventLog.log("timeUpdate", "\(sec)s / \(Int(e.duration))s")
                }
            },
            onClipLoaded: { [eventLog] e in eventLog.log("clipLoaded", "\(e.raw)".prefix(80).description) },
            onAdStart: { [eventLog] e in eventLog.log("adStart", "\(e.raw)") },
            onAdEnd: { [eventLog] e in eventLog.log("adEnd", "\(e.raw)") },
            onPlayersChange: { [eventLog] p in eventLog.log("playersChange", "\(p.count) players") },
            onActivePlayerChange: { [eventLog] id in eventLog.log("activePlayerChange", id ?? "none") },
            onAnalyticsEvent: { [eventLog] e in
                if ["st","fn","xst","xit","xcl","pa","rs","se","pg"].contains(e.eventCode) {
                    eventLog.log("analytics:\(e.eventCode)", "\(e.properties)".prefix(80).description)
                }
            },
            onExternalLink: { [eventLog] url in eventLog.log("externalLink", url) }
        )
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // App header — pinned, always visible
                appHeader
                    .zIndex(1)

                if showSettings {
                    SettingsPanelView(settings: $settings)
                }

                // Channel with integrated native player — fills remaining space
                BBChannelWithPlayerView(
                    channelUrl: channelUrl,
                    options: channelOptions,
                    viewModel: playerVM,
                    callbacks: callbacks
                )
                .frame(maxHeight: .infinity)

                EventInspectorView(eventLog: eventLog, onClear: { eventLog.clear() })
                    .frame(height: 160)
            }
        }
        .background(Colors.dark)
        .onAppear {
            if let decoded = try? JSONDecoder().decode(ChannelSettings.self, from: settingsData) {
                settings = decoded
            }
        }
    }

    private var appHeader: some View {
        HStack(spacing: 8) {
            Button { onBack() } label: {
                Image(systemName: "chevron.left").foregroundColor(.white)
            }.padding(8)
            Spacer()
            Text(channelName)
                .foregroundColor(.white).font(.system(size: 14)).lineLimit(1)
            Spacer()
            Button {
                if let url = URL(string: channelUrl.replacingOccurrences(of: ".json", with: ".html")) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("WEB").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
            }
            CastButtonView(tintColor: .white).frame(width: 24, height: 24)
            Button { showSettings.toggle() } label: {
                Image(systemName: "gear")
                    .foregroundColor(showSettings ? Colors.accent : .white)
            }.padding(8)
        }
        .padding(.horizontal, 4)
        .background(Color.black)
    }
}
