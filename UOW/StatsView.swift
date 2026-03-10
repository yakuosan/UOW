import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: GameStore
    @State private var showGameRecords = false

    var body: some View {
        ZStack {
            Color(hex: "FAF7F2").ignoresSafeArea()
            if showGameRecords {
                GameRecordsPanel()
                    .environmentObject(store)
            } else {
                StatsMainPanel()
                    .environmentObject(store)
            }
        }
        .navigationTitle("グラフ")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showGameRecords.toggle()
                    }
                } label: {
                    Image(systemName: showGameRecords ? "chart.bar.fill" : "square.grid.2x2.fill")
                        .foregroundColor(Color(hex: "8ECFB0"))
                }
            }
        }
    }
}

// MARK: - メインパネル

struct StatsMainPanel: View {
    @EnvironmentObject var store: GameStore
    @State private var selectedDayIndex = 6   // 今日 = 常に最後のインデックス
    @State private var showMonthlyReport = false

    private var allSessions: [GameSession] {
        store.games.flatMap(\.sessions)
    }

    private var totalWords: Int {
        allSessions.reduce(0) { $0 + $1.wordCount }
    }

    private var totalImpacts: Int {
        allSessions.reduce(0) { $0 + $1.impactCount }
    }

    // 過去7日の日付（index 0 = 6日前, index 6 = 今日）
    private var weekDates: [Date] {
        (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: -6 + $0, to: Date())
        }
    }

    // 各日付に対応する曜日ラベル（実際の日付から算出）
    private var weekDayLabels: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"   // 日, 月, 火, 水, 木, 金, 土
        return weekDates.map { formatter.string(from: $0) }
    }

    // 各日のセッション平均スコア（0〜1スケール）
    private var barData: [Double] {
        weekDates.map { date in
            let sessions = allSessions.filter {
                Calendar.current.isDate($0.date, inSameDayAs: date)
            }
            guard !sessions.isEmpty else { return 0 }
            let avg = sessions.map(\.peakScore).reduce(0, +) / Double(sessions.count)
            return avg / 100.0
        }
    }

    // セッションがある日かどうか
    private var hasSessionOnDay: [Bool] {
        weekDates.map { date in
            allSessions.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
        }
    }

    // 選択した日のセッション一覧
    private var selectedDaySessions: [(Game, GameSession)] {
        guard selectedDayIndex < weekDates.count else { return [] }
        let date = weekDates[selectedDayIndex]
        return store.games.flatMap { game in
            game.sessions
                .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
                .map { (game, $0) }
        }.sorted { $0.1.date > $1.1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ヘッダー
                HStack {
                    Text("記録")
                        .font(.title2.bold())
                    Spacer()
                    if consecutiveDays > 0 {
                        Text("連続\(consecutiveDays)日")
                            .font(.caption.bold())
                            .foregroundColor(Color(hex: "8ECFB0"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(hex: "8ECFB0").opacity(0.15)))
                    }
                }
                .padding(.horizontal, 20)

                // カレンダー（実際の曜日ラベルを使用）
                WeekCalendarView(
                    weekDayLabels: weekDayLabels,
                    weekDates: weekDates,
                    hasSession: hasSessionOnDay,
                    selectedIndex: $selectedDayIndex
                )
                .padding(.horizontal, 20)

                // 選択した日のセッション（あれば）
                if !selectedDaySessions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedDateLabel)
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            ForEach(selectedDaySessions, id: \.1.id) { game, session in
                                SessionRow(gameName: game.name, session: session)
                                if session.id != selectedDaySessions.last?.1.id {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                        .padding(.horizontal, 20)
                    }
                }

                // カウントカード
                HStack(spacing: 12) {
                    SmallStatCard(
                        icon: "flame.fill",
                        iconColor: Color(hex: "E8A090"),
                        bgColor: Color(hex: "FFF0EE"),
                        title: "暴言の回数",
                        value: "\(totalWords)回"
                    )
                    SmallStatCard(
                        icon: "hand.raised.fill",
                        iconColor: Color(hex: "8ECFB0"),
                        bgColor: Color(hex: "EEF9F4"),
                        title: "台パンの回数",
                        value: "\(totalImpacts)回"
                    )
                }
                .padding(.horizontal, 20)

                // バーチャート（実際の曜日ラベルを使用）
                VStack(alignment: .leading, spacing: 12) {
                    if allSessions.isEmpty {
                        Text("計測するとグラフが表示されます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        BarChartView(
                            barData: barData,
                            days: weekDayLabels,
                            selectedIndex: selectedDayIndex
                        )
                    }

                    HStack(spacing: 16) {
                        LegendItem(color: Color(hex: "F5A87A"), label: "イライラ度（平均）")
                    }

                    HStack {
                        Text(monthString)
                            .font(.subheadline.bold())
                        Spacer()
                        Button("月別レポート") {
                            showMonthlyReport = true
                        }
                        .font(.caption)
                        .foregroundColor(Color(hex: "8ECFB0"))
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                .padding(.horizontal, 20)
            }
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showMonthlyReport) {
            MonthlyReportView()
                .environmentObject(store)
        }
    }

    // 連続記録日数
    private var consecutiveDays: Int {
        var count = 0
        var date = Date()
        while allSessions.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            count += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return count
    }

    // 選択日のラベル
    private var selectedDateLabel: String {
        guard selectedDayIndex < weekDates.count else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: weekDates[selectedDayIndex]) + "の記録"
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
}

