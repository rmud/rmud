import Foundation

enum CreatureCondition {
    case excellent
    case veryGood
    case good
    case fair
    case bad
    case veryBad
    case awful
    case stunned
    case dying
    case dead

    init(hitPointsPercentage percent: Int, position: Position) {
        if position == .dead {
            self = .dead
        } else if position == .dying {
            self = .dying
        } else if position == .stunned {
            self = .stunned
        } else {
            self =
                percent >= 100 ? .excellent :
                percent >= 90  ? .veryGood :
                percent >= 75  ? .good :
                percent >= 50  ? .fair :
                percent >= 25  ? .bad:
                percent >= 10  ? .veryBad :
               .awful
        }
    }
    
    func longDescriptionPrepositional(gender: Gender, color: String, normalColor: String) -> String {
        switch (self) {
        case .excellent: return "в \(color)великолепном\(normalColor) состоянии"
        case .veryGood: return "в \(color)очень хорошем\(normalColor) состоянии"
        case .good: return "в \(color)хорошем\(normalColor) состоянии"
        case .fair: return "в \(color)среднем\(normalColor) состоянии"
        case .bad: return "в \(color)плохом\(normalColor) состоянии"
        case .veryBad: return "в \(color)очень плохом\(normalColor) состоянии"
        case .awful: return "в \(color)ужасном\(normalColor) состоянии"
        case .stunned: return "\(color)оглушен\(gender.ending(",а,о,ы"))\(normalColor)"
        case .dying: return "\(color)умира\(gender.ending("ет,ет,ет,ют"))\(normalColor)"
        case .dead: return "\(color)мертв\(gender.ending(",а,о,ы"))\(normalColor)"
        }
    }

    func shortDescription(gender: Gender) -> String {
        switch self {
        case .excellent: return "великолепное"
        case .veryGood:  return "оч.хорошее"
        case .good:      return "хорошее"
        case .fair:      return "среднее"
        case .bad:       return "плохое"
        case .veryBad:   return "оч.плохое"
        case .awful:     return "ужасное"
        case .stunned:   return "оглушен\(gender.ending(",а,о,ы"))"
        case .dying:     return "умира\(gender.ending("ет,ет,ет,ют"))"
        case .dead:      return "мертв\(gender.ending(",а,о,ы"))"
        }
    }
}
