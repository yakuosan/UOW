import SwiftUI

struct RankingView: View {
    @EnvironmentObject var store: GameStore
    @State private var showAddFriend = false

    // 自分の平均イライラ度
    private var myAvgStress: Int {
        let all = store.games.flatMap(\.sessions)
        guard !all.isEmpty else { return 0 }
        return Int(all.map(\.peakScore).reduce(0, +) / Double(all.count))
    }

    private var mySessionCount: Int {
        store.games.flatMap(\.sessions).count
    }

    // 自分＋フレンドをイライラ度降順でランキング化
    private var rankings: [RankEntry] {
        var entries: [RankEntry] = []

        // 自分
        entries.append(RankEntry(
            name: store.myDisplayName,
            avgStress: myAvgStress,
            sessionCount: mySessionCount,
            isMe: true
        ))

        // フレンド
        for friend in store.friends {
            entries.append(RankEntry(
                name: friend.name,
                avgStress: friend.avgStress,
                sessionCount: friend.sessionCount,
                isMe: false,
                friendID: friend.id
            ))
        }

        // 高イライラ度順
        entries.sort { $0.avgStress > $1.avgStress }
        return entries.enumerated().map { i, e in
            RankEntry(rank: i + 1, name: e.name, avgStress: e.avgStress,
                      sessionCount: e.sessionCount, isMe: e.isMe, friendID: e.friendID)
        }
    }

    private var hasAnyData: Bool {
        mySessionCount > 0 || !store.friends.isEmpty
    }

    var body: some View {
        ZStack {
            Color(hex: "FAF7F2").ignoresSafeArea()

            VStack(spacing: 20) {
                // フレンドを追加ボタン
                HStack {
                    Spacer()
                    Button {
                        showAddFriend = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.badge.plus")
                            Text("フレンドを追加")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color(hex: "8ECFB0")))
                    }
                }
                .padding(.horizontal, 20)

                if !hasAnyData {
                    EmptyRankingView()
                } else {
                    // 自分のサマリーカード
                    if mySessionCount > 0 {
                        MyStatsCard(
                            avgStress: myAvgStress,
                            sessionCount: mySessionCount
                        )
                        .padding(.horizontal, 20)
                    }

                    // ランキングリスト
                    VStack(spacing: 0) {
                        ForEach(rankings) { entry in
                            RankingRow(entry: entry) {
                                // フレンドのみ削除可能
                                if let fid = entry.friendID {
                                    store.removeFriend(id: fid)
                                }
                            }
                            if entry.rank != rankings.last?.rank {
                                Divider().padding(.leading, 80)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                    .padding(.horizontal, 20)
                }

                Spacer()
            }
            .padding(.top, 12)
        }
        .navigationTitle("ランキング")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddFriend) {
            AddFriendView()
                .environmentObject(store)
        }
    }
}

// MARK: - フレンド追加シート

struct AddFriendView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var friendCode: String = ""
    @State private var copiedCode = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    private var myCode: String { store.generateMyCode() }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FAF7F2").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // ── 自分のコードを共有 ──
                        VStack(alignment: .leading, spacing: 12) {
                            SectionLabel(icon: "qrcode", title: "自分のコードを共有")

                            // 表示名の変更
                            VStack(alignment: .leading, spacing: 6) {
                                Text("表示名")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack {
                                    TextField(store.myDisplayName, text: $displayName)
                                        .textFieldStyle(.plain)
                                    if !displayName.isEmpty {
                                        Button("保存") {
                                            store.setDisplayName(displayName)
                                            displayName = ""
                                            UIApplication.shared.sendAction(
                                                #selector(UIResponder.resignFirstResponder),
                                                to: nil, from: nil, for: nil
                                            )
                                        }
                                        .font(.caption.bold())
                                        .foregroundColor(Color(hex: "8ECFB0"))
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                            }

                            // コード表示
                            VStack(spacing: 8) {
                                Text(myCode)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.center)
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(hex: "F0EDE8"))
                                    .cornerRadius(10)

                                Button {
                                    UIPasteboard.general.string = myCode
                                    withAnimation {
                                        copiedCode = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        copiedCode = false
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: copiedCode ? "checkmark" : "doc.on.doc")
                                        Text(copiedCode ? "コピーしました" : "コードをコピー")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule().fill(copiedCode
                                                       ? Color(hex: "8ECFB0")
                                                       : Color(hex: "5B8DEF"))
                                    )
                                }
                            }

                            Text("このコードを友達に送って追加してもらおう")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                        .padding(.horizontal, 20)

                        // ── フレンドのコードを追加 ──
                        VStack(alignment: .leading, spacing: 12) {
                            SectionLabel(icon: "person.badge.plus", title: "フレンドを追加")

                            VStack(alignment: .leading, spacing: 6) {
                                Text("フレンドのコードを貼り付け")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("コードを入力...", text: $friendCode, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .lineLimit(3)
                                    .padding(12)
                                    .background(Color(hex: "F0EDE8"))
                                    .cornerRadius(10)
                            }

                            // エラー / 成功メッセージ
                            if let err = errorMessage {
                                Text(err)
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "E87575"))
                            }
                            if let success = successMessage {
                                Text(success)
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "8ECFB0"))
                            }

                            Button {
                                addFriend()
                            } label: {
                                Text("追加する")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule().fill(friendCode.isEmpty
                                                       ? Color(hex: "BBBBBB")
                                                       : Color(hex: "8ECFB0"))
                                    )
                            }
                            .disabled(friendCode.isEmpty)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                        .padding(.horizontal, 20)

                        // ── 登録済みフレンド ──
                        if !store.friends.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionLabel(icon: "person.2.fill", title: "フレンド一覧")

                                VStack(spacing: 0) {
                                    ForEach(store.friends) { friend in
                                        FriendListRow(friend: friend) {
                                            store.removeFriend(id: friend.id)
                                        }
                                        if friend.id != store.friends.last?.id {
                                            Divider().padding(.leading, 16)
                                        }
                                    }
                                }
                                .background(Color(hex: "F0EDE8"))
                                .cornerRadius(10)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("フレンド")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func addFriend() {
        errorMessage = nil
        successMessage = nil
        do {
            try store.addFriend(from: friendCode)
            successMessage = "フレンドを追加しました！"
            friendCode = ""
        } catch let error as FriendError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "追加に失敗しました"
        }
    }
}

