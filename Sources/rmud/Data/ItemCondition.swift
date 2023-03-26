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
