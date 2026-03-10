import SwiftUI

struct ContentView: View {
    @StateObject private var store = GameStore()

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
                    .environmentObject(store)
            }
            .tabItem { Label("ホーム", systemImage: "house.fill") }

            NavigationStack {
                RankingView()
                    .environmentObject(store)
            }
            .tabItem { Label("ランキング", systemImage: "trophy.fill") }

            NavigationStack {
                CharacterView()
            }
            .tabItem { Label("キャラクター", systemImage: "face.smiling.inverse") }

            NavigationStack {
                StatsView()
                    .environmentObject(store)
            }
            .tabItem { Label("統計", systemImage: "chart.bar.fill") }
        }
        .tint(Color(hex: "5B8DEF"))
    }
}

// MARK: - キャラクタープレースホルダー

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
        .navigationTitle("キャラクター")
    }
}

