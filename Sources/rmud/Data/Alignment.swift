import Foundation

struct Alignment {
    enum AlignmentCategory: UInt16 {
        case veryGood             // 778...1000
        case moderatelyGood       // 434...777
        case slightlyGood         // 335...433
        case barelyGood           // 334
        case neutralBorderingGood // 333
        case neutral              // -332...332
        case neutralBorderingEvil // -333
        case barelyEvil           // -334
        case slightlyEvil         // -335...-433
        case moderatelyEvil       // -434...-777
        case veryEvil             // -778...-1000
        
        var description: String {
            switch self {
            case .veryGood:
                // "ваша душа наполнена светом и вы следуете идеалам справедливости"
                return "Ваша душа чиста, и Ваша вера в идеалы Добра непоколебима."
            case .moderatelyGood: return "Вы привержены идеалам Добра."
            case .slightlyGood: return "Вы склонны следовать идеалам Добра."
            case .barelyGood: return "Вы пока еще верите в идеалы Добра."
            case .neutralBorderingGood: return "Вы готовы поверить в идеалы Добра."
            case .neutral: return "Понятия Добра и Зла не имеют для Вас особого значения."
            case .neutralBorderingEvil: return "Мысль оказаться на стороне Зла не особенно страшит Вас."
            case .barelyEvil: return "Творимое Вами зло тяготит Вас, душа Ваша ищет иных идеалов."
            case .slightlyEvil: return "Вас не особо смущает мыль о собственных злодеяниях."
            case .moderatelyEvil: return "Вы несете миру зло, и зло несет вас к вашей цели."
            case .veryEvil: return "Ваша злая душа черна и давно неспособна на сострадание."
            }
        }
    }

    var value: Int

    static var minimumValue: Int = -1000
    static var maximumValue: Int = 1000
    
    private static let barelyGood: Alignment = 334 // Good alignment: 334 to 1000
    private static let barelyEvil: Alignment = -334 // Evil alignment: -334 to -1000
    private static let moderatelyGood = Alignment(clamping: Alignment.barelyGood.value + 100)
    private static let moderatelyEvil = Alignment(clamping: Alignment.barelyEvil.value - 100)
    private static let veryGood: Alignment = 778
    private static let veryEvil: Alignment = -778
    
    var category: AlignmentCategory {
        // Good
        if self >= Alignment.veryGood {
            return .veryGood
        } else if self >= Alignment.moderatelyGood {
            return .moderatelyGood
        } else if self > Alignment.barelyGood {
            return .slightlyGood
        } else if self == Alignment.barelyGood {
            return .barelyGood
        }
        
        // Evil:
        if self <= Alignment.veryEvil {
            return .veryEvil
        } else if self <= Alignment.moderatelyEvil {
            return .moderatelyEvil
        } else if self < Alignment.barelyEvil {
            return .slightlyEvil
        } else if self == Alignment.barelyEvil {
            return .barelyEvil
        }
        
        // Neutral:
        if value == Alignment.barelyGood.value - 1 {
            return .neutralBorderingGood
        } else if value == Alignment.barelyEvil.value + 1 {
            return .neutralBorderingEvil
        } else {
            return .neutral
        }
    }
    
    var isGood: Bool {
        return value >= Alignment.barelyGood.value
    }
    
    var isEvil: Bool {
        return value <= Alignment.barelyEvil.value
    }
    
    var isNeutral: Bool {
        return !isGood && !isEvil
    }

    init(clamping value: Int) {
        self.value = clamping(value, to: Alignment.minimumValue...Alignment.maximumValue)
    }
}

extension Alignment: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        assert(value >= Alignment.minimumValue && value <= Alignment.maximumValue)
        self.value = clamping(value, to: Alignment.minimumValue...Alignment.maximumValue)
    }
}

extension Alignment: Equatable {
    static func ==(lhs: Alignment, rhs: Alignment) -> Bool {
        return lhs.value == rhs.value
    }
}

extension Alignment: Comparable {
    static func <(lhs: Alignment, rhs: Alignment) -> Bool {
        return lhs.value < rhs.value
    }
}
