import Foundation
import Combine

// Steam Store Search API から返ってくるゲーム1件
struct SteamGame: Identifiable, Decodable {
    let id: Int
    let name: String
    let tinyImage: String

    // header.jpg は 460×215px の高品質サムネイル
    var headerImageURL: String {
        "https://cdn.cloudflare.steamstatic.com/steam/apps/\(id)/header.jpg"
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case tinyImage = "tiny_image"
    }
}

private struct SteamSearchResponse: Decodable {
    let total: Int
    let items: [SteamGame]
}

@MainActor
class GameSearchService: ObservableObject {
    @Published var results: [SteamGame] = []
    @Published var isLoading = false

    private var searchTask: Task<Void, Never>?

    /// クエリで Steam ゲームを検索（0.4秒デバウンス付き）
    func search(query: String) {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            isLoading = false
            return
        }

        isLoading = true

        searchTask = Task {
            // 入力が止まるまで待つ（デバウンス）
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }

            do {
                let encoded = trimmed.addingPercentEncoding(
                    withAllowedCharacters: .urlQueryAllowed
                ) ?? trimmed
                let url = URL(string:
                    "https://store.steampowered.com/api/storesearch/?term=\(encoded)&l=english&cc=US"
                )!
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(SteamSearchResponse.self, from: data)

                guard !Task.isCancelled else { return }
                self.results = response.items
                self.isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                self.results = []
                self.isLoading = false
            }
        }
    }

    func clear() {
        searchTask?.cancel()
        results = []
        isLoading = false
    }
}

