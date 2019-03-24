import Foundation

// Spec attacks:
enum SpecialAttackType: UInt8 {
    case spell         = 0
    case single        = 1
    case spellMultiple = 2
    case multiple      = 3
    
    static let aliases = ["спец.тип"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0: "заклинание",  // Заклинание
            1: "вред",        // Вред одной жертве
            2: "кзаклинание", // Заклинание всем, кто в комнате и враг
            3: "квред",       // Вред всем, кто в комнате и враг
        ])
    }
}
