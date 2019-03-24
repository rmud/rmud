import Foundation

// Message override defines
// TODO: merge with WeaponHitType?
enum HitType: UInt8  {
    case hit = 0
    case hitType1 = 1
    case hitType2 = 2
    case hitType3 = 3
    case hitType4 = 4
    case hitType5 = 5
    case hitType6 = 6
    case hitType7 = 7
    case hitType8 = 8
    case hitType9 = 9
    case hitType10 = 10
    case hitType11 = 11
    case hitType12 = 12
    case hitType13 = 13
    case hitType14 = 14
    case hitType15 = 15
    
    static let aliases = ["удар1", "удар2"]
    
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
