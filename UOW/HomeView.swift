import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: GameStore
    @State private var selectedGame: Game?
    @State private var showAddGame = false
    @State private var showMonitoring = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "FAF7F2").ignoresSafeArea()

            VStack(spacing: 0) {
                // ナビゲーションヘッダー
                HStack {
                    Text("ゲームを選択")
                        .font(.title2.bold())
                    Image(systemName: "location.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                    Spacer()
                    Button {
                        showAddGame = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // セクションヘッダー
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "E87575"))
                                .frame(width: 4, height: 22)
                            Text("マイゲーム")
                                .font(.headline.bold())
                        }
                        .padding(.horizontal, 20)

                        // ゲームカードリスト
                        if store.games.isEmpty {
                            EmptyGameView(onAdd: { showAddGame = true })
                                .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(store.games) { game in
                                    GameCardView(
                                        game: game,
                                        isSelected: selectedGame?.id == game.id
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedGame = game
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                    }
                    .padding(.bottom, 120)
                }
            }

            // 計測を開始するボタン（固定底部）
            VStack(spacing: 0) {
                Button {
                    showMonitoring = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                        Text("計測を開始する")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(selectedGame != nil
                                  ? Color(hex: "8ECFB0")
                                  : Color(hex: "B0C9BF"))
                    )
                }
                .disabled(selectedGame == nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .background(
                Color(hex: "FAF7F2")
                    .shadow(color: .black.opacity(0.06), radius: 10, y: -4)
            )
        }
        .fullScreenCover(isPresented: $showMonitoring) {
            MonitoringView(game: selectedGame)
                    .environmentObject(store)
        }
        .sheet(isPresented: $showAddGame) {
            AddGameView(myGames: $store.games)
        }
    }
}

// MARK: - ゲームカード

struct GameCardView: View {
    let game: Game
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 16) {
                // ゲームサムネイル
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black)
                        .frame(width: 80, height: 80)
                    Image(systemName: game.imageName)
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }

                // ゲーム情報
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.name)
                        .font(.title3.bold())
                    if let avg = game.averageScore {
                        HStack(spacing: 4) {
                            Text("平均イライラ度:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(Int(avg))")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }
                    } else {
                        Text("プレイ記録なし")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "AAAAAA"))
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "8ECFB0") : Color.clear, lineWidth: 2)
            )

            // 右端のアクセントカラー（半楕円）
            Ellipse()
                .fill(game.accentColor)
                .frame(width: 30, height: 56)
                .offset(x: 14)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 空状態ビュー

struct EmptyGameView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "CCCCCC"))
            Text("ゲームが登録されていません")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("右上の＋ボタンからゲームを追加してください")
                .font(.caption)
                .foregroundColor(Color(hex: "AAAAAA"))
                .multilineTextAlignment(.center)
            Button {
                onAdd()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("ゲームを追加する")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color(hex: "8ECFB0")))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

#Preview {
    HomeView()
}

