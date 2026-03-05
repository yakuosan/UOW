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

    // Decay rate per second
    private let decayRate: Double = 0.3

    private var decayTimer: Timer?

    init() {
        startDecayTimer()
    }

    deinit {
        decayTimer?.invalidate()
    }

    private func startDecayTimer() {
        decayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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
        case 0...30:   newLevel = .calm
        case 31...60:  newLevel = .caution
        case 61...80:  newLevel = .warning
        default:       newLevel = .danger
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
