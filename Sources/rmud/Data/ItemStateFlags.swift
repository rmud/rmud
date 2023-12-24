import Foundation

struct ItemStateFlags: OptionSet {
    typealias T = ItemStateFlags
    
    let rawValue: UInt8
    
    static let bow =       T(rawValue: 1 << 0) // Состояние тетивы лука (1 - натянута)
    static let noAffects = T(rawValue: 1 << 1) // Предмет не имеет эффектов
    
    static let aliases = ["псостояния"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            1: "тетива",
            2: "нетэффектов"
        ])
    }
}

