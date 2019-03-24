import Foundation

enum LockCondition: UInt8 {
    case ok = 0
    case jammed = 1 // заклинен
    case disabled = 2 // взломан
    case crashed = 3 // разрушен

    static let aliases = ["контейнер.замок_состояние", "проход.замок_состояние"] +
        Direction.orderedDirections.map({ "\($0.nameForAreaFile).замок_состояние" })

    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0:  "нормальное",
            1:  "заклинен",
            2:  "взломан",
            3:  "разрушен",
        ])
    }
}
