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

    init(hitPointsPercentage percent: Int, isStunned: Bool, isDying: Bool) {
        if isDying {
            self = .dying
        } else if (isStunned) {
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
        }
    }

    func shortDescription(gender: Gender, color: String, normalColor: String) -> String {
        let condition: String
        switch (self) {
        case .excellent: condition = "великолепное"
        case .veryGood: condition = "оч.хорошее"
        case .good: condition = "хорошее"
        case .fair: condition = "среднее"
        case .bad: condition = "плохое"
        case .veryBad: condition = "оч.плохое"
        case .awful: condition = "ужасное"
        case .stunned: condition = "оглушен\(gender.ending(",а,о,ы"))"
        case .dying: condition = "умира\(gender.ending("ет,ет,ет,ют"))"
        }
        return "\(color)\(condition)\(normalColor)"
    }
}
