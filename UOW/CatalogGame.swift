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
        GameGenre(name: "格闘",           accentColor: Color(hex: "F5E6A3"), sfSymbol: "figure.martial.arts",     imageURL: "https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=400"),
        GameGenre(name: "RPG",           accentColor: Color(hex: "B8E6C4"), sfSymbol: "shield.fill",             imageURL: "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400"),
    ]

    static let all: [GameGenre] = popular + [
        GameGenre(name: "バトルロイヤル",  accentColor: Color(hex: "F5D5A3"), sfSymbol: "airplane",               imageURL: "https://images.unsplash.com/photo-1585504198199-20277593b94f?w=400"),
        GameGenre(name: "スポーツ",       accentColor: Color(hex: "A3D5F5"), sfSymbol: "sportscourt.fill",        imageURL: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400"),
        GameGenre(name: "パズル",         accentColor: Color(hex: "F5A3D5"), sfSymbol: "puzzlepiece.fill",        imageURL: "https://images.unsplash.com/photo-1606503825008-909a67e63c3d?w=400"),
        GameGenre(name: "ストラテジー",    accentColor: Color(hex: "A3F5D5"), sfSymbol: "brain.head.profile",      imageURL: "https://images.unsplash.com/photo-1553481187-be93c21490a9?w=400"),
        GameGenre(name: "ホラー",         accentColor: Color(hex: "C5A3F5"), sfSymbol: "eye.trianglebadge.exclamationmark", imageURL: "https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=400"),
        GameGenre(name: "レーシング",      accentColor: Color(hex: "F5F5A3"), sfSymbol: "car.fill",                imageURL: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400"),
    ]
}

// Steam App ID から header.jpg URLを生成
private func steamImage(_ appID: Int) -> String {
    "https://cdn.cloudflare.steamstatic.com/steam/apps/\(appID)/header.jpg"
}

// カタログゲームモデル
struct CatalogGame: Identifiable {
    let id = UUID()
    let name: String
    let genre: String
    let imageURL: String

    // MARK: - おすすめ（人気タイトル・Steam画像付き）
    static let recommended: [CatalogGame] = [

        // ── FPS / シューター ──
        CatalogGame(name: "Apex Legends",            genre: "FPS・バトルロイヤル",    imageURL: steamImage(1172470)),
        CatalogGame(name: "VALORANT",                genre: "タクティカルFPS",        imageURL: steamImage(2457320)),
        CatalogGame(name: "Counter-Strike 2",        genre: "タクティカルFPS",        imageURL: steamImage(730)),
        CatalogGame(name: "Overwatch 2",             genre: "チームシューター",        imageURL: steamImage(2357570)),
        CatalogGame(name: "Tom Clancy's Rainbow Six Siege", genre: "タクティカルFPS",  imageURL: steamImage(359550)),
        CatalogGame(name: "PUBG: BATTLEGROUNDS",     genre: "バトルロイヤル",         imageURL: steamImage(578080)),
        CatalogGame(name: "Call of Duty: MW3",       genre: "FPS",                   imageURL: steamImage(2519060)),

        // ── MOBA ──
        CatalogGame(name: "League of Legends",       genre: "MOBA",                  imageURL: ""),
        CatalogGame(name: "Dota 2",                  genre: "MOBA",                  imageURL: steamImage(570)),

        // ── バトルロイヤル / フリープレイ ──
        CatalogGame(name: "フォートナイト",             genre: "バトルロイヤル",         imageURL: ""),
        CatalogGame(name: "Fall Guys",               genre: "パーティー",             imageURL: steamImage(1097150)),

        // ── アクション・RPG ──
        CatalogGame(name: "Elden Ring",              genre: "アクションRPG",          imageURL: steamImage(1245620)),
        CatalogGame(name: "原神",                     genre: "オープンワールドRPG",     imageURL: steamImage(1740360)),
        CatalogGame(name: "モンスターハンターワールド",  genre: "アクションRPG",          imageURL: steamImage(582010)),
        CatalogGame(name: "Cyberpunk 2077",          genre: "オープンワールドRPG",     imageURL: steamImage(1091500)),
        CatalogGame(name: "Grand Theft Auto V",      genre: "オープンワールド",        imageURL: steamImage(271590)),
        CatalogGame(name: "Hades",                   genre: "ローグライク",            imageURL: steamImage(1145360)),
        CatalogGame(name: "Dead by Daylight",        genre: "ホラー・非対称対戦",      imageURL: steamImage(381210)),

        // ── サバイバル / サンドボックス ──
        CatalogGame(name: "Rust",                    genre: "サバイバル",             imageURL: steamImage(252490)),
        CatalogGame(name: "Minecraft",               genre: "サバイバル・サンドボックス", imageURL: ""),
        CatalogGame(name: "Terraria",                genre: "サンドボックス・アクション", imageURL: steamImage(105600)),
        CatalogGame(name: "Stardew Valley",          genre: "農業・RPG",              imageURL: steamImage(413150)),

        // ── 格闘・任天堂 ──
        CatalogGame(name: "大乱闘スマッシュブラザーズ", genre: "格闘",                  imageURL: ""),
        CatalogGame(name: "ストリートファイター6",       genre: "格闘",                  imageURL: steamImage(1794960)),
        CatalogGame(name: "鉄拳8",                   genre: "格闘",                  imageURL: steamImage(1681750)),

        // ── スポーツ ──
        CatalogGame(name: "EA SPORTS FC 24",         genre: "サッカー",               imageURL: steamImage(2195250)),
        CatalogGame(name: "NBA 2K24",                genre: "バスケットボール",        imageURL: steamImage(2338770)),

        // ── インディー・その他 ──
        CatalogGame(name: "Hollow Knight",           genre: "アクション・メトロイドバニア", imageURL: steamImage(367520)),
        CatalogGame(name: "Among Us",                genre: "パーティー・推理",        imageURL: steamImage(945360)),
        CatalogGame(name: "Team Fortress 2",         genre: "チームシューター",        imageURL: steamImage(440)),
    ]

    // ジャンルでフィルタリング
    static func filtered(by genre: GameGenre) -> [CatalogGame] {
        recommended.filter { $0.genre.localizedCaseInsensitiveContains(genre.name) }
    }
}

