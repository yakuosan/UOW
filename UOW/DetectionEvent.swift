import Foundation

enum EventType {
    case mildWord(String)
    case severeWord(String)
    case impact
}

struct DetectionEvent: Identifiable {
    let id = UUID()
    let type: EventType
    let timestamp: Date
    
    var icon: String {
        switch type {
        case .mildWord:  return "😤"
        case .severeWord: return "🤬"
        case .impact:    return "💥"
        }
    }
    
    var description: String {
        switch type {
        case .mildWord(let w):  return "軽い暴言: \(w)"
        case .severeWord(let w): return "強い暴言: \(w)"
        case .impact:           return "台パン検知"
        }
    }
    
    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: timestamp)
    }
}
