import Foundation

enum WeaponType: UInt16 {
    // Сейчас совпадают по значениям с типом ударов,
    // но некорректно их считать типами ударов:
    // типов удара больше - клюнул и т.п., и типы ударов
    // называются по другому (уколол, а не режущее и т.п.)
    case bareHand = 0
    case piercing = 1
    case cutting = 2
    case twoHanded = 3
    case pole = 4
    case slashing = 5
    case crushing = 6
    case throwing = 7
    // TODO: а всякие "клюнув" и т.д. почему не разрешить?
    case staves = 15
    
    static let aliases = [
        "оружие.тип",
        "оружие.удар", // deprecated
        "удар" // deprecated
    ]

    var skill: Skill {
        switch self {
        case .bareHand: return .bare
        case .piercing: return .piercing
        case .cutting: return .cutting
        case .twoHanded: return .twoHanded
        case .pole: return .pole
        case .slashing: return .slashing
        case .crushing: return .crushing
        case .throwing: return .throwing
        case .staves: return .staves
        }
    }
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0:  "рукопашныйбой", // Рукопашный бой
            1:  "колющее",       // Колющее оружие
            2:  "режущее",       // Режущее оружие
            3:  "двуручное",     // Двуручное оружие
            4:  "древковое",     // Древковое оружие
            5:  "рубящее",       // Рубящее оружие
            6:  "ударное",       // Ударное оружие
            7:  "стрелковое",    // Стрелковое оружие
            15: "посохи",        // Посохи
        ])
    }
}
