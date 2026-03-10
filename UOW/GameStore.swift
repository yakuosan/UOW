import Foundation
import Combine

class GameStore: ObservableObject {
    @Published var games: [Game] = []
    @Published var friends: [Friend] = []
    @Published var myDisplayName: String = "あなた"

    private let gamesKey   = "saved_games"
    private let friendsKey = "saved_friends"
    private let nameKey    = "my_display_name"

    init() {
        loadGames()
        loadFriends()
        myDisplayName = UserDefaults.standard.string(forKey: nameKey) ?? "あなた"
    }

    // MARK: - Games

    func save() {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: gamesKey)
        }
    }

    private func loadGames() {
        guard let data = UserDefaults.standard.data(forKey: gamesKey),
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

    // MARK: - Display Name

    func setDisplayName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        myDisplayName = trimmed
        UserDefaults.standard.set(trimmed, forKey: nameKey)
    }

    // MARK: - Friends

    /// 自分の現在のスタッツをbase64コードとして生成
    func generateMyCode() -> String {
        let all = games.flatMap(\.sessions)
        let avg = all.isEmpty ? 0 : Int(all.map(\.peakScore).reduce(0, +) / Double(all.count))
        let card = FriendShareCard(name: myDisplayName, avgStress: avg, sessionCount: all.count)
        let data = (try? JSONEncoder().encode(card)) ?? Data()
        return data.base64EncodedString()
    }

    /// コードからフレンドを追加
    func addFriend(from code: String) throws {
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard let data = Data(base64Encoded: trimmed),
              let card = try? JSONDecoder().decode(FriendShareCard.self, from: data) else {
            throw FriendError.invalidCode
        }
        guard !friends.contains(where: { $0.name == card.name }) else {
            throw FriendError.alreadyAdded
        }
        friends.append(Friend(name: card.name, avgStress: card.avgStress, sessionCount: card.sessionCount))
        saveFriends()
    }

    func removeFriend(id: UUID) {
        friends.removeAll { $0.id == id }
        saveFriends()
    }

    private func saveFriends() {
        if let data = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(data, forKey: friendsKey)
        }
    }

    private func loadFriends() {
        guard let data = UserDefaults.standard.data(forKey: friendsKey),
              let decoded = try? JSONDecoder().decode([Friend].self, from: data) else { return }
        friends = decoded
    }
}

