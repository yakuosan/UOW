import SwiftUI

// MARK: - Gauge View

struct IrritationGaugeView: View {
    let score: Double
    let level: IrritationLevel

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: score)

                VStack(spacing: 4) {
                    Text("\(Int(score))")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(gaugeColor)
                        .animation(.easeInOut, value: score)
                    Text(level.description)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Text("イライラ度スコア")
                .font(.caption)
                .foregroundColor(.secondary)

            LevelIndicatorRow(level: level)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var gaugeColor: Color {
        switch level {
        case .calm:    return .green
        case .caution: return .yellow
        case .warning: return .orange
        case .danger:  return .red
        }
    }
}

struct LevelIndicatorRow: View {
    let level: IrritationLevel
    private let levels: [(IrritationLevel, String, Color)] = [
        (.calm,    "平常",  .green),
        (.caution, "注意",  .yellow),
        (.warning, "警告",  .orange),
        (.danger,  "危険",  .red),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(levels, id: \.1) { l, name, color in
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .scaleEffect(level == l ? 1.4 : 1.0)
                        .animation(.spring(), value: level)
                    Text(name)
                        .font(.caption2)
                        .fontWeight(level == l ? .bold : .regular)
                        .foregroundColor(level == l ? color : .secondary)
                }
            }
        }
    }
}

// MARK: - Control Buttons

struct ControlButtons: View {
    @ObservedObject var viewModel: IrritationViewModel

    var body: some View {
        HStack(spacing: 16) {
            Button {
                if viewModel.isMonitoring {
                    viewModel.stopMonitoring()
                } else {
                    viewModel.startMonitoring()
                }
            } label: {
                HStack {
                    Image(systemName: viewModel.isMonitoring ? "mic.slash.fill" : "mic.fill")
                    Text(viewModel.isMonitoring ? "停止" : "監視開始")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(viewModel.isMonitoring ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Transcription Card

struct TranscriptionCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("音声認識", systemImage: "waveform")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
    }
}

// MARK: - Event Log

struct EventLogView: View {
    let events: [DetectionEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("検知ログ", systemImage: "list.bullet")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ForEach(events.prefix(10)) { event in
                HStack {
                    Text(event.icon)
                    Text(event.description)
                        .font(.caption)
                    Spacer()
                    Text(event.timeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.6))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.4))
        .cornerRadius(12)
    }
}

// MARK: - Advice Modal

struct AdviceModal: View {
    let advice: String
    let level: IrritationLevel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 20) {
                Text(level == .danger ? "⚠️ 危険レベル" : "💡 アドバイス")
                    .font(.title2.bold())
                Text(advice)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                Image(systemName: "lungs.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Button("閉じる") { onDismiss() }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(32)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(40)
        }
    }
}

// MARK: - マイク権限案内オーバーレイ

struct MicPermissionGuide: View {
    let onAllow: () -> Void
    let onOpenSettings: () -> Void
    let isDenied: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 28) {

                // アイコン
                ZStack {
                    Circle()
                        .fill(Color(hex: "EEF9F4"))
                        .frame(width: 88, height: 88)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "8ECFB0"))
                }

                // テキスト
                VStack(spacing: 10) {
                    Text(isDenied ? "マイクの許可が必要です" : "マイクをオンにしてください")
                        .font(.title3.bold())

                    Text(isDenied
                         ? "設定アプリ → このアプリ → マイクと音声認識をオンにしてください。"
                         : "暴言・台パンを検知するためにマイクと音声認識の許可が必要です。次の画面で「許可」を選んでください。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // ボタン
                VStack(spacing: 12) {
                    if isDenied {
                        Button(action: onOpenSettings) {
                            HStack(spacing: 8) {
                                Image(systemName: "gear")
                                Text("設定を開く")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Capsule().fill(Color(hex: "8ECFB0")))
                        }
                    } else {
                        Button(action: onAllow) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("許可して計測を開始する")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Capsule().fill(Color(hex: "8ECFB0")))
                        }
                    }
                }
            }
            .padding(28)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
            .padding(.horizontal, 28)
        }
    }
}

// MARK: - 強制深呼吸モーダル（スコア90超で表示、完了するまで閉じられない）

struct BreathingModal: View {
    let onComplete: () -> Void

    @State private var phase: BreathPhase = .inhale
    @State private var circleScale: CGFloat = 0.5
    @State private var cycleCount = 0
    @State private var isComplete = false
    @State private var phaseTimeLeft: Int = 4
    // 世代番号：onAppear が複数回呼ばれても古いチェーンを無効化する
    @State private var generation: Int = 0

    enum BreathPhase {
        case inhale, hold, exhale

