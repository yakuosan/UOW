import SwiftUI
import AVFoundation
import Speech

struct MonitoringView: View {
    let game: Game?
    @StateObject private var viewModel = IrritationViewModel()
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var peakScore: Double = 0
    @State private var sessionSaved = false
    @State private var showResult = false
    @State private var showPermissionGuide = false

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

                // 警告バナー（スコア40〜70）
                if viewModel.score >= 40 && viewModel.score <= 70 {
                    ScoreWarningBanner(score: viewModel.score)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 計測終了ボタン
                Button {
                    stopAndSave()
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

            // ヒーリングミュージック再生中バー
            if viewModel.isPlayingMusic {
                VStack {
                    Spacer()
                    MusicPlayingBar()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(5)
            }

            // 忠告モーダル（warning レベル）
            if viewModel.showAdviceModal {
                AdviceModal(
                    advice: viewModel.currentAdvice,
                    level: viewModel.level,
                    onDismiss: { viewModel.dismissModal() }
                )
            }

            // マイク権限案内オーバーレイ
            if showPermissionGuide {
                MicPermissionGuide(
                    onAllow: {
                        showPermissionGuide = false
                        viewModel.requestPermissions()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            viewModel.startMonitoring()
                        }
                    },
                    onOpenSettings: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    isDenied: AVAudioSession.sharedInstance().recordPermission == .denied
                              || SFSpeechRecognizer.authorizationStatus() == .denied
                )
                .transition(.opacity)
                .zIndex(20)
            }

            // 強制深呼吸モーダル（danger レベル：スコア91以上、完了するまで閉じられない）
            if viewModel.showBreathingModal {
                BreathingModal {
                    viewModel.dismissBreathingModal()
                }
                .transition(.opacity)
                .zIndex(10)
            }

            // 計測結果オーバーレイ
            if showResult {
                SessionResultOverlay(
                    gameName: game?.name ?? "ゲーム",
                    peakScore: peakScore,
                    wordCount: viewModel.wordCount,
                    impactCount: viewModel.impactCount
                ) {
                    dismiss()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .navigationTitle("現在のイライラ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("終了") {
                    stopAndSave()
                }.foregroundColor(.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("リセット") {
                    viewModel.resetScore()
                    peakScore = 0
                }.foregroundColor(.primary)
            }
        }
        .onAppear {
            checkAndRequestPermissions()
        }
        .onReceive(viewModel.$score) { score in
            if score > peakScore { peakScore = score }
        }
        .onDisappear {
            // バックグラウンドに回った場合などのフォールバック保存
            viewModel.stopMonitoring()
            if !sessionSaved { saveSession() }
        }
        // 設定アプリからマイクをONにして戻ってきたとき自動で案内を閉じてスタート
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, showPermissionGuide else { return }
            let micOK = AVAudioSession.sharedInstance().recordPermission == .granted
            let speechOK = SFSpeechRecognizer.authorizationStatus() == .authorized
            if micOK && speechOK {
                withAnimation {
                    showPermissionGuide = false
                }
                viewModel.requestPermissions()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.startMonitoring()
                }
            }
        }
        // 権限が付与されたら案内を閉じる（in-appダイアログのOKを押した直後）
        .onChange(of: viewModel.micPermissionGranted) { _, granted in
            guard granted, showPermissionGuide else { return }
            withAnimation {
                showPermissionGuide = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.startMonitoring()
            }
        }
    }

    // MARK: - 権限確認 → 案内 or 直接スタート
    private func checkAndRequestPermissions() {
        let micStatus = AVAudioSession.sharedInstance().recordPermission
        let speechStatus = SFSpeechRecognizer.authorizationStatus()

        if micStatus == .undetermined || speechStatus == .notDetermined {
            // 初回：案内画面を表示してから権限リクエスト
            showPermissionGuide = true
        } else if micStatus == .denied || speechStatus == .denied {
            // 拒否済み：設定を開く案内を表示
            showPermissionGuide = true
        } else {
            // 既に許可済み：すぐスタート
            viewModel.requestPermissions()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.startMonitoring()
            }
        }
    }

    // MARK: - 停止 → 保存 → 結果表示
    private func stopAndSave() {
        viewModel.stopMonitoring()
        saveSession()
        withAnimation(.easeInOut(duration: 0.25)) {
            showResult = true
        }
    }

    private func saveSession() {
        guard !sessionSaved else { return }   // 二重保存防止
        guard let gameID = game?.id else { return }
        sessionSaved = true
        let session = GameSession(
            peakScore: peakScore,             // 0でも保存する（穏やかなセッションも記録）
            wordCount: viewModel.wordCount,
            impactCount: viewModel.impactCount
        )
        store.addSession(session, to: gameID)
        print("[MonitoringView] Session saved: peakScore=\(Int(peakScore))%, words=\(viewModel.wordCount), impacts=\(viewModel.impactCount)")
    }
}

