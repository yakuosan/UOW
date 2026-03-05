//
//  GameSession.swift
//  UOW
//
//  Created by 阪上八雲 on 2026/03/06.
//

import Foundation

struct GameSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let peakScore: Double   // セッション中の最高スコア
    let wordCount: Int
    let impactCount: Int

    init(peakScore: Double, wordCount: Int, impactCount: Int) {
        self.id = UUID()
        self.date = Date()
        self.peakScore = peakScore
        self.wordCount = wordCount
        self.impactCount = impactCount
    }
}
