import Foundation

// Object frag types and saving throws
enum Frag: UInt8 {
    case magic       = 0
    case heat        = 1
    case cold        = 2
    case acid        = 3
    case electricity = 4
    case crush       = 5
    
    static let aliases = ["спец.разрушение"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0: "нет",           // Нет разрушения
            1: "огонь",         // Разрушение огнем
            2: "холод",         // Разрушение холодом
            3: "кислота",       // Разрушение кислотой
            4: "электричество", // Разрушение электричеством
            5: "удар",          // Разрушение сильным ударом
        ])
    }
}
