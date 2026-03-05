import SwiftUI

struct AddGameView: View {
    @Binding var myGames: [Game]
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var showAllGenres = false

    private var filteredGames: [CatalogGame] {
        if searchText.isEmpty { return CatalogGame.recommended }
        return CatalogGame.recommended.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.genre.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FAF7F2").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // 検索バー
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("ゲームを検索...", text: $searchText)
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        .padding(.horizontal, 20)

                        if searchText.isEmpty {
                            // 人気のゲームカテゴリ
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    SectionHeader(title: "人気のゲーム")
                                    Spacer()
                                    Button("すべて見る") {
                                        showAllGenres = true
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "8ECFB0"))
                                }
                                .padding(.horizontal, 20)

                                LazyVGrid(
                                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                                    spacing: 12
                                ) {
                                    ForEach(GameGenre.popular) { genre in
                                        GenreCategoryCard(genre: genre)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // おすすめ / 検索結果
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: searchText.isEmpty ? "おすすめ" : "検索結果")
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(filteredGames) { game in
                                    CatalogGameRow(
                                        game: game,
                                        isAdded: myGames.contains { $0.name == game.name }
                                    ) {
                                        addGame(game)
                                    }
                                    if game.id != filteredGames.last?.id {
                                        Divider().padding(.leading, 76)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("ゲームを登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationDestination(isPresented: $showAllGenres) {
                AllGenresView()
            }
        }
    }

    private func addGame(_ catalogGame: CatalogGame) {
        guard !myGames.contains(where: { $0.name == catalogGame.name }) else { return }
        withAnimation {
            myGames.append(Game(
                name: catalogGame.name,
                imageName: "gamecontroller.fill",
            ))
        }
    }
}

// MARK: - すべてのジャンル画面

struct AllGenresView: View {
    var body: some View {
        ZStack {
            Color(hex: "FAF7F2").ignoresSafeArea()
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    ForEach(GameGenre.all) { genre in
                        GenreCategoryCard(genre: genre)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("全ジャンル")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - カテゴリカード（画像付き）

struct GenreCategoryCard: View {
    let genre: GameGenre

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 2)

            VStack(spacing: 0) {
                // 上部: 画像エリア
                ZStack {
                    genre.accentColor.opacity(0.18)
                    if let url = URL(string: genre.imageURL), !genre.imageURL.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                genreIcon
                            }
                        }
                    } else {
                        genreIcon
                    }
                }
                .frame(height: 88)
                .clipped()

                // 下部: ジャンル名 + アクセント
                ZStack(alignment: .trailing) {
                    HStack {
                        Text(genre.name)
                            .font(.headline.bold())
                            .padding(.leading, 12)
                        Spacer()
                    }
                    .frame(height: 48)
                    .background(Color.white)

                    // 右端アクセント半楕円
                    Ellipse()
                        .fill(genre.accentColor)
                        .frame(width: 28, height: 52)
                        .offset(x: 13)
                }
                .clipShape(Rectangle())
            }
        }
        .frame(height: 136)
        .cornerRadius(16)
        .clipped()
    }

    private var genreIcon: some View {
        Image(systemName: genre.sfSymbol)
            .font(.system(size: 38))
            .foregroundColor(genre.accentColor)
    }
}

// MARK: - セクションヘッダー

struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "E87575"))
                .frame(width: 4, height: 20)
            Text(title)
                .font(.headline.bold())
        }
    }
}

// MARK: - ゲームリスト行

struct CatalogGameRow: View {
    let game: CatalogGame
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            GameThumbnail(imageURL: game.imageURL)
                .frame(width: 56, height: 56)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(game.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(game.genre)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()

            Button {
                if !isAdded { onAdd() }
            } label: {
                ZStack {
                    Circle()
                        .fill(isAdded ? Color.gray.opacity(0.2) : Color(hex: "8ECFB0"))
                        .frame(width: 32, height: 32)
                    Image(systemName: isAdded ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isAdded ? .gray : .white)
                }
            }
            .disabled(isAdded)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - サムネイル

struct GameThumbnail: View {
    let imageURL: String

    var body: some View {
        if !imageURL.isEmpty, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                default: placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.black
            Image(systemName: "gamecontroller.fill")
                .foregroundColor(.white).font(.title3)
        }
    }
}