// MARK: - 計測結果オーバーレイ

struct SessionResultOverlay: View {
    let gameName: String
    let peakScore: Double
    let wordCount: Int
    let impactCount: Int
    let onClose: () -> Void

    private var scoreColor: Color {
        switch peakScore {
        case 0...30:  return Color(hex: "8ECFB0")
        case 31...60: return Color(hex: "F5E6A3")
        case 61...80: return Color(hex: "F5A87A")
        default:      return Color(hex: "E87575")
        }
    }

    private var scoreLabel: String {
        switch peakScore {
        case 0...30:  return "落ち着いてました"
        case 31...60: return "少しイライラしました"
        case 61...80: return "かなりイライラしました"
        default:      return "かなりイライラしました！"
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 6) {
                    Text("計測完了")
                        .font(.title2.bold())
                    Text(gameName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // スコアゲージ
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.2), lineWidth: 10)
                        .frame(width: 120, height: 120)
                    Circle()
                        .trim(from: 0, to: CGFloat(peakScore / 100))
                        .stroke(scoreColor,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(Int(peakScore))%")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor)
                        Text("最高イライラ度")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Text(scoreLabel)
                    .font(.headline)
                    .foregroundColor(scoreColor)

                // 暴言 / 台パンカウント
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(wordCount)")
                            .font(.title3.bold())
                            .foregroundColor(Color(hex: "E8A090"))
                        Text("暴言")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Divider().frame(height: 36)
                    VStack(spacing: 4) {
                        Text("\(impactCount)")
                            .font(.title3.bold())
                            .foregroundColor(Color(hex: "8ECFB0"))
                        Text("台パン")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)

                // 閉じるボタン
                Button(action: onClose) {
                    Text("閉じる")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(scoreColor))
                }
            }
            .padding(28)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
            .padding(.horizontal, 32)
        }
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
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black)
                        .frame(width: 72, height: 52)
                    if let urlStr = game?.imageURL, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Image(systemName: game?.imageName ?? "gamecontroller.fill")
                                    .font(.title2).foregroundColor(.white)
                            }
                        }
                        .frame(width: 72, height: 52)
                        .clipped()
                    } else {
                        Image(systemName: game?.imageName ?? "gamecontroller.fill")
                            .font(.title2).foregroundColor(.white)
                    }
                }
                .cornerRadius(8)

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

// MARK: - スコア警告バナー（40〜70）

struct ScoreWarningBanner: View {
    let score: Double

    private var message: String {
        score >= 56 ? "イライラが高まっています。深呼吸してみましょう。" : "少し注意が必要です。落ち着いて。"
    }
    private var bannerColor: Color {
        score >= 56 ? Color(hex: "F5A87A") : Color(hex: "F5E6A3")
    }
    private var icon: String {
        score >= 56 ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill"
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(bannerColor)
                .font(.title3)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(bannerColor.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(bannerColor.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - 円形イライラゲージ

struct IrritationCircleGauge: View {
    let score: Double
    let isMonitoring: Bool

    private let size: CGFloat = 220
    private let lineWidth: CGFloat = 18

    @State private var pulseScale: CGFloat = 1.0

    private var inCautionRange: Bool { score >= 40 && score <= 70 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "EEEBE6"), lineWidth: lineWidth)
                .frame(width: size, height: size)

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
                .animation(.linear(duration: 0.05), value: score)
                .scaleEffect(pulseScale)

            VStack(spacing: 2) {
                Text("イライラ度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(score))%")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                HStack(spacing: 4) {
                    Image(systemName: "mic")
                    Image(systemName: "waveform")
                }
                .font(.caption)
                .foregroundColor(isMonitoring ? Color(hex: "8ECFB0") : .secondary)
            }
        }
        .frame(width: size + 40, height: size + 40)
        .onChange(of: inCautionRange) { _, inRange in
            if inRange {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    pulseScale = 1.0
                }
            }
        }
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

