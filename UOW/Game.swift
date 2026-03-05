import Foundation
import SwiftUI

struct Game: Identifiable, Codable {
    let id: UUID
    var name: String
    var imageName: String
    var sessions: [GameSession]

    init(name: String, imageName: String) {
        self.id = UUID()
        self.name = name
        self.imageName = imageName
        self.sessions = []
    }

    // 過去セッションの平均スコア（セッションなしはnil）
    var averageScore: Double? {
        guard !sessions.isEmpty else { return nil }
        return sessions.map(\.peakScore).reduce(0, +) / Double(sessions.count)
    }

    var accentColor: Color {
        guard let avg = averageScore else { return Color(hex: "D0D0D0") }
        switch avg {
        case 0...30:  return Color(hex: "B8E6C4")
        case 31...60: return Color(hex: "F5C5C5")
        case 61...80: return Color(hex: "F5E6A3")
        default:      return Color(hex: "F5A5A5")
        }
    }
}

// サンプルデータ（sessions空 = プレイ記録なし）
extension Game {
    static let samples: [Game] = [
        {
            var g = Game(name: "スマブラ", imageName: "figure.martial.arts")
            g.sessions = [
                GameSession(peakScore: 75, wordCount: 8, impactCount: 3),
                GameSession(peakScore: 65, wordCount: 5, impactCount: 2),
            ]
            return g
        }(),
        Game(name: "valorant", imageName: "scope"),
    ]
}

