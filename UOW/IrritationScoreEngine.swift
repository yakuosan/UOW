import Foundation
import Combine

enum IrritationLevel {
    case calm       // 0–30
    case caution    // 31–60
    case warning    // 61–80
    case danger     // 81–100

    var description: String {
        switch self {
        case .calm:    return "平常"
        case .caution: return "注意"
        case .warning: return "警告"
        case .danger:  return "危険"
        }
    }

    var color: String {
        switch self {
        case .calm:    return "green"
        case .caution: return "yellow"
        case .warning: return "orange"
        case .danger:  return "red"
        }
    }
}

class IrritationScoreEngine: ObservableObject {
    @Published var score: Double = 0.0
    @Published var level: IrritationLevel = .calm

    // Score increments
    private let mildWordScore: Double = 5.0
    private let severeWordScore: Double = 15.0
    private let impactScore: Double = 10.0

    // 0.1秒ごとに0.03ずつ減衰（= 毎秒0.3と同じ速度、でも10倍滑らか）
    private let decayRate: Double = 0.03
    private let timerInterval: TimeInterval = 0.1

    private var decayTimer: Timer?

    init() {
        startDecayTimer()
    }

    deinit {
        decayTimer?.invalidate()
    }

    private func startDecayTimer() {
        decayTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            self?.applyDecay()
        }
    }

    private func applyDecay() {
        DispatchQueue.main.async {
            self.score = max(0, self.score - self.decayRate)
            self.updateLevel()
        }
    }

    func addMildWord() {
        DispatchQueue.main.async {
            self.score = min(100, self.score + self.mildWordScore)
            self.updateLevel()
            print("[Score] Mild word detected. Score: \(self.score)")
        }
    }

    func addSevereWord() {
        DispatchQueue.main.async {
            self.score = min(100, self.score + self.severeWordScore)
            self.updateLevel()
            print("[Score] Severe word detected. Score: \(self.score)")
        }
    }

    func addImpact() {
        DispatchQueue.main.async {
            self.score = min(100, self.score + self.impactScore)
            self.updateLevel()
            print("[Score] Impact detected. Score: \(self.score)")
        }
    }

    private func updateLevel() {
        let newLevel: IrritationLevel
        switch score {
        case 0...50:   newLevel = .calm     // 平常（無反応）
        case 51...70:  newLevel = .caution  // 注意（視覚的警告のみ）
        case 71...90:  newLevel = .warning  // 警告（ヒーリング音楽）
        default:       newLevel = .danger   // 危険（音楽 + 強制深呼吸）
        }
        if newLevel != level {
            level = newLevel
        }
    }

    func reset() {
        DispatchQueue.main.async {
            self.score = 0
            self.level = .calm
        }
    }
}

