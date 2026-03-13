import AVFoundation
import Foundation

class ImpactDetector {

    // MARK: - 設定値

    /// RMSスパイクの絶対閾値（delta がこれ以上なら即台パン判定）
    private let absoluteThreshold: Double = 0.20

    /// ベースラインの何倍以上の急上昇で台パンと判定（静音環境向け相対閾値）
    private let relativeMultiplier: Double = 4.0

    /// 検知後のクールダウン時間（秒）
    private let cooldownInterval: TimeInterval = 1.5

    /// 直近フレームの窓サイズ
    private let windowSize = 8

    // MARK: - 状態

    private var recentRMS: [Double] = []

    /// 環境ノイズのベースライン（動的更新）
    private var baselineRMS: Double = 0.01
    private var baselineSamples: [Double] = []
    private let baselineWindowSize = 40

    /// 最後に検知した時刻
    private var lastDetectionTime: Date = .distantPast

    var onImpactDetected: (() -> Void)?

    // MARK: - バッファ処理

    func process(buffer: AVAudioPCMBuffer) {
        let rms = calculateRMS(buffer: buffer)

        // ── ベースライン更新 ──
        // 静かなフレーム（ベースラインの2倍未満）だけをサンプリング
        if rms < baselineRMS * 2.5 {
            baselineSamples.append(rms)
            if baselineSamples.count > baselineWindowSize {
                baselineSamples.removeFirst()
            }
            if !baselineSamples.isEmpty {
                let avg = baselineSamples.reduce(0, +) / Double(baselineSamples.count)
                baselineRMS = max(0.005, avg)   // 最低でも0.005を保持
            }
        }

        // ── スパイク検出 ──
        recentRMS.append(rms)
        if recentRMS.count > windowSize { recentRMS.removeFirst() }
        guard recentRMS.count >= 2 else { return }

        // クールダウン中はスキップ
        guard Date().timeIntervalSince(lastDetectionTime) >= cooldownInterval else { return }

        let previousMax = recentRMS.dropLast().max() ?? 0
        let current = recentRMS.last ?? 0
        let delta = current - previousMax

        // 条件1: 絶対値でのスパイク（delta が大きい）
        let isAbsoluteSpike = delta >= absoluteThreshold

        // 条件2: ベースラインに対する相対スパイク（静音環境向け）
        //        current がベースラインの relativeMultiplier 倍以上 かつ delta も十分大きい
        let isRelativeSpike = current >= baselineRMS * relativeMultiplier
                           && delta >= baselineRMS * 2.5

        if isAbsoluteSpike || isRelativeSpike {
            print("[Impact] Detected! RMS=\(f(current)) delta=\(f(delta)) baseline=\(f(baselineRMS)) mode=\(isAbsoluteSpike ? "abs" : "rel")")
            lastDetectionTime = Date()
            onImpactDetected?()
            recentRMS.removeAll()   // 連続検知リセット
        }
    }

    // MARK: - RMS計算

    private func calculateRMS(buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let channelCount = Int(buffer.format.channelCount)
        let frameCount   = Int(buffer.frameLength)
        guard channelCount > 0, frameCount > 0 else { return 0 }

        var sum: Float = 0
        for channel in 0..<channelCount {
            let samples = channelData[channel]
            for frame in 0..<frameCount {
                let s = samples[frame]
                sum += s * s
            }
        }
        let mean = sum / Float(frameCount * channelCount)
        return Double(sqrt(mean))
    }

    private func f(_ v: Double) -> String { String(format: "%.4f", v) }
}

