import Foundation
import Combine

class GameStore: ObservableObject {
    @Published var games: [Game] = []

    private let saveKey = "saved_games"

    init() {
        load()
    }

    func save() {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Game].self, from: data) else { return }
        games = decoded
    }

    func addSession(_ session: GameSession, to gameID: UUID) {
        guard let idx = games.firstIndex(where: { $0.id == gameID }) else { return }
        games[idx].sessions.append(session)
        save()
    }

    func addGame(_ game: Game) {
        guard !games.contains(where: { $0.name == game.name }) else { return }
        games.append(game)
        save()
    }
}

