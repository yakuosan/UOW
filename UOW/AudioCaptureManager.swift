import AVFoundation
import Foundation

class AudioCaptureManager {
    private let audioEngine = AVAudioEngine()
    private var isRunning = false

    // Callback for audio buffer (used by SpeechManager and ImpactDetector)
    var onBuffer: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?

    func startCapture() throws {
        guard !isRunning else { return }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
            self?.onBuffer?(buffer, time)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRunning = true
        print("[AudioCapture] Started.")
    }

    func stopCapture() {
        guard isRunning else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
        print("[AudioCapture] Stopped.")
    }

    var inputNode: AVAudioInputNode {
        audioEngine.inputNode
    }

    var outputFormat: AVAudioFormat {
        audioEngine.inputNode.outputFormat(forBus: 0)
    }
}
