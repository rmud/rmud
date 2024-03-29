import Foundation

// The cardinal directions: used as index to room_data.dir_option[]
enum Direction: UInt8 {
    case north = 0
    case east  = 1
    case south = 2
    case west  = 3
    case up    = 4
    case down  = 5
    
    static let aliases = ["проход.направление"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0: "север",  // Север
            1: "восток", // Восток
            2: "юг",     // Юг
            3: "запад",  // Запад
            4: "вверх",  // Вверх
            5: "вниз",   // Вниз
        ])
    }

    static let count = Direction.allDirectionsOrdered.count
    
    static var allDirectionsOrdered: [Direction] = [.north, .east, .south, .west, .up, .down]
    static var allDirections = Set(allDirectionsOrdered)

    // Mapper tries to build horizontal lines first, this way it's decisions are perceived more intuitively in most cases.
    // Use only in mapper as this behavior can be reviewed in the future.
    static var orderedByMappingPriorityDirections: [Direction] = [.west, .east, .north, .south, .up, .down]

    static var horizontalDirections: Set<Direction> = {
       return Set([.north, .east, .south, .west])
    }()
    
    var opposite: Direction {
        switch self {
        case .north: return .south
        case .east: return .west
        case .south: return .north
        case .west: return .east
        case .up: return .down
        case .down: return .up
        }
    }
    
    var singleLetter: String {
        switch self {
        case .north: return "с"
        case .east:  return "в"
        case .south: return "ю"
        case .west:  return "з"
        case .up:    return "п"
        case .down:  return "о"
        }
    }

    var singleLetterEng: String {
        switch self {
        case .north: return "n"
        case .east:  return "e"
        case .south: return "s"
        case .west:  return "w"
        case .up:    return "u"
        case .down:  return "d"
        }
    }
    
    var nameForAreaFile: String {
        switch self {
        case .north: return "север"
        case .east:  return "восток"
        case .south: return "юг"
        case .west:  return "запад"
        case .up:    return "вверх"
        case .down:  return "вниз"
        }
    }

    var name: String {
        return nameForAreaFile
    }

    var whereTo: String {
        switch self {
        case .north: return "на север"
        case .east:  return "на восток"
        case .south: return "на юг"
        case .west:  return "на запад"
        case .up:    return "наверх"
        case .down:  return "вниз"
        }
    }
    
    var whereFrom: String {
        switch self {
        case .north: return "с севера"
        case .east:  return "с востока"
        case .south: return "с юга"
        case .west:  return "с запада"
        case .up:    return "сверху"
        case .down:  return "снизу"
        }
    }

    var whereToEng: String {
        switch self {
        case .north: return "north"
        case .east:  return "east"
        case .south: return "south"
        case .west:  return "west"
        case .up:    return "up"
        case .down:  return "down"
        }
    }

    var whereAt: String {
        switch self {
        case .north: return "на севере"
        case .east:  return "на востоке"
        case .south: return "на юге"
        case .west:  return "на западе"
        case .up:    return "наверху"
        case .down:  return "внизу"
        }
    }
        
    var whereAtRightAligned: String {
        return String(repeating: " ", count:  Direction.whereAtMaxLength - whereAt.count) + whereAt
    }

    var whereAtCapitalizedAndRightAligned: String {
        return String(repeating: " ", count:  Direction.whereAtMaxLength - whereAt.count) + whereAt.capitalizingFirstLetter()
    }

    static var whereAtMaxLength: Int = {
        var maxLength = 0
        for direction in Direction.allDirections {
            if direction.whereAt.count > maxLength {
                maxLength = direction.whereAt.count
            }
        }
        return maxLength
    }()

    init?(fullName: String) {
        for direction in Direction.allDirectionsOrdered {
            if direction.name.isEqualCI(to: fullName) {
                self = direction
                return
            }
        }
        if "подняться".isEqualCI(to: fullName) {
            self = .up
        } else if "опуститься".isEqualCI(to: fullName) {
            self = .down
        }
        return nil
    }
    
    init?(abbreviatedName: String) {
        for direction in Direction.allDirectionsOrdered {
            if direction.name.hasPrefixCI(abbreviatedName) {
                self = direction
                return
            }
        }
        if "подняться".hasPrefixCI(abbreviatedName) {
            self = .up
        } else if "опуститься".hasPrefixCI(abbreviatedName) {
            self = .down
        }
        return nil
    }

    init?(singleLetterName: String) {
        for direction in Direction.allDirectionsOrdered {
            if direction.singleLetter == singleLetterName {
                self = direction
                return
            }
        }
        return nil
    }
}

extension Array {
    subscript(index: Direction) -> Element {
        get {
            return self[Int(index.rawValue)]
        }
        set {
            self[Int(index.rawValue)] = newValue
        }
    }
}
