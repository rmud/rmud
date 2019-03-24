import Foundation

// Take/Wear flags: used by obj_data.wear_flags
struct ItemWearFlags: OptionSet {
    typealias T = ItemWearFlags
    
    let rawValue: UInt32
    
    // 2. Добавить слоты:
    // на поясе (его можно украсть)
    // хвост (для животных) 
    static let take      = T(rawValue: 1 << 0)  // Item can be taken
    static let finger    = T(rawValue: 1 << 1)  // Can be worn on finger
    static let neck      = T(rawValue: 1 << 2)  // Can be worn on neck (jewelry)
    static let neckAbout = T(rawValue: 1 << 3)  // Can be worn around neck (armor)
    static let body      = T(rawValue: 1 << 4)  // Can be worn on body
    static let head      = T(rawValue: 1 << 5)  // Can be worn on head
    static let face      = T(rawValue: 1 << 6)  // Can be worn of face
    static let legs      = T(rawValue: 1 << 7)  // Can be worn on legs
    static let feet      = T(rawValue: 1 << 8)  // Can be worn on feet
    static let hands     = T(rawValue: 1 << 9)  // Can be worn on hands
    static let arms      = T(rawValue: 1 << 10) // Can be worn on arms
    static let shield    = T(rawValue: 1 << 11) // Can be used as a shield
    static let about     = T(rawValue: 1 << 12) // Can be worn about body
    static let back      = T(rawValue: 1 << 13) // Can be worn on a back
    static let waist     = T(rawValue: 1 << 14) // Can be worn around waist
    static let wrist     = T(rawValue: 1 << 15) // Can be worn on wrist
    static let ears      = T(rawValue: 1 << 16) // Can be worn on ears
    static let wield     = T(rawValue: 1 << 17) // Can be wielded
    static let hold      = T(rawValue: 1 << 18) // Can be held
    static let twoHand   = T(rawValue: 1 << 19) // Can be wielded in 2 hands
    
    static let aliases = ["использование"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            1:  "взять",            // Поднимается с земли
            2:  "палец",            // Надевается на пальцы
            3:  "шея",              // Надевается на шеию (укращение)
            4:  "вокругшеи",        // Надевается вокруг шеи (доспехи)
            5:  "тело",             // Надевается на тело
            6:  "голова",           // Надевается на голову
            7:  "лицо",             // Надевается на лицо
            8:  "ноги",             // Надевается на ноги
            9:  "ступни",           // Обувается
            10: "кисти",            // Надевается на кисти рук
            11: "руки",             // Надевается на руки
            12: "щит",              // Используется как щит
            13: "вокруг",           // Надевается вокруг тела
            14: "спина",            // Надевается за спину (рюкзак, крылья, ...)
            15: "пояс",             // Надевается вокруг пояса
            16: "запястье",         // Надевается вокруг запястья
            17: "уши",              // Надевается в уши (серьги)
            18: "основное",         // Используется как основное оружие
            19: "вспомогательное",  // Используется как вспомогательное оружие
            20: "двуручное"         // Используется как двуручное оружие
        ])
    }
}

