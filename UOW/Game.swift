import Foundation
import SwiftUI

struct Game: Identifiable, Codable {
    let id: UUID
    var name: String
    var imageName: String
    var imageURL: String?        // Steam等から取得した実際の画像URL
    var sessions: [GameSession]

    init(name: String, imageName: String = "gamecontroller.fill", imageURL: String? = nil) {
        self.id = UUID()
        self.name = name
        self.imageName = imageName
        self.imageURL = imageURL
        self.sessions = []
    }

    // 旧データ（imageURLなし）でもデコードできるよう明示的に実装
    enum CodingKeys: String, CodingKey {
        case id, name, imageName, imageURL, sessions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id       = try c.decode(UUID.self,          forKey: .id)
        name     = try c.decode(String.self,         forKey: .name)
        imageName = try c.decode(String.self,        forKey: .imageName)
        imageURL = try c.decodeIfPresent(String.self, forKey: .imageURL)
        sessions = try c.decode([GameSession].self,  forKey: .sessions)
    }

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

