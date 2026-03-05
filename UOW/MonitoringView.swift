import SwiftUI

struct MonitoringView: View {
    let game: Game?
    @StateObject private var viewModel = IrritationViewModel()
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var peakScore: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "FAF7F2").ignoresSafeArea()

            VStack(spacing: 20) {
                // ゲーム情報カード
                GameInfoCard(game: game)
                    .padding(.horizontal, 20)

                // 円形イライラゲージ
                IrritationCircleGauge(
                    score: viewModel.score,
                    isMonitoring: viewModel.isMonitoring
                )

                // 計測終了ボタン
                Button {
                    viewModel.stopMonitoring()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.circle.fill")
                        Text("計測を終了する")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color(hex: "E87575")))
                }
                .padding(.horizontal, 20)

                // 暴言・台パンカウント
                HStack(spacing: 16) {
                    DetectionStatCard(
                        sfSymbol: "flame.fill",
                        iconColor: Color(hex: "E8A090"),
                        bgColor:  Color(hex: "FFF0EE"),
                        title: "暴言",
                        count: viewModel.wordCount
                    )
                    DetectionStatCard(
                        sfSymbol: "hand.raised.fill",
                        iconColor: Color(hex: "8ECFB0"),
                        bgColor:  Color(hex: "EEF9F4"),
                        title: "台パン",
                        count: viewModel.impactCount
                    )
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 12)

            // 忠告モーダル
            if viewModel.showAdviceModal {
                AdviceModal(
                    advice: viewModel.currentAdvice,
                    level: viewModel.level,
                    onDismiss: { viewModel.dismissModal() }
                )
            }
        }
        .navigationTitle("現在のイライラ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("終了") { dismiss() }.foregroundColor(.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("リセット") { viewModel.resetScore() }.foregroundColor(.primary)
            }
        }
        .onAppear {
            viewModel.requestPermissions()
            viewModel.startMonitoring()
        }
        .onReceive(viewModel.scoreEngine.$score) { score in
            if score > peakScore { peakScore = score }
        }
        .onDisappear {
            viewModel.stopMonitoring()
            saveSession()
        }
    }

    private func saveSession() {
        guard let gameID = game?.id, peakScore > 0 else { return }
        let session = GameSession(
            peakScore: peakScore,
            wordCount: viewModel.wordCount,
            impactCount: viewModel.impactCount
        )
        store.addSession(session, to: gameID)
    }
}

// MARK: - ゲーム情報カード

struct GameInfoCard: View {
    let game: Game?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("プレイしているゲーム")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                // ゲームサムネイル
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black)
                        .frame(width: 72, height: 52)
                    Image(systemName: game?.imageName ?? "gamecontroller.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                Text(game?.name ?? "ゲームを選択してください")
                    .font(.title3.bold())

                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

// MARK: - 円形イライラゲージ

struct IrritationCircleGauge: View {
    let score: Double
    let isMonitoring: Bool

    private let size: CGFloat = 220
    private let lineWidth: CGFloat = 18

    var body: some View {
        ZStack {
            // 背景トラック
            Circle()
                .stroke(Color(hex: "EEEBE6"), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // グラデーション進捗弧
            Circle()
                .trim(from: 0, to: max(0.01, score / 100))
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: "8ECFB0"),
                            Color(hex: "F5C5A0"),
                            Color(hex: "E87575")
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle:   .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: score)

            // 中央テキスト
            VStack(spacing: 2) {
                Text("イライラ度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(score))%")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .animation(.easeInOut, value: score)

                // マイク＋波形アイコン
                HStack(spacing: 4) {
                    Image(systemName: "mic")
                    Image(systemName: "waveform")
                }
                .font(.caption)
                .foregroundColor(isMonitoring ? Color(hex: "8ECFB0") : .secondary)
            }
        }
        .frame(width: size + 40, height: size + 40)
    }
}

// MARK: - 検知カウントカード

struct DetectionStatCard: View {
    let sfSymbol: String
    let iconColor: Color
    let bgColor: Color
    let title: String
    let count: Int

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(bgColor)
                    .frame(width: 52, height: 52)
                Image(systemName: sfSymbol)
                    .font(.title2)
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(count)回")
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

