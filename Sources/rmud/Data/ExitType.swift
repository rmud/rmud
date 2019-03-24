import Foundation

enum ExitType: UInt8 {
    case none = 0
    case door = 1
    case gate = 2
    case window = 3
    case hatch = 4
    case portal = 5
    case wicket = 6
    case grate = 7
    case smallDoor = 8
    case plate = 9
    case doors = 10
    case hole = 11
    case manhole = 12
    case passage = 13
    case gap = 14
    
    static let aliases = ["проход.тип"] +
        Direction.orderedDirections.map({ "\($0.nameForAreaFile).тип" })
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            1: "дверь",
            2: "ворота",
            3: "окно",
            4: "люк",
            5: "портал",
            6: "калитка",
            7: "решетка",
            8: "дверца",
            9: "плита",
            10: "двери",
            11: "дыра",
            12: "лаз",
            13: "проход",
            14: "пролом",
        ])
    }
    
    var nominative: String {
        switch self {
        case .none:      return "нет выхода"
        case .door:      return "дверь"
        case .gate:      return "ворота"
        case .window:    return "окно"
        case .hatch:     return "люк"
        case .portal:    return "портал"
        case .wicket:    return "калитка"
        case .grate:     return "решетка"
        case .smallDoor: return "дверца"
        case .plate:     return "плита"
        case .doors:     return "двери"
        case .hole:      return "дыра"
        case .manhole:   return "лаз"
        case .passage:   return "проход"
        case .gap:       return "пролом"
        }
    }

    // для построения сообщений о состоянии проходов:
    // окончание краткого прилагательного ("открытА","закрытО") в русском
    // глагол-связка в английском
    var adjunctiveEnd: String {
        switch self {
        case .none:      return ""
        case .door:      return "а"
        case .gate:      return "ы"
        case .window:    return "о"
        case .hatch:     return ""
        case .portal:    return ""
        case .wicket:    return "а"
        case .grate:     return "а"
        case .smallDoor: return "а"
        case .plate:     return "а"
        case .doors:     return "ы"
        case .hole:      return "а"
        case .manhole:   return ""
        case .passage:   return ""
        case .gap:       return ""
        }
    }

}
