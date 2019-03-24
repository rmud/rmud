import Foundation

// Extra object flags: used by obj_data.extra_flags
struct ItemExtraFlags: OptionSet {
    typealias T = ItemExtraFlags
    
    let rawValue: UInt32
    
    static let glow         = T(rawValue: 1 << 0)  // Item is glowing
    static let hum          = T(rawValue: 1 << 1)  // Item is humming
    static let noRent       = T(rawValue: 1 << 2)  // Item cannot be rented
    static let rechargeable = T(rawValue: 1 << 3)  // Wand doesn't decay at no charges
    static let stringed     = T(rawValue: 1 << 4)  // Weapon is stringed
    static let invisible    = T(rawValue: 1 << 5)  // Item is invisible
    static let magic        = T(rawValue: 1 << 6)  // Item is magical
    static let cursed       = T(rawValue: 1 << 7)  // Item is cursed, can't unequip
    static let bless        = T(rawValue: 1 << 8)  // Item is blessed
    static let noSell       = T(rawValue: 1 << 9)  // Shopkeepers wouldn't handle it
    static let fragile      = T(rawValue: 1 << 10) // Item disintegrates when dropped
    static let coat         = T(rawValue: 1 << 11) // Item hides other items when worn
    static let stink        = T(rawValue: 1 << 12) // Item stinks
    static let buried       = T(rawValue: 1 << 13) // Item is buried in the ground
    static let learn        = T(rawValue: 1 << 14) // Teaches the character applies
    static let uncursed     = T(rawValue: 1 << 15) // Item is uncursed, can unequip
    static let animal       = T(rawValue: 1 << 16) // Item can be equipped by animals
    static let fragrant     = T(rawValue: 1 << 17) // Item is fragrant
    static let big          = T(rawValue: 1 << 18) // Item is big - more visible, harder to steal
    // при реализации "...несет на плечах" не забывать проверять ITEM_INVISIBLE
    static let reusable     = T(rawValue: 1 << 19) // Item, such as a key, don't decay when it have been used
    static let tradable     = T(rawValue: 1 << 20) // Shops buy such items unlimited
    static let privateItem      = T(rawValue: 1 << 21) // Item can be taken only by it's owner
    static let mystery      = T(rawValue: 1 << 22) // "Знание свойств" мало что скажет о предмете
    static let animate      = T(rawValue: 1 << 23) // If item is animate
    
    static let aliases = ["псвойства"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            1: "светящийся",       // Мягко светится
            2: "шумящий",          // Тихо шумит
            3: "игровой",          // Выбрасывается при уходе на постой
            4: "перезаряжающийся", // Не разрушается при окончании зарядов
            5: "тетива",           // Каждый второй раунд тратится на натягивание тетивы
            6: "невидимый",        // Невидимый
            7: "магический",       // Магический
            8: "проклятый",        // Проклятый
            9: "благословленный",  // Благословленный
            10: "бесполезный",     // Не продается
            11: "хрупкий",         // Самоуничтожается при попадании на землю
            12: "покров",          // -Будучи надетым, скрывает под собой другие предметы
            13: "пахнущий",        // Неприятно пахнет
            14: "закопанный",      // Спрятан
            15: "обучающий",       // Носящий предмет получает умения, которых не было
            16: "снимаемый",       // Предмет можно снять, если он был проклят
            17: "животный",        // Можно носить животным
            18: "ароматный",       // Ароматный
            19: "большой",         // Предмет виден из соседних комнат,
            //-(пока нет) виден при переноске (если его можно взять),
            //-(пока нет) его сильно сложнее украсть
            20: "многоразовый",    // для ключей (и, возможно, прочих одноразовых предметов)
                                   // отменяет немедленное уничтожение
            21: "товар",           // Такие вещи покупаются магазинами без ограничений
            22: "личный",          // Предмет не может брать никто кроме его владельйа
            23: "непостижимый",    // "Знание свойств" бессильно на этот предмет
            24: "одушевленный"     // Склоняется по правилам одушевленных существительных
        ])
    }
}

