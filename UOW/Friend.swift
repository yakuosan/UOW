//
//  Friend.swift
//  UOW
//
//  Created by 阪上八雲 on 2026/03/09.
//

import Foundation

struct Friend: Identifiable, Codable {
    let id: UUID
    var name: String
    var avgStress: Int
    var sessionCount: Int
    var addedAt: Date

    init(name: String, avgStress: Int, sessionCount: Int) {
        self.id = UUID()
        self.name = name
        self.avgStress = avgStress
        self.sessionCount = sessionCount
        self.addedAt = Date()
    }
}

// フレンドコードとしてやり取りするデータ
struct FriendShareCard: Codable {
    let name: String
    let avgStress: Int
    let sessionCount: Int
}

enum FriendError: LocalizedError {
    case invalidCode
    case alreadyAdded

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "コードが正しくありません"
        case .alreadyAdded: return "すでに追加されています"
        }
    }
}
