import SwiftUI

struct ContentView: View {
    @StateObject private var store = GameStore()

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(store)
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            RankingView()
                .tabItem {
                    Label("ランキング", systemImage: "trophy.fill")
                }

            CharacterView()
                .tabItem {
                    Label("キャラクター", systemImage: "face.smiling.inverse")
                }

            StatsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar.fill")
                }
        }
        .tint(Color(hex: "5B8DEF"))
    }
}

// MARK: - プレースホルダー画面

struct RankingView: View {
    var body: some View {
        ZStack {
            Color(hex: "FAF7F2").ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "E8B84B"))
                Text("ランキング")
                    .font(.title2.bold())
                Text("Coming Soon")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CharacterView: View {
    var body: some View {
        ZStack {
            Color(hex: "FAF7F2").ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "face.smiling.inverse")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "8ECFB0"))
                Text("キャラクター")
                    .font(.title2.bold())
                Text("Coming Soon")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StatsView: View {
    var body: some View {
        ZStack {
            Color(hex: "FAF7F2").ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "5B8DEF"))
                Text("統計")
                    .font(.title2.bold())
                Text("Coming Soon")
                    .foregroundColor(.secondary)
            }
        }
    }
}

