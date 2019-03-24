import Foundation

enum ClassId: UInt8 {
    case mage       = 0
    case mishakal   = 1
    case thief      = 2
    case fighter    = 3
    case assassin   = 4
    case ranger     = 5
    case solamnic   = 6
    case morgion    = 7
    case chislev    = 8
    case sargonnas  = 9
    case kiriJolith = 10
    // Умеет все, что умеют остальные классы
    case amalgamated = 11 // это значение будет смещаться с появлением новых
    static let count = 12
    
    static let allClasses: [ClassId] = {
        var classes = [ClassId]()
        classes.reserveCapacity(ClassId.count)
        for i in 0 ..< ClassId.count {
            classes.append(ClassId(rawValue: UInt8(i))!)
        }
        return classes
    }()

    func isPlayable() -> Bool {
        guard let masculine = info.namesByGender[.masculine],
                let feminine = info.namesByGender[.feminine] else {
            return false
        }
        guard !masculine.isEmpty && !masculine.hasPrefix("!") &&
                !feminine.isEmpty && !feminine.hasPrefix("!") else {
            return false
        }

        return true
    }
    
    static let aliases = ["профессия"]
    
    var info: ClassInfo {
        return classes.classInfoById[Int(rawValue)]
    }
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            0:   "маг",          // Маг
            1:   "мишакаль",     // Жрец Мишакаль
            2:   "вор",          // Вор
            3:   "наемник",      // Наемник
            4:   "ассассин",     // Ассассин
            5:   "следопыт",     // Следопыт
            6:   "рыцарь",       // Рыцарь Соламнии
            7:   "моргион",      // -Жрец Моргиона
            8:   "числев",       // -Жрец Числев
            9:   "саргоннас",    // -Жрец Саргоннаса
            10:  "кириджолит",   // -Жрец Кири-Джолита
            11:  "нетпрофессии", // Нет профессии
        ])
    }
}