// MARK: - ゲーム記録パネル

struct GameRecordsPanel: View {
    @EnvironmentObject var store: GameStore
    @State private var showAllSessions = false

    // 全セッションを日付降順でソート
    private var recentSessions: [(Game, GameSession)] {
        store.games.flatMap { game in
            game.sessions.map { (game, $0) }
        }
        .sorted { $0.1.date > $1.1.date }
    }

    // 今週のセッション（直近7日）
    private var weekSessions: [GameSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return store.games.flatMap(\.sessions).filter { $0.date >= cutoff }
    }

    // 平均イライラ度（全セッション）
    private var avgStress: Double? {
        let all = store.games.flatMap(\.sessions)
        guard !all.isEmpty else { return nil }
        return all.map(\.peakScore).reduce(0, +) / Double(all.count)
    }

    // 今週の合計暴言数
    private var weekWordCount: Int {
        weekSessions.reduce(0) { $0 + $1.wordCount }
    }

    // 今週の合計台パン数
    private var weekImpactCount: Int {
        weekSessions.reduce(0) { $0 + $1.impactCount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("各ゲームの記録")
                    .font(.title2.bold())
                    .padding(.horizontal, 20)

                // 最近の記録
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("最近の記録")
                            .font(.headline.bold())
                        Spacer()
                        Button("すべて見る") {
                            showAllSessions = true
                        }
                        .font(.caption)
                        .foregroundColor(Color(hex: "8ECFB0"))
                    }
                    .padding(.horizontal, 20)

                    if recentSessions.isEmpty {
                        Text("計測するとここに記録が表示されます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(recentSessions.prefix(5), id: \.1.id) { game, session in
                                SessionRow(gameName: game.name, session: session)
                                if session.id != recentSessions.prefix(5).last?.1.id {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                        .padding(.horizontal, 20)
                    }
                }

                // 週間サマリー（実データ）
                VStack(alignment: .leading, spacing: 12) {
                    Text("週間サマリー")
                        .font(.headline.bold())
                        .padding(.horizontal, 20)

                    HStack(spacing: 12) {
                        SummaryCard(
                            title: "平均イライラ度",
                            value: avgStress.map { "\(Int($0))%" } ?? "--",
                            color: Color(hex: "F5A87A")
                        )
                        SummaryCard(
                            title: "今週の暴言",
                            value: weekSessions.isEmpty ? "--" : "\(weekWordCount)回",
                            color: Color(hex: "E87575")
                        )
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 12) {
                        SummaryCard(
                            title: "今週の台パン",
                            value: weekSessions.isEmpty ? "--" : "\(weekImpactCount)回",
                            color: Color(hex: "8ECFB0")
                        )
                        SummaryCard(
                            title: "総セッション数",
                            value: "\(store.games.flatMap(\.sessions).count)回",
                            color: Color(hex: "8EA8CF")
                        )
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showAllSessions) {
            AllSessionsView()
                .environmentObject(store)
        }
    }
}

// MARK: - 全セッション一覧

struct AllSessionsView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss

    private var allSessions: [(Game, GameSession)] {
        store.games.flatMap { game in
            game.sessions.map { (game, $0) }
        }.sorted { $0.1.date > $1.1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FAF7F2").ignoresSafeArea()
                if allSessions.isEmpty {
                    Text("記録がありません")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(allSessions, id: \.1.id) { game, session in
                            SessionRow(gameName: game.name, session: session)
                                .listRowBackground(Color.white)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("すべての記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 週カレンダー

struct WeekCalendarView: View {
    let weekDayLabels: [String]   // 実際の日付から算出した曜日名
    let weekDates: [Date]
    let hasSession: [Bool]
    @Binding var selectedIndex: Int

    private func dayNumber(_ date: Date) -> Int {
        Calendar.current.component(.day, from: date)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<weekDayLabels.count, id: \.self) { i in
                VStack(spacing: 6) {
                    Text(weekDayLabels[i])
                        .font(.caption2)
                        .foregroundColor(dayLabelColor(index: i))
                    ZStack {
                        Circle()
                            .fill(selectedIndex == i ? Color(hex: "8ECFB0") : Color.clear)
                            .frame(width: 32, height: 32)
                        Text("\(dayNumber(weekDates[i]))")
                            .font(.subheadline.bold())
                            .foregroundColor(selectedIndex == i ? .white : .primary)
                    }
                    // セッションがある日はドット
                    Circle()
                        .fill(hasSession[i] ? Color(hex: "F5A87A") : Color.clear)
                        .frame(width: 5, height: 5)
                }
                .frame(maxWidth: .infinity)
                .onTapGesture { selectedIndex = i }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // 土曜=青, 日曜=赤, その他=secondary
    private func dayLabelColor(index: Int) -> Color {
        let weekday = Calendar.current.component(.weekday, from: weekDates[index])
        switch weekday {
        case 1: return Color(hex: "E87575")   // 日曜
        case 7: return Color(hex: "5B8DEF")   // 土曜
        default: return .secondary
        }
    }
}

// MARK: - バーチャート

struct BarChartView: View {
    let barData: [Double]
    let days: [String]
    var selectedIndex: Int = -1

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<barData.count, id: \.self) { i in
                VStack(spacing: 4) {
                    // スコアラベル（データある日のみ）
                    if barData[i] > 0 {
                        Text("\(Int(barData[i] * 100))%")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color(hex: "F5A87A"))
                    }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(index: i))
                        .frame(height: max(4, CGFloat(barData[i]) * 100))
                        .animation(.easeInOut, value: barData[i])
                    Text(days[i])
                        .font(.caption2)
                        .foregroundColor(i == selectedIndex ? Color(hex: "8ECFB0") : .secondary)
                        .fontWeight(i == selectedIndex ? .bold : .regular)
                }
                .frame(maxWidth: .infinity, maxHeight: 120, alignment: .bottom)
            }
        }
    }

    private func barColor(index: Int) -> Color {
        if barData[index] == 0 { return Color(hex: "EEEBE6") }
        if index == selectedIndex { return Color(hex: "F5A87A").opacity(1.0) }
        return Color(hex: "F5A87A").opacity(0.6)
    }
}

// MARK: - セッション行

struct SessionRow: View {
    let gameName: String
    let session: GameSession

    private var scoreColor: Color {
        switch session.peakScore {
        case 0...30:  return Color(hex: "8ECFB0")
        case 31...60: return Color(hex: "F5E6A3")
        case 61...80: return Color(hex: "F5A87A")
        default:      return Color(hex: "E87575")
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: session.date)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: session.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(scoreColor.opacity(0.3))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(gameName)
                    .font(.subheadline.bold())
                HStack(spacing: 8) {
                    Text("\(dateString)  \(timeString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if session.wordCount > 0 || session.impactCount > 0 {
                        Text("暴言\(session.wordCount) / 台パン\(session.impactCount)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.3), lineWidth: 3)
                    .frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: CGFloat(session.peakScore / 100))
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(session.peakScore))%")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - 小パーツ

struct SmallStatCard: View {
    let icon: String
    let iconColor: Color
    let bgColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(bgColor)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.subheadline)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - 月別レポート

struct MonthlyReportView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var displayMonth: Date = Date()

    private let cal = Calendar.current

    // 表示月の開始・終了
    private var monthStart: Date {
        cal.date(from: cal.dateComponents([.year, .month], from: displayMonth))!
    }
    private var monthEnd: Date {
        cal.date(byAdding: .month, value: 1, to: monthStart)!
    }
    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: displayMonth)!.count
    }

    // 表示月のセッション
    private var monthSessions: [(game: Game, session: GameSession)] {
        store.games.flatMap { game in
            game.sessions
                .filter { $0.date >= monthStart && $0.date < monthEnd }
                .map { (game, $0) }
        }.sorted { $0.session.date < $1.session.date }
    }

    private var sessions: [GameSession] { monthSessions.map(\.session) }

    // サマリー統計
    private var sessionCount: Int { sessions.count }
    private var avgStress: Double? {
        guard !sessions.isEmpty else { return nil }
        return sessions.map(\.peakScore).reduce(0, +) / Double(sessions.count)
    }
    private var peakStress: Int {
        Int(sessions.map(\.peakScore).max() ?? 0)
    }
    private var totalWords: Int   { sessions.reduce(0) { $0 + $1.wordCount } }
    private var totalImpacts: Int { sessions.reduce(0) { $0 + $1.impactCount } }

    // 日別平均スコア（1始まり、index 0 = 1日）
    private var dailyAvg: [Double] {
        (1...daysInMonth).map { day in
            let daySessions = sessions.filter {
                cal.component(.day, from: $0.date) == day
            }
            guard !daySessions.isEmpty else { return 0 }
            return daySessions.map(\.peakScore).reduce(0, +) / Double(daySessions.count)
        }
    }

    // ゲーム別統計（イライラ度降順）
    private var gameStats: [(name: String, avg: Double, count: Int)] {
        store.games.compactMap { game in
            let s = game.sessions.filter { $0.date >= monthStart && $0.date < monthEnd }
            guard !s.isEmpty else { return nil }
            let avg = s.map(\.peakScore).reduce(0, +) / Double(s.count)
            return (game.name, avg, s.count)
        }.sorted { $0.avg > $1.avg }
    }

    // 月ラベル
    private var monthLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f.string(from: displayMonth)
    }

    // 未来月への移動を禁止
    private var canGoNext: Bool {
        guard let next = cal.date(byAdding: .month, value: 1, to: displayMonth) else { return false }
        return next <= Date()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FAF7F2").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        // 月ナビゲーター
                        HStack {
                            Button {
                                displayMonth = cal.date(byAdding: .month, value: -1, to: displayMonth)!
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title3.bold())
                                    .foregroundColor(Color(hex: "8ECFB0"))
                            }
                            Spacer()
                            Text(monthLabel)
                                .font(.title3.bold())
                            Spacer()
                            Button {
                                displayMonth = cal.date(byAdding: .month, value: 1, to: displayMonth)!
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title3.bold())
                                    .foregroundColor(canGoNext ? Color(hex: "8ECFB0") : Color.secondary.opacity(0.3))
                            }
                            .disabled(!canGoNext)
                        }
                        .padding(.horizontal, 20)

                        if sessions.isEmpty {
                            // 空状態
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 44))
                                    .foregroundColor(Color(hex: "CCCCCC"))
                                Text("この月の記録はありません")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                            .padding(.horizontal, 20)
                        } else {
                            // サマリーグリッド
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                MonthStatCard(
                                    icon: "calendar",
                                    iconColor: Color(hex: "5B8DEF"),
                                    title: "計測回数",
                                    value: "\(sessionCount)回"
                                )
                                MonthStatCard(
                                    icon: "waveform.path.ecg",
                                    iconColor: Color(hex: "F5A87A"),
                                    title: "平均イライラ度",
                                    value: avgStress.map { "\(Int($0))%" } ?? "--"
                                )
                                MonthStatCard(
                                    icon: "flame.fill",
                                    iconColor: Color(hex: "E8A090"),
                                    title: "暴言の回数",
                                    value: "\(totalWords)回"
                                )
                                MonthStatCard(
                                    icon: "hand.raised.fill",
                                    iconColor: Color(hex: "8ECFB0"),
                                    title: "台パンの回数",
                                    value: "\(totalImpacts)回"
                                )
                            }
                            .padding(.horizontal, 20)

                            // 日別イライラ度グラフ
                            VStack(alignment: .leading, spacing: 12) {
                                Text("日別イライラ度")
                                    .font(.headline.bold())

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(alignment: .bottom, spacing: 6) {
                                        ForEach(0..<daysInMonth, id: \.self) { i in
                                            let score = dailyAvg[i]
                                            VStack(spacing: 3) {
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(score > 0
                                                          ? Color(hex: "F5A87A").opacity(0.6 + score / 300)
                                                          : Color(hex: "EEEBE6"))
                                                    .frame(width: 14, height: max(4, CGFloat(score) * 0.8))
                                                Text("\(i + 1)")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .frame(height: 100, alignment: .bottom)
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                            .padding(.horizontal, 20)

                            // ゲーム別ランキング
                            if !gameStats.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("ゲーム別イライラ度")
                                        .font(.headline.bold())

                                    ForEach(gameStats, id: \.name) { stat in
                                        GameStatRow(name: stat.name, avg: stat.avg, count: stat.count)
                                    }
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                                .padding(.horizontal, 20)
                            }

                            // セッション一覧
                            VStack(alignment: .leading, spacing: 12) {
                                Text("セッション一覧")
                                    .font(.headline.bold())
                                    .padding(.horizontal, 20)

                                VStack(spacing: 0) {
                                    ForEach(monthSessions, id: \.session.id) { item in
                                        SessionRow(gameName: item.game.name, session: item.session)
                                        if item.session.id != monthSessions.last?.session.id {
                                            Divider().padding(.leading, 16)
                                        }
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("月別レポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 月別サマリーカード

struct MonthStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - ゲーム別行

struct GameStatRow: View {
    let name: String
    let avg: Double
    let count: Int

    private var barColor: Color {
        switch avg {
        case 0...30:  return Color(hex: "8ECFB0")
        case 31...60: return Color(hex: "F5E6A3")
        case 61...80: return Color(hex: "F5A87A")
        default:      return Color(hex: "E87575")
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Spacer()
                Text("\(Int(avg))%")
                    .font(.subheadline.bold())
                    .foregroundColor(barColor)
                Text("(\(count)回)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "EEEBE6"))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(avg / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

