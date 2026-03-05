import AVFoundation
import Foundation

class ImpactDetector {
    // RMS must rise by this amount within the window to count as impact
    private let spikeThreshold: Double = 0.3
    // Rolling window of recent RMS values
    private var recentRMS: [Double] = []
    private let windowSize = 5  // ~5 frames ≈ 0.5 sec at 1024-sample buffers

    var onImpactDetected: (() -> Void)?

    func process(buffer: AVAudioPCMBuffer) {
        let rms = calculateRMS(buffer: buffer)
        recentRMS.append(rms)
        if recentRMS.count > windowSize {
            recentRMS.removeFirst()
        }

        guard recentRMS.count >= 2 else { return }

        let previousMax = recentRMS.dropLast().max() ?? 0
        let current = recentRMS.last ?? 0
        let delta = current - previousMax

        if delta >= spikeThreshold {
            print("[Impact] Spike detected. RMS: \(String(format: "%.3f", current)), delta: \(String(format: "%.3f", delta))")
            onImpactDetected?()
            recentRMS.removeAll()  // reset to avoid double-counting
        }
    }

    private func calculateRMS(buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let channelCount = Int(buffer.format.channelCount)
        let frameCount = Int(buffer.frameLength)
        guard channelCount > 0, frameCount > 0 else { return 0 }

        var sum: Float = 0
        for channel in 0..<channelCount {
            let samples = channelData[channel]
            for frame in 0..<frameCount {
                let sample = samples[frame]
                sum += sample * sample
            }
        }
        let mean = sum / Float(frameCount * channelCount)
        return Double(sqrt(mean))
    }
}
