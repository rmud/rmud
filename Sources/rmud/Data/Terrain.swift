import Foundation

// Terrain types: used in room_data.sector_type
enum Terrain: UInt8 {
    case inside =         0  // Indoors
    case city =           1  // In a city
    case field =          2  // In a field
    case forest =         3  // In a forest
    case hills =          4  // In the hills
    case mountain =       5  // On a mountain
    case waterSwimmable = 6  // Swimmable water
    case waterNoSwim =   7  // Water - need a boat
    case underwater =     8  // Underwater
    case air =            9  // Air
    case longRoad =       10 // Long road
    case swamp =          11 // Swamp or similar wet unstable grond
    case spareForest =    12 // Like a FIELD with some effects of FOREST
    case jungle =         13 // Jungle - more dense, than forest, no mounted movement
    case tree =           14 // On a tree, mast, and other overhad places
    
    static let aliases = ["местность"]
    
    var isWater: Bool {
        switch self {
        case .waterSwimmable, .waterNoSwim, .underwater:
            return true
        default:
            return false
        }
    }
    
    var timeNeededSec: Int {
        switch self {
        case .inside:         return 1  // 1
        case .city:           return 2  // 1
        case .field:          return 4  // 2
        case .forest:         return 6  // 3
        case .hills:          return 8  // 4
        case .mountain:       return 12 // 6
        case .waterSwimmable: return 8  // 4
        case .waterNoSwim:    return 2  // 1
        case .underwater:     return 10 // 5
        case .air:            return 2  // 1
        case .longRoad:       return 8  // 4
        case .swamp:          return 10 // 5
        case .spareForest:    return 4  // 2
        case .jungle:         return 8  // 4
        case .tree:           return 6  // 3
        }
    }
    
    var gamePulsesNeeded: UInt64 {
        return UInt64(timeNeededSec) * 10
    }
    
    var name: String {
        switch self {
        case .inside:         return "помещение"
        case .city:           return "город"
        case .field:          return "поле"
        case .forest:         return "лес"
        case .hills:          return "холмы"
        case .mountain:       return "горы"
        case .waterSwimmable: return "мелководье"
        case .waterNoSwim:    return "глубоководье"
        case .underwater:     return "подводой"
        case .air:            return "воздух"
        case .longRoad:       return "дорога"
        case .swamp:          return "болото"
        case .spareForest:    return "редкийлес"
        case .jungle:         return "джунгли"
        case .tree:           return "надереве"
        }
    }
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0:  "помещение",    // Внутри помещения
            1:  "город",        // Улицы города
            2:  "поле",         // Открытое поле
            3:  "лес",          // Густой лес
            4:  "холмы",        // Холмы
            5:  "горы",         // Высокие горы
            6:  "мелководье",   // Вода, можно плавать
            7:  "глубоководье", // Вода, нельзя плавать
            8:  "подводой",     // Под водой
            9:  "воздух",       // В воздухе
            10: "дорога",       // Дальняя дорога
            11: "болото",       // Болото и т.п. сырая тяжелая местность
            12: "редкийлес",    // Почти как ПОЛЕ, с легкими эфектами ЛЕСа
            13: "джунгли",      // Очень густой лес, не проехать верхом, сложнее освещать соседние комнаты
            14: "надереве",     // На дереве, на мачте корабля и в т.п. ситуациях, где узко, неустойчиво и высоко
        ])
    }
}
