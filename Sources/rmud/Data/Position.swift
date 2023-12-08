import Foundation

enum Position: UInt8 {
    case dead     = 0
    case dying    = 1
    case stunned  = 2
    case sleeping = 3
    case resting  = 4
    case sitting  = 5
    case standing = 6
    
    var isAwake: Bool {
        switch self {
        case .resting, .sitting, .standing: return true
        default: return false
        }
    }

    var isSleepingOrWorse: Bool {
        return self == .sleeping || self == .stunned || self == .dying || self == .dead
    }
    
    var isStunnedOrWorse: Bool {
        return self == .stunned || self == .dying || self == .dead
    }
    
    var isStunnedOrBetter: Bool {
        return !isDyingOrDead
    }
    
    var isDyingOrDead: Bool {
        return self == .dying || self == .dead
    }
    
    var groundDescription: String {
        switch self {
        case .dead: return "безжизненно леж2(и,и,и,а)т здесь"
        case .dying: return "леж2(и,и,и,а)т здесь, истекая кровью"
        case .stunned: return "леж2(и,и,и,а)т здесь без сознания"
        case .sleeping: return "сп2(и,и,и,я)т здесь"
        case .resting: return "отдыха2(е,е,е,ю)т здесь"
        case .sitting: return "сид2(и,и,и,я)т здесь"
        case .standing: return "сто2(и,и,и,я)т здесь"
        }
    }
    
    static let aliases = ["положение", "цель.положение"]

    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0: "мертв",    // Мертв
            1: "ранен",    // Ранен
            2: "оглушен",  // Оглушен
            3: "спит",     // Спит
            4: "отдыхает", // Отдыхает
            5: "сидит",    // Сидит
            6: "стоит",    // Стоит
        ])
    }
}
