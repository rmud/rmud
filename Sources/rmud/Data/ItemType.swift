import Foundation

// Item types: used by Item.typeFlag, range = 1 - 31! (why?)
enum ItemType: UInt8 {
    case none      = 0
    case light     = 1       // Item is a light source
    case scroll    = 2       // Item is a scroll
    case wand      = 3       // Item is a wand
    case staff     = 4       // Item is a staff
    case weapon    = 5       // Item is a weapon
    //case ranged    = 6       // Unimplemented
    //case missile   = 7       // Unimplemented
    case treasure  = 8       // Item is a treasure, not gold
    case armor     = 9       // Item is armor
    case potion    = 10      // Item is a potion
    case worn      = 11      // Item is worn
    case other     = 12      // Misc object
    //case trash     = 13      // Trash - shopkeeps won't buy
    //case trap      = 14      // Unimplemented
    case container = 15      // Item is a container
    case note      = 16      // Item is note
    case vessel    = 17      // Item is a drink container
    case key       = 18      // Item is a key
    case food      = 19      // Item is food
    case money     = 20      // Item is a pile of gold
    case pen       = 21      // Item is a pen
    case boat      = 22      // Item is a boat
    case fountain  = 23      // Item is a fountain
    case spellbook = 24      // Item is spellbook
    case board     = 25      // Item is message board
    case receipt   = 26      // Расписка на верховое животное
    case token     = 27      // Item is a token for obtaining bonus

    static let aliases = ["тип" /* , "магазин.товар" */] // FIXME: use for магазин.товар too, remove ItemTypeFlagsDeprecated
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0: "нет",
            1: "свет",        // Источник света
            2: "свиток",      // Свиток
            3: "палочка",     // Палочка
            4: "жезл",        // Посох, он же жезл, а вообще надо разделить эти типы...
            // И, кстати, чем он в игре принципиально отличается от палочки?
            5: "оружие",      // Оружие
//          6: "дальнегобоя", // (не используется)
//          7: "снаряд",      // (не используется)
            8: "сокровище",   // Сокровище
            9: "доспех",      // Доспех
            10: "зелье",      // Зелье
            11: "одеваемое",  // Одеваемый предмет
            12: "прочее",     // Прочее
//            13: "мусор",      // Мусор - не беут в магазины - избыточно, т.к. есть флаг БЕСПОЛЕЗНЫЙ
//          14: "ловушка",    // (не используется)
            15: "контейнер",  // Контейнер
            16: "записка",    // Записка
            17: "сосуд",      // Сосуд
            18: "ключ",       // Ключ
            19: "пища",       // Пища
            20: "деньги",     // Деньги
            21: "прибор",     // Письменный прибор
            22: "лодка",      // Лодка
            23: "фонтан",     // Фонтан
            24: "книга",      // Книга заклинаний или молитвеник
            25: "доска",      // Доска объявлений
            26: "расписка",   // Расписка на ездовое животное
            27: "токен",      // Токен для получения бонуса
        ])
    }
}
