import Foundation

// Curated demo channels — replace with your own publication and channel IDs.

struct DemoChannel: Identifiable {
    let name: String
    let url: String
    var id: String { url }
}

let DEMO_CHANNELS: [DemoChannel] = [
    DemoChannel(name: "Demo Channel", url: "https://demo.bbvms.com/ch/1152.json"),
]

struct ChannelSettings: Codable, Equatable {
    var autoPlay: Bool = true
    var noStats: Bool = false
    var jwt: String = ""

    static let `default` = ChannelSettings()
}

struct EventEntry: Identifiable {
    let id: Int
    let time: String
    let type: String
    let category: EventCategory
    let summary: String
    let detail: String?
}

enum EventCategory: String {
    case lifecycle, navigation, player, error, analytics
}
