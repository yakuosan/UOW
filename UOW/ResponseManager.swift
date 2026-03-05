import AVFoundation
import Combine
import Foundation

class ResponseManager: NSObject, ObservableObject {
    @Published var currentAdvice: String = ""
    @Published var showAdviceModal: Bool = false

    private var audioPlayer: AVAudioPlayer?
    private var currentLevel: IrritationLevel = .calm
    private var fadeTimer: Timer?

    private let adviceByLevel: [IrritationLevel: [String]] = [
        .caution: [
            "少し深呼吸してみましょう。",
            "ゆっくりと息を吐いてください。",
            "肩の力を抜いてみて。"
        ],
        .warning: [
            "今すぐ深呼吸を3回してください。",
            "目を閉じて5秒間、ゆっくり息を吸いましょう。",
            "一度その場を離れてみては？"
        ],
        .danger: [
            "⚠️ 危険な状態です。今すぐ落ち着いてください。",
            "⚠️ 誰かを傷つける前に、深呼吸を。",
            "⚠️ 水を一杯飲んで、少し休みましょう。"
        ]
    ]

    func update(for level: IrritationLevel) {
        guard level != currentLevel else { return }
        let previous = currentLevel
        currentLevel = level

        switch level {
        case .calm:
            stopMusic()
            currentAdvice = ""
            showAdviceModal = false
        case .caution:
            playMusic(named: "healing_low", volume: 0.4)
            currentAdvice = randomAdvice(for: level)
            showAdviceModal = false
        case .warning:
            playMusic(named: "healing_mid", volume: 0.7)
            currentAdvice = randomAdvice(for: level)
            showAdviceModal = true
        case .danger:
            playMusic(named: "healing_high", volume: 1.0)
            currentAdvice = randomAdvice(for: level)
            showAdviceModal = true
        }

        print("[Response] Level changed: \(previous.description) → \(level.description)")
    }

    private func randomAdvice(for level: IrritationLevel) -> String {
        adviceByLevel[level]?.randomElement() ?? ""
    }

    private func playMusic(named name: String, volume: Float) {
        // If already playing the same track, just adjust volume
        if audioPlayer?.isPlaying == true,
           let url = audioPlayer?.url,
           url.deletingPathExtension().lastPathComponent == name {
            crossfadeVolume(to: volume)
            return
        }

        // Load new track
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("[Response] Audio file not found: \(name).mp3")
            // Try .caf
            guard let cafURL = Bundle.main.url(forResource: name, withExtension: "caf") else {
                print("[Response] Audio file not found: \(name).caf either")
                return
            }
            loadAndPlay(url: cafURL, volume: volume)
            return
        }
        loadAndPlay(url: url, volume: volume)
    }

    private func loadAndPlay(url: URL, volume: Float) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0
            audioPlayer?.play()
            crossfadeVolume(to: volume)
            print("[Response] Playing: \(url.lastPathComponent)")
        } catch {
            print("[Response] Failed to play audio: \(error)")
        }
    }

    private func crossfadeVolume(to targetVolume: Float) {
        fadeTimer?.invalidate()
        guard let player = audioPlayer else { return }
        let step: Float = 0.05
        let interval: TimeInterval = 0.05

        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            if abs(player.volume - targetVolume) < step {
                player.volume = targetVolume
                timer.invalidate()
            } else if player.volume < targetVolume {
                player.volume += step
            } else {
                player.volume -= step
            }
        }
    }

    private func stopMusic() {
        fadeTimer?.invalidate()
        guard let player = audioPlayer, player.isPlaying else { return }
        crossfadeVolume(to: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.audioPlayer?.stop()
            self?.audioPlayer = nil
        }
    }
}

extension ResponseManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("[Response] Audio finished playing")
    }
}
