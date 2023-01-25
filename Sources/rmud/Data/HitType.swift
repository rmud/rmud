import Foundation

// Message override defines
// TODO: merge with WeaponHitType?
enum HitType: UInt8  {
    case hit = 0
    case pierce = 1
    case slash = 2
    case slice = 3
    case impale = 4
    case cleave = 5
    case crush = 6
    case shoot = 7
    case scratch = 8
    case whip = 9
    case butt = 10
    case peck = 11
    case strike = 12
    case sting = 13
    case bite = 14
    case knock = 15
    
    static let aliases = ["удар1", "удар2"]
    
    var indefinite: String {
        switch (self) {
        case .hit: return "ударить"
        case .pierce: return "уколоть"
        case .slash: return "порезать"
        case .slice: return "полоснуть"
        case .impale: return "пронзить"
        case .cleave: return "рубануть"
        case .crush: return "сокрушить"
        case .shoot: return "прострелить"
        case .scratch: return "царапнуть"
        case .whip: return "хлестнуть"
        case .butt: return "боднуть"
        case .peck: return "клюнуть"
        case .strike: return "лягнуть"
        case .sting: return "ужалить"
        case .bite: return "укусить"
        case .knock: return "стукнуть"
        }
    }
    
    var past: String {
        switch (self) {
        case .hit: return "ударив"
        case .pierce: return "уколов"
        case .slash: return "порезав"
        case .slice: return "полоснув"
        case .impale: return "пронзив"
        case .cleave: return "рубанув"
        case .crush: return "сокрушив"
        case .shoot: return "прострелив"
        case .scratch: return "царапнув"
        case .whip: return "хлестнув"
        case .butt: return "боднув"
        case .peck: return "клюнув"
        case .strike: return "лягнув"
        case .sting: return "ужалив"
        case .bite: return "укусив"
        case .knock: return "стукнув"
        }
    }
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0:  "ударить",     // Рукопашный бой
            1:  "уколоть",     // Колющее оружие
            2:  "порезать",    // Режущее оружие
            3:  "полоснуть",   // Двуручное оружие
            4:  "пронзить",    // Древковое оружие
            5:  "порубить",    // Рубящее оружие
            6:  "сокрушить",   // Ударное оружие
            7:  "прострелить", // Стрелковое оружие
            8:  "поцарапать",  // Нестандартное оружие
            9:  "хлестнуть",   // Нестандартное оружие
            10: "боднуть",     // Нестандартное оружие
            11: "клюнуть",     // Нестандартное оружие
            12: "лягнуть",     // Нестандартное оружие
            13: "ужалить",     // Нестандартное оружие
            14: "укусить",     // Нестандартное оружие
            15: "стукнуть",    // Посохи
        ])
    }
}
