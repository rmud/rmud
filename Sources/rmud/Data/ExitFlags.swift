import Foundation

// Exit info: used in room_data.dir_option.exit_info
struct ExitFlags: OptionSet {
    typealias T = ExitFlags
    
    let rawValue: UInt32
    
    static let isDoor     = T(rawValue: 1 << 0)  // Exit is a door
    static let closed     = T(rawValue: 1 << 1)  // The door is closed
    static let locked     = T(rawValue: 1 << 2)  // The door is locked
    static let pickProof  = T(rawValue: 1 << 3)  // Lock can't be picked
    static let hidden     = T(rawValue: 1 << 4)  // Door is hidden
    static let opaque     = T(rawValue: 1 << 5)  // player can't see through
    static let noMob      = T(rawValue: 1 << 6)  // free mobiles don't want do go this way
    //static let            = T(rawValue: 1 << 7)  // only flying creatures can pass it
    //static let            = T(rawValue: 1 << 8)  // узкий - отсекает последователей
    static let assymetric = T(rawValue: 1 << 9)  // just to supress symmetry check
    static let diffKeys   = T(rawValue: 1 << 10) // just to supress symmetry check
    static let diffLocks  = T(rawValue: 1 << 11) // just to supress symmetry check
    static let noKey      = T(rawValue: 1 << 12) // just to supress key existance check
    static let barOut     = T(rawValue: 1 << 13) // Проход забаррикадирован на выход
    static let barIn      = T(rawValue: 1 << 14) // Проход забаррикадирован на вход
    // Подсказки для автомаппера:
    static let imaginary  = T(rawValue: 1 << 15) // Проход не существует
    static let torn       = T(rawValue: 1 << 16) // Комнаты по краям прохода не на одной линии (разорваны)
    
    static let aliases = ["проход.признаки"] +
        Direction.orderedDirections.map({ "\($0.nameForAreaFile).признаки" })
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            //1:    *                // (не используется)
            2: "закрыт",          // Проход открыт на сбросе области
            3: "заперт",          // Проход заперт на сбросе области
            4: "невзламывается",  // Проход нельзя взломать
            5: "спрятан",         // Проход спрятан
            6: "непрозрачный",    // Через проход не видно, кто есть в следующей комнате
            7: "недлямонстров",   // Монстры по собственной воле не ходят через этот проход
            8: "барьер",          // -Только летающие могут тут пройти
            // 9: "узкий",          // -Отсекает последователей при проходе
            //(или лучше пусть выдаст им задержку действия?)
            10: "несимметричный", // Подтверждает преднамеренную несимметричность прохода,
            // подавляя вывод сообщения на старте игры
            11: "разные_ключи",
            12: "разная_сложность",
            13: "нет_ключа",
            14: "баррикада_выход",
            15: "баррикада_вход",
            16: "мнимый",
            17: "разорван"
        ])
    }
    
}
