import AVFoundation
import Foundation

class ImpactDetector {

    // MARK: - 設定値

    /// RMSスパイクの絶対閾値
    private let absoluteThreshold: Double = 0.20

    /// ベースラインの何倍以上で台パン候補とするか
    private let relativeMultiplier: Double = 4.0

    /// 検知後のクールダウン時間（秒）
    private let cooldownInterval: TimeInterval = 1.5

    /// 「直前が静かだった」と判定する RMS の上限
    /// 声や咳は連続するので直前フレームも音量が高い → これで除外
    private let quietThreshold: Double = 0.06

    /// 台パン確定に必要な減衰率
    /// 次フレームの RMS がピークの何%以下なら「すぐ落ちた＝台パン」と判定
    /// 咳は音が持続するのでこの条件を満たさない
    private let decayConfirmRatio: Double = 0.45

    /// 直近フレームの窓サイズ
    private let windowSize = 8

    // MARK: - 状態

    private var recentRMS: [Double] = []
    private var baselineRMS: Double = 0.01
    private var baselineSamples: [Double] = []
    private let baselineWindowSize = 40
    private var lastDetectionTime: Date = .distantPast

    /// スパイク候補のピーク値（次フレームで減衰チェックするために保持）
    private var candidatePeakRMS: Double = 0

    var onImpactDetected: (() -> Void)?

    // MARK: - バッファ処理

    func process(buffer: AVAudioPCMBuffer) {
        let rms = calculateRMS(buffer: buffer)

        // ── Phase 2: 候補の確定チェック（1フレーム後に確認）──
        if candidatePeakRMS > 0 {
            let decayRatio = rms / max(0.001, candidatePeakRMS)
            if decayRatio < decayConfirmRatio {
                // RMS が急激に落ちた → 台パン確定
                print("[Impact] ✅ Confirmed! peak=\(f(candidatePeakRMS)) next=\(f(rms)) ratio=\(String(format: "%.2f", decayRatio))")
                lastDetectionTime = Date()
                onImpactDetected?()
                recentRMS.removeAll()
            } else {
                // RMS が持続している → 咳・声など、台パンではない
                print("[Impact] ❌ Rejected (sustained sound). ratio=\(String(format: "%.2f", decayRatio))")
            }
            candidatePeakRMS = 0
            return  // このフレームはここで終了
        }

        // ── ベースライン更新（静かなフレームのみ使用）──
        if rms < baselineRMS * 2.5 {
            baselineSamples.append(rms)
            if baselineSamples.count > baselineWindowSize { baselineSamples.removeFirst() }
            if !baselineSamples.isEmpty {
                let avg = baselineSamples.reduce(0, +) / Double(baselineSamples.count)
                baselineRMS = max(0.005, avg)
            }
        }

        // ── スパイク候補の検出 ──
        recentRMS.append(rms)
        if recentRMS.count > windowSize { recentRMS.removeFirst() }
        guard recentRMS.count >= 2 else { return }

        // クールダウン中はスキップ
        guard Date().timeIntervalSince(lastDetectionTime) >= cooldownInterval else { return }

        let previousMax  = recentRMS.dropLast().max() ?? 0
        let previousMean = recentRMS.dropLast().reduce(0.0, +) / Double(max(1, recentRMS.count - 1))
        let current = recentRMS.last ?? 0
        let delta = current - previousMax

        // 声・咳は連続音なので直前フレームも音量が高い → 除外
        let wasQuietBefore = previousMean < quietThreshold

        let isAbsoluteSpike = delta >= absoluteThreshold && wasQuietBefore
        let isRelativeSpike = current >= baselineRMS * relativeMultiplier
                           && delta >= baselineRMS * 2.5
                           && wasQuietBefore

        if isAbsoluteSpike || isRelativeSpike {
            // すぐ確定せず、次フレームで減衰チェックをする
            candidatePeakRMS = current
            print("[Impact] 📍 Candidate: RMS=\(f(current)) delta=\(f(delta)) prevMean=\(f(previousMean))")
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

