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
                StatsView()
                    .environmentObject(store)
            }
            .tabItem { Label("統計", systemImage: "chart.bar.fill") }
        }
        .tint(Color(hex: "5B8DEF"))
    }
}

