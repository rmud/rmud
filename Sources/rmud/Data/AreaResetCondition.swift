import Foundation

enum AreaResetCondition: UInt8 {
    case never = 0
    case withoutPlayers = 1
    case always = 2
    
    static let aliases = ["сброс.условие"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0: "никогда",
            1: "безигроков",
            2: "всегда",
        ])
    }

    var nominative: String {
        switch self {
        case .never:          return "никогда"
        case .withoutPlayers: return "без игроков"
        case .always:         return "всегда"
        }
    }
}

