//
//  CatalogGame.swift
//  UOW
//
//  Created by 阪上八雲 on 2026/03/05.
//

import SwiftUI

// ゲームカタログのカテゴリ
struct GameGenre: Identifiable {
    let id = UUID()
    let name: String
    let accentColor: Color
    let sfSymbol: String
    let imageURL: String

    static let popular: [GameGenre] = [
        GameGenre(name: "FPS",           accentColor: Color(hex: "F5C5C5"), sfSymbol: "scope",                   imageURL: "https://images.unsplash.com/photo-1542751371-adc38448a05e?w=400"),
        GameGenre(name: "MOBA",          accentColor: Color(hex: "D4C5F5"), sfSymbol: "map.fill",                imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=400"),
        GameGenre(name: "fight",         accentColor: Color(hex: "F5E6A3"), sfSymbol: "figure.martial.arts",     imageURL: "https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=400"),
        GameGenre(name: "RPG",           accentColor: Color(hex: "B8E6C4"), sfSymbol: "shield.fill",             imageURL: "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400"),
    ]

    static let all: [GameGenre] = popular + [
        GameGenre(name: "Battle Royale", accentColor: Color(hex: "F5D5A3"), sfSymbol: "airplane",               imageURL: "https://images.unsplash.com/photo-1585504198199-20277593b94f?w=400"),
        GameGenre(name: "Sports",        accentColor: Color(hex: "A3D5F5"), sfSymbol: "sportscourt.fill",        imageURL: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400"),
        GameGenre(name: "Puzzle",        accentColor: Color(hex: "F5A3D5"), sfSymbol: "puzzlepiece.fill",        imageURL: "https://images.unsplash.com/photo-1606503825008-909a67e63c3d?w=400"),
        GameGenre(name: "Strategy",      accentColor: Color(hex: "A3F5D5"), sfSymbol: "brain.head.profile",      imageURL: "https://images.unsplash.com/photo-1553481187-be93c21490a9?w=400"),
        GameGenre(name: "Horror",        accentColor: Color(hex: "C5A3F5"), sfSymbol: "eye.trianglebadge.exclamationmark", imageURL: "https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=400"),
        GameGenre(name: "Racing",        accentColor: Color(hex: "F5F5A3"), sfSymbol: "car.fill",                imageURL: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400"),
    ]
}

// カタログゲームモデル
struct CatalogGame: Identifiable {
    let id = UUID()
    let name: String
    let genre: String
    let imageURL: String

    static let recommended: [CatalogGame] = [
        CatalogGame(name: "Apex Legends",          genre: "アクション・FPS",        imageURL: "https://cdn.cloudflare.steamstatic.com/steam/apps/1172470/header.jpg"),
        CatalogGame(name: "VALORANT",              genre: "タクティカル・FPS",       imageURL: "https://cdn.cloudflare.steamstatic.com/steam/apps/2457320/header.jpg"),
        CatalogGame(name: "スマッシュブラザーズ",     genre: "格闘・fight",            imageURL: ""),
        CatalogGame(name: "League of Legends",     genre: "MOBA",                  imageURL: ""),
        CatalogGame(name: "原神",                   genre: "RPG・オープンワールド",    imageURL: ""),
        CatalogGame(name: "Overwatch 2",           genre: "チームシューター・FPS",    imageURL: "https://cdn.cloudflare.steamstatic.com/steam/apps/2357570/header.jpg"),
        CatalogGame(name: "フォートナイト",           genre: "バトルロイヤル・FPS",     imageURL: ""),
        CatalogGame(name: "Minecraft",             genre: "サバイバル・RPG",         imageURL: ""),
    ]
}
