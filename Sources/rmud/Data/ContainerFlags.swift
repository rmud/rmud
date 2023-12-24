import Foundation

// Container flags - value[1]
struct ContainerFlags: OptionSet {
    typealias T = ContainerFlags
    
    let rawValue: UInt8
    
    static let closeable =    T(rawValue: 1 << 0) // Container can be closed
    static let pickProof =    T(rawValue: 1 << 1) // Container is pickproof
    static let closed =       T(rawValue: 1 << 2) // Container is closed
    static let locked =       T(rawValue: 1 << 3) // Container is locked
    static let corpse =       T(rawValue: 1 << 4) // Container is corpse
    static let deprecated_unused_playerCorpse = T(rawValue: 1 << 5) // Container is player's corpse
    static let personCorpse = T(rawValue: 1 << 6) // Об этом трупе писать "тело", а не "труп"
    static let edible       = T(rawValue: 1 << 7)
    
    static let aliases = ["косвойства", "контейнер.свойства"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            1: "закрывается",    // Контейнер можно закрыть
            2: "невзламывается", // Контейнер нельзя взломать
            3: "закрыт",         // Контейнер закрыт при загрузке
            4: "заперт",         // Контейнер заперт при загрузке
            5: "труп",           // В контейнер ничего нельзя класть
            //6: "*"               // Для областей не используется - труп персонажа,
            7: "съедобен"
        ])
    }
}