        var durationSeconds: Int {
            switch self {
            case .inhale: return 4
            case .hold:   return 2
            case .exhale: return 6
            }
        }
        var label: String {
            switch self {
            case .inhale: return "吸って"
            case .hold:   return "止めて"
            case .exhale: return "吐いて"
            }
        }
        var targetScale: CGFloat {
            switch self {
            case .inhale, .hold: return 1.0
            case .exhale:        return 0.45
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()

            VStack(spacing: 36) {

                VStack(spacing: 6) {
                    Text("⚠️ イライラ度が危険レベルです")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "E87575"))
                    Text("深呼吸して落ち着きましょう")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }

                ZStack {
                    Circle()
                        .fill(Color(hex: "8ECFB0").opacity(0.15))
                        .frame(width: 220, height: 220)

                    Circle()
                        .fill(Color(hex: "8ECFB0").opacity(0.4))
                        .frame(width: 220, height: 220)
                        .scaleEffect(circleScale)
                        .animation(
                            .easeInOut(duration: Double(phase.durationSeconds)),
                            value: circleScale
                        )

                    VStack(spacing: 4) {
                        Text(phase.label)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("\(phaseTimeLeft)")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "8ECFB0"))
                    }
                }

                HStack(spacing: 16) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i < cycleCount
                                  ? Color(hex: "8ECFB0")
                                  : Color.white.opacity(0.3))
                            .frame(width: 14, height: 14)
                            .scaleEffect(i < cycleCount ? 1.2 : 1.0)
                            .animation(.spring(), value: cycleCount)
                    }
                }

                if isComplete {
                    Button(action: onComplete) {
                        Text("完了　✓")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color(hex: "8ECFB0")))
                    }
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else {
                    Text("あと \(3 - cycleCount) サイクル")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(32)
        }
        .onAppear {
            // 世代番号を上げて古いチェーンを無効化してから新しく開始
            generation += 1
            let myGen = generation
            phase = .inhale
            cycleCount = 0
            isComplete = false
            phaseTimeLeft = BreathPhase.inhale.durationSeconds
            withAnimation(.easeInOut(duration: Double(BreathPhase.inhale.durationSeconds))) {
                circleScale = BreathPhase.inhale.targetScale
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                tick(gen: myGen)
            }
        }
    }

    // MARK: - タイマー制御（世代番号付き）

    /// 1秒ごとに呼ばれるカウントダウン。gen が現世代と一致しないときは即停止。
    private func tick(gen: Int) {
        guard gen == generation, !isComplete else { return }
        if phaseTimeLeft > 1 {
            phaseTimeLeft -= 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { tick(gen: gen) }
        } else {
            advance(gen: gen)
        }
    }

    private func advance(gen: Int) {
        guard gen == generation else { return }
        switch phase {
        case .inhale:
            phase = .hold
            // hold は円のサイズ変更なし
        case .hold:
            phase = .exhale
            withAnimation(.easeInOut(duration: Double(BreathPhase.exhale.durationSeconds))) {
                circleScale = BreathPhase.exhale.targetScale
            }
        case .exhale:
            cycleCount += 1
            if cycleCount >= 3 {
                withAnimation { isComplete = true }
                return   // チェーン終了
            }
            phase = .inhale
            withAnimation(.easeInOut(duration: Double(BreathPhase.inhale.durationSeconds))) {
                circleScale = BreathPhase.inhale.targetScale
            }
        }
        phaseTimeLeft = phase.durationSeconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { tick(gen: gen) }
    }
}

// MARK: - ヒーリングミュージック再生中バー

struct MusicPlayingBar: View {
    @State private var h0: CGFloat = 6
    @State private var h1: CGFloat = 14
    @State private var h2: CGFloat = 6
    @State private var h3: CGFloat = 16

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 3) {
                bar(height: h0).onAppear {
                    withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) { h0 = 14 }
                }
                bar(height: h1).onAppear {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { h1 = 8 }
                }
                bar(height: h2).onAppear {
                    withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) { h2 = 18 }
                }
                bar(height: h3).onAppear {
                    withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) { h3 = 10 }
                }
            }
            .frame(height: 20)

            Text("ヒーリングミュージック再生中")
                .font(.subheadline.bold())
                .foregroundColor(Color(hex: "8ECFB0"))

            Spacer()

            Image(systemName: "music.note")
                .foregroundColor(Color(hex: "8ECFB0"))
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: Color(hex: "8ECFB0").opacity(0.3), radius: 8, y: 2)
    }

    private func bar(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(hex: "8ECFB0"))
            .frame(width: 3, height: height)
    }
}

// MARK: - Permission Warning

struct PermissionWarningView: View {
    @ObservedObject var viewModel: IrritationViewModel

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("マイク・音声認識の許可が必要です")
                .font(.headline)
            Text("設定アプリからこのアプリのマイクと音声認識の使用を許可してください。")
                .font(.caption)
                .multilineTextAlignment(.center)
            Button("許可をリクエスト") {
                viewModel.requestPermissions()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(40)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255)
    }
}

