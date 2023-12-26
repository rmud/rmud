enum ItemCondition {
    case perfect
    case veryGood
    case good
    case average
    case poor
    case veryPoor
    case awful

    init(conditionPercentage percent: Int) {
        self =
            percent >= 100 ? .perfect :
            percent >= 90  ? .veryGood :
            percent >= 75  ? .good :
            percent >= 50  ? .average :
            percent >= 25  ? .poor:
            percent >= 10  ? .veryPoor :
           .awful
    }
    
    func longDescriptionPrepositional(color: String, normalColor: String) -> String {
        switch (self) {
        case .perfect: return "в \(color)великолепном\(normalColor) состоянии"
        case .veryGood: return "в \(color)очень хорошем\(normalColor) состоянии"
        case .good: return "в \(color)хорошем\(normalColor) состоянии"
        case .average: return "в \(color)среднем\(normalColor) состоянии"
        case .poor: return "в \(color)плохом\(normalColor) состоянии"
        case .veryPoor: return "в \(color)очень плохом\(normalColor) состоянии"
        case .awful: return "в \(color)ужасном\(normalColor) состоянии"
        }
    }

    var shortDescription: String {
        switch self {
        case .perfect:   return "великолепное"
        case .veryGood:  return "оч.хорошее"
        case .good:      return "хорошее"
        case .average:   return "среднее"
        case .poor:      return "плохое"
        case .veryPoor:  return "оч.плохое"
        case .awful:     return "ужасное"
        }
    }
}
