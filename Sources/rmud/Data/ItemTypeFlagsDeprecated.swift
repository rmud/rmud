import Foundation

// FIXME: For compatibility with old МАГАЗИН.ТОВАР which used flags instead of set<ItemType>

struct ItemTypeFlagsDeprecated: OptionSet {
    typealias T = ItemTypeFlagsDeprecated
    
    let rawValue: UInt32
    
    static let light     = T(rawValue: 1 << 0)
    static let scroll    = T(rawValue: 1 << 1)
    static let wand      = T(rawValue: 1 << 2)
    static let staff     = T(rawValue: 1 << 3)
    static let weapon    = T(rawValue: 1 << 4)
    static let treasure  = T(rawValue: 1 << 7)
    static let armor     = T(rawValue: 1 << 8)
    static let potion    = T(rawValue: 1 << 9)
    static let worn      = T(rawValue: 1 << 10)
    static let other     = T(rawValue: 1 << 11)
    static let container = T(rawValue: 1 << 14)
    static let note      = T(rawValue: 1 << 15)
    static let vessel    = T(rawValue: 1 << 16)
    static let key       = T(rawValue: 1 << 17)
    static let food      = T(rawValue: 1 << 18)
    static let money     = T(rawValue: 1 << 19)
    static let pen       = T(rawValue: 1 << 20)
    static let boat      = T(rawValue: 1 << 21)
    static let fountain  = T(rawValue: 1 << 22)
    static let spellbook = T(rawValue: 1 << 23)
    static let board     = T(rawValue: 1 << 24)
    static let receipt   = T(rawValue: 1 << 25)
    static let token     = T(rawValue: 1 << 26)
    
    static let aliases = ["магазин.товар"]
    
    var itemTypes: Set<ItemType> {
        var result: Set<ItemType> = []
        for i in 0..<rawValue.bitWidth {
            if rawValue & (1 << i) != 0 {
                guard let itemType = ItemType(rawValue: UInt8(i + 1)) else {
                    assertionFailure()
                    continue
                }
                result.insert(itemType)
            }
        }
        return result
    }
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            1: "свет",
            2: "свиток",
            3: "палочка",
            4: "жезл",
            5: "оружие",
            8: "сокровище",
            9: "доспех",
            10: "зелье",
            11: "одеваемое",
            12: "прочее",
            15: "контейнер",
            16: "записка",
            17: "сосуд",
            18: "ключ",
            19: "пища",
            20: "деньги",
            21: "прибор",
            22: "лодка",
            23: "фонтан",
            24: "книга",
            25: "доска",
            26: "расписка",
            27: "токен",
            ])
    }
}