// MARK: - フレンド一覧行

struct FriendListRow: View {
    let friend: Friend
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: "E0DDD8"))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.subheadline)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.subheadline.bold())
                Text("平均イライラ度: \(friend.avgStress)%・計\(friend.sessionCount)回")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(Color(hex: "E87575"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - セクションラベル

struct SectionLabel: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "8ECFB0"))
            Text(title)
                .font(.headline.bold())
        }
    }
}

// MARK: - ランキングエントリ

struct RankEntry: Identifiable {
    let id = UUID()
    var rank: Int = 0
    let name: String
    let avgStress: Int
    let sessionCount: Int
    let isMe: Bool
    var friendID: UUID? = nil
}

// MARK: - 自分のスタッツカード

struct MyStatsCard: View {
    let avgStress: Int
    let sessionCount: Int

    private var stressColor: Color {
        switch avgStress {
        case 0...30:  return Color(hex: "8ECFB0")
        case 31...60: return Color(hex: "F5E6A3")
        case 61...80: return Color(hex: "F5A87A")
        default:      return Color(hex: "E87575")
        }
    }

    private var stressLabel: String {
        switch avgStress {
        case 0...30:  return "落ち着いてます"
        case 31...60: return "少しイライラ気味"
        case 61...80: return "かなりイライラ中"
        default:      return "危険水域！"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(stressColor.opacity(0.2), lineWidth: 6)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: CGFloat(avgStress) / 100)
                    .stroke(stressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                Text("\(avgStress)%")
                    .font(.system(size: 13, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("平均イライラ度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(stressLabel)
                    .font(.headline.bold())
                    .foregroundColor(stressColor)
                Text("計\(sessionCount)回の計測データ")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - 空状態

struct EmptyRankingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "CCCCCC"))
            Text("まだ記録がありません")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("ゲームを計測するとランキングに表示されます")
                .font(.caption)
                .foregroundColor(Color(hex: "AAAAAA"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .padding(.horizontal, 20)
    }
}

// MARK: - ランキング行

struct RankingRow: View {
    let entry: RankEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text("\(entry.rank)")
                .font(.title2.bold())
                .foregroundColor(rankColor)
                .frame(width: 28, alignment: .center)

            Circle()
                .fill(entry.isMe ? Color(hex: "8ECFB0").opacity(0.3) : Color(hex: "E0DDD8"))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: entry.isMe ? "person.fill.checkmark" : "person.fill")
                        .foregroundColor(entry.isMe ? Color(hex: "8ECFB0") : .white)
                        .font(.title3)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.name)
                        .font(.headline)
                    if entry.isMe {
                        Text("自分")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "8ECFB0"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "8ECFB0").opacity(0.15)))
                    }
                }
                Text("平均イライラ度: \(entry.avgStress)%・計\(entry.sessionCount)回")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if entry.isMe {
                Text(medalEmoji)
                    .font(.title2)
            } else {
                // フレンドは長押しで削除
                Text(medalEmoji)
                    .font(.title2)
                    .contextMenu {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("フレンドを削除", systemImage: "trash")
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color(hex: "FFB800")
        case 2: return Color(hex: "A0A0A0")
        case 3: return Color(hex: "CD7F32")
        default: return .primary
        }
    }

    private var medalEmoji: String {
        switch entry.rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
}

