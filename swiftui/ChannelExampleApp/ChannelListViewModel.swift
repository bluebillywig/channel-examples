import Foundation

@MainActor
class ChannelListViewModel: ObservableObject {
    @Published var channels: [String: [ChannelItem]] = [:]
    @Published var loading = true
    @Published var error: String?

    private var publications: [Publication]

    init(publications: [Publication]) {
        self.publications = publications
    }

    func updatePublications(_ pubs: [Publication]) {
        self.publications = pubs
    }

    func load(isRefresh: Bool = false) async {
        if !isRefresh { loading = true }
        error = nil

        await withTaskGroup(of: (String, Result<[ChannelItem], Error>).self) { group in
            for pub in publications {
                group.addTask {
                    do {
                        let items = try await Self.fetchChannels(host: pub.host)
                        return (pub.key, .success(items))
                    } catch {
                        return (pub.key, .failure(error))
                    }
                }
            }

            var result: [String: [ChannelItem]] = [:]
            var errors: [String] = []

            for await (key, outcome) in group {
                switch outcome {
                case .success(let items):
                    result[key] = items
                case .failure(let err):
                    errors.append("\(key): \(err.localizedDescription)")
                }
            }

            // On refresh: merge successes into existing data (keep old on failure)
            // On initial load: replace entirely
            if isRefresh {
                for (key, items) in result {
                    channels[key] = items
                }
            } else {
                channels = result
            }
            if !errors.isEmpty && channels.isEmpty {
                self.error = errors.joined(separator: "; ")
            }
        }

        loading = false
    }

    private static func fetchChannels(host: String) async throws -> [ChannelItem] {
        guard let url = URL(string: "https://\(host)/papi/search?className=Channel&limit=1000&sort=createddate+desc") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct APIResponse: Codable {
            let items: [ChannelItem]?
        }

        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        return decoded.items ?? []
    }
}
