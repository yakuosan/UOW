import SwiftUI

struct AddGameView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var searchService = GameSearchService()
    @State private var searchText = ""
    @State private var showAllGenres = false
    @State private var selectedGenre: GameGenre? = nil
    @State private var showManualEntry = false

    // 検索中かどうか
    private var isSearching: Bool { !searchText.isEmpty }

    // カタログのフィルタリング（ジャンル選択のみ、テキスト検索はSteamに任せる）
    private var catalogGames: [CatalogGame] {
        guard let genre = selectedGenre else { return CatalogGame.recommended }
        return CatalogGame.recommended.filter {
            $0.genre.localizedCaseInsensitiveContains(genre.name)
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
                                .onChange(of: searchText) { _, newValue in
                                    if newValue.isEmpty {
                                        searchService.clear()
                                        selectedGenre = nil
                                    } else {
                                        searchService.search(query: newValue)
                                    }
                                }
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                    searchService.clear()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        .padding(.horizontal, 20)

                        if isSearching {
                            // ── Steam 検索結果 ──
                            SteamSearchResultsSection(
                                results: searchService.results,
                                isLoading: searchService.isLoading,
                                addedNames: Set(store.games.map(\.name))
                            ) { steamGame in
                                store.addGame(Game(
                                    name: steamGame.name,
                                    imageName: "gamecontroller.fill",
                                    imageURL: steamGame.headerImageURL
                                ))
                            }
                        } else {
                            // ── ジャンルグリッド ──
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    SectionHeader(title: "人気のゲーム")
                                    Spacer()
                                    Button("すべて見る") { showAllGenres = true }
                                        .font(.subheadline)
                                        .foregroundColor(Color(hex: "8ECFB0"))
                                }
                                .padding(.horizontal, 20)

                                LazyVGrid(
                                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                                    spacing: 12
                                ) {
                                    ForEach(GameGenre.popular) { genre in
                                        GenreCategoryCard(
                                            genre: genre,
                                            isSelected: selectedGenre?.id == genre.id
                                        )
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedGenre = selectedGenre?.id == genre.id ? nil : genre
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            // ── カタログ ──
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    SectionHeader(title: selectedGenre != nil
                                                  ? "\(selectedGenre!.name)のゲーム"
                                                  : "おすすめ")
                                    Spacer()
                                    if selectedGenre != nil {
                                        Button("クリア") {
                                            withAnimation { selectedGenre = nil }
                                        }
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "8ECFB0"))
                                    }
                                }
                                .padding(.horizontal, 20)

                                VStack(spacing: 0) {
                                    ForEach(catalogGames) { game in
                                        CatalogGameRow(
                                            game: game,
                                            isAdded: store.games.contains { $0.name == game.name }
                                        ) {
                                            store.addGame(Game(
                                                name: game.name,
                                                imageName: "gamecontroller.fill",
                                                imageURL: game.imageURL.isEmpty ? nil : game.imageURL
                                            ))
                                        }
                                        if game.id != catalogGames.last?.id {
                                            Divider().padding(.leading, 76)
                                        }
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                                .padding(.horizontal, 20)

                                // 手動登録ボタン
                                Button { showManualEntry = true } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "pencil.circle.fill")
                                        Text("ゲームが見つからない場合は手動で登録")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(Color(hex: "8ECFB0"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                                }
                                .padding(.horizontal, 20)
                            }
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
            .sheet(isPresented: $showManualEntry) {
                ManualGameEntrySheet { name in
                    store.addGame(Game(
                        name: name,
                        imageName: "gamecontroller.fill"
                    ))
                    showManualEntry = false
                }
            }
        }
    }
}

// MARK: - 手動登録シート

struct ManualGameEntrySheet: View {
    let onAdd: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var gameName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FAF7F2").ignoresSafeArea()
                VStack(spacing: 28) {
                    // アイコン
                    ZStack {
                        Circle()
                            .fill(Color(hex: "EEF9F4"))
                            .frame(width: 80, height: 80)
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "8ECFB0"))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ゲーム名")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        TextField("例: マリオカート、ポケモンSV", text: $gameName)
                            .font(.body)
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }
                    .padding(.horizontal, 24)

                    Text("Steamにないゲームや、コンシューマー機のゲームはこちらから登録できます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Spacer()
                }
                .padding(.top, 36)
            }
            .navigationTitle("手動でゲームを登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") {
                        let trimmed = gameName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onAdd(trimmed)
                    }
                    .fontWeight(.bold)
                    .disabled(gameName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Steam 検索結果セクション

struct SteamSearchResultsSection: View {
    let results: [SteamGame]
    let isLoading: Bool
    let addedNames: Set<String>
    let onAdd: (SteamGame) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Steam 検索結果")
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 20)

            if !isLoading && results.isEmpty {
                Text("ゲームが見つかりませんでした")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(results) { game in
                        SteamGameRow(
                            game: game,
                            isAdded: addedNames.contains(game.name)
                        ) {
                            onAdd(game)
                        }
                        if game.id != results.last?.id {
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
    }
}

// MARK: - Steam ゲーム行

struct SteamGameRow: View {
    let game: SteamGame
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // header.jpg（460×215）をサムネイルとして使用
            AsyncImage(url: URL(string: game.headerImageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    ZStack {
                        Color.black
                        Image(systemName: "gamecontroller.fill")
                            .foregroundColor(.white)
                    }
                default:
                    ZStack {
                        Color(hex: "EEEBE6")
                        ProgressView().scaleEffect(0.7)
                    }
                }
            }
            .frame(width: 56, height: 56)
            .cornerRadius(10)
            .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text(game.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("Steam")
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
    var isSelected: Bool = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 2)

            VStack(spacing: 0) {
                ZStack {
                    genre.accentColor.opacity(0.18)
                    if let url = URL(string: genre.imageURL), !genre.imageURL.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image): image.resizable().scaledToFill()
                            default: genreIcon
                            }
                        }
                    } else {
                        genreIcon
                    }
                }
                .frame(height: 88)
                .clipped()

                ZStack(alignment: .trailing) {
                    HStack {
                        Text(genre.name)
                            .font(.headline.bold())
                            .padding(.leading, 12)
                        Spacer()
                    }
                    .frame(height: 48)
                    .background(Color.white)

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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? genre.accentColor : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isSelected ? 0.96 : 1.0)
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

// MARK: - カタログゲーム行

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

