import Foundation

enum MovementType: UInt8 {
    case walk   = 0
    case run    = 1
    case crawl  = 2
    case gallop = 3
    case roll   = 4
    case ride   = 5
    case jump   = 6
    case swim   = 7
    
    static let aliases = ["перемещение"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0: "идти",     // Пришел/ушел
            1: "бежать",   // Прибежал/убежал
            2: "ползти",   // Приполз/уполз
            3: "скакать",  // Прискакал/ускакал
            4: "катиться", // Прикатился/укатился
            5: "ехать",    // Приехал/уехал
            6: "прыгать",  // Припрыгал/упрыгал
            7: "плыть",    // Приплыл/уплыл
        ])
    }
    
    func arrivalVerb(actIndex index: Int) -> String {
        switch self {
        case .walk:   return "приш\(index)(ёл,ла,ло,ли)"
        case .run:    return "прибежал\(index)(,а,о,и)"
        case .crawl:  return "приполз\(index)(,ла,ло,ли)"
        case .gallop: return "прискакал\(index)(,а,о,и)"
        case .roll:   return "прикатил\(index)(ся,ась,ось,ись)"
        case .ride:   return "приехал\(index)(,а,о,и)"
        case .jump:   return "припрыгал\(index)(,а,о,и)"
        case .swim:   return "приплыл\(index)(,а,о,и)"
        }
    }
    
    func leavingVerb(actIndex index: Int) -> String {
        switch self {
        case .walk: return "уш\(index)(ёл,ла,ло,ли)"
        case .run:  return "убежал\(index)(,а,о,и)"
        case .crawl: return "уполз\(index)(,ла,ло,ли)"
        case .gallop: return "ускакал\(index)(,а,о,и)"
        case .roll: return "укатил\(index)(ся,ась,ось,ись)"
        case .ride: return "уехал\(index)(,а,о,и)"
        case .jump: return "упрыгал\(index)(,а,о,и)"
        case .swim: return "уплыл\(index)(,а,о,и)"
        }
    }
}
