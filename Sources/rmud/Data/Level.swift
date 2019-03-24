import Foundation

class Level {
    static let maximumMortalLevel: UInt8 = 30
    
    static let hero: UInt8 = 31
    static let lesserGod: UInt8 = 32
    static let middleGod: UInt8 = 33
    static let greaterGod: UInt8 = 34
    static let implementor: UInt8 = 35
    
    static let maximum: UInt8 = 35
    
    static let minimumMapLevel = 1 // Level.lesserGod
    
    // for doWho
    static func whoLevelPrefix(level: UInt8, gender: Gender) -> String {
        switch gender {
        case .feminine:
            switch level {
            case 31: return "[     Героиня     ]"
            case 32: return "[ Младшая богиня  ]"
            case 33: return "[     Богиня      ]"
            case 34: return "[ Старшая богиня  ]"
            case 35: return "[Верховная богиня ]"
            default: break
            }
        default:
            switch level {
            case 31: return "[      Герой      ]"
            case 32: return "[   Младший бог   ]"
            case 33: return "[       Бог       ]"
            case 34: return "[   Старший бог   ]"
            case 35: return "[  Верховный бог  ]"
            default: break
            }
        }
        return "[        ?        ]"
    }
}
