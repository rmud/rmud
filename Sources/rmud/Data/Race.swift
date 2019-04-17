import Foundation

enum Race: UInt8 {
    // PC races:
    case human        = 0
    case highElf      = 1
    case wildElf      = 2
    case halfElf      = 3
    case gnome        = 4
    case dwarf        = 5
    case kender       = 6
    case minotaur     = 7
    case barbarian    = 8
    case goblin       = 9
    static let playerRaces: [Race] = [
        .human, .highElf, .wildElf, .halfElf, .gnome, .dwarf, .kender,
        .minotaur, .barbarian, .goblin
    ]
    
    // NPC races:
    case person       = 20
    case monster      = 21
    case animal       = 22
    case undead       = 23
    case dragon       = 24
    case insect       = 25
    case plant        = 26
    case amorphous    = 27
    case construct    = 28
    case giant        = 29
    
    static let playerRacesCount = 10
    static let allRacesCount  = 30

    var isElf: Bool { return self == .highElf || self == .wildElf }
    
    var canTalk: Bool {
        switch self {
        case .animal, .insect, .plant, .amorphous: return false
        default: return true
        }
    }
    
    static let aliases = ["раса"]
    
    var info: RaceInfo {
        return classes.raceInfoById[Int(rawValue)]
    }

    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            
            0:  "человек",     // Человек
            1:  "высокийэльф", // Высокий эльф
            2:  "дикийэльф",   // Дикий эльф
            3:  "полуэльф",    // Полуэльф
            4:  "гноммеханик", // Гном-механик
            5:  "гном",        // Гном
            6:  "кендер",      // Кендер
            7:  "минотавр",    // Минотавр
            8:  "варвар",      // Варвар
            9:  "гоблин",      // Гоблин
            20: "персона",     // Персона
            21: "монстр",      // Монстр
            22: "животное",    // Животное (кроме тех, которые НАСЕКОМОЕ)
            23: "нежить",      // Нежить
            24: "дракон",      // Дракон
            25: "насекомое",   // Насекомое (а также пауки, черви и т.п.)
            26: "растение",    // Растение, гриб, мох и т.п.
            27: "жидкотел",    // Всякие слизи, желе, губки и прочие
            28: "устройство",  // искуственные механические и магические творения, например големы, см.также флаг МАГИЧЕСКИЙ
            29: "великан",     // гуманоиды огромных размеров, в т.ч. тролли
        ])
    }
}
