import Foundation

// Player flags: used by char_data.plr.flags
struct RoomFlags: OptionSet {
    typealias T = RoomFlags
    
    let rawValue: UInt32
    
    static let dark           = T(rawValue: 1 << 0)   // Dark                            
    static let death          = T(rawValue: 1 << 1)   // Death trap                      
    static let nomob          = T(rawValue: 1 << 2)   // Mobs aren't allowed             
    static let indoors        = T(rawValue: 1 << 3)   // Indoors                         
    static let peaceful       = T(rawValue: 1 << 4)   // Violence not allowed            
    static let soundproof     = T(rawValue: 1 << 5)   // Shouts, tells blocked           
    static let nofootmarks    = T(rawValue: 1 << 6)   // Can't leave footmarks here      
    static let nomagic        = T(rawValue: 1 << 7)   // Magic not allowed               
    static let tunnel         = T(rawValue: 1 << 8)   // Room for only 1 character       
    static let unusedTiny     = T(rawValue: 1 << 9)
    static let unusedGodRoom  = T(rawValue: 1 << 10)
    static let dangerous      = T(rawValue: 1 << 11)  // Not a 'word of recall' destination 
    static let unusedHouse2   = T(rawValue: 1 << 12)
    static let unusedAtrium   = T(rawValue: 1 << 13)
    static let light          = T(rawValue: 1 << 14)  // Room is always lit              
    static let bfsMark        = T(rawValue: 1 << 15)  // fixme
    static let nomount        = T(rawValue: 1 << 16)  // Mounts can't enter this room    
    static let recuperate     = T(rawValue: 1 << 17)  // Hit regen doubled in this room  
    static let mist           = T(rawValue: 1 << 18)  // Hidden for scan and look dir    
    static let noteleport     = T(rawValue: 1 << 19)  // Can't tele/relo/door here       
    static let laboratory     = T(rawValue: 1 << 20)  // Wizards' mem time doubled       
    static let altar          = T(rawValue: 1 << 21)  // Clerics' mem time doubled       
    static let spin           = T(rawValue: 1 << 22)  // Dirs are random                 
    static let dump           = T(rawValue: 1 << 23)  // Room is dump                    
    static let wilderness     = T(rawValue: 1 << 24)  // Dirs are random without orient  
    static let good           = T(rawValue: 1 << 25)  // Bonuses apply only to good char 
    static let neutral        = T(rawValue: 1 << 26)  // Bonuses apply only to neutral   
    static let evil           = T(rawValue: 1 << 27)  // Bonuses apply only to evil      
    static let noisy          = T(rawValue: 1 << 28)  // Can't memorize spells here      
    
    static let aliases = ["ксвойства"]
    static let names: [Int64: String] = [
        1:  "темнота",        // Всегда темная
        2:  "смерть",         // При входе персонаж умирает
        3:  "нетмонстров",    // Монстры не могут зайти
        4:  "внутри",         // Внутри помещения
        5:  "мир",            // Мирная
        6:  "нетсвязи",       // Коммуникации наружу и снаружи не работают
        7:  "нетследов",      // Умение ВЫСЛЕДИТЬ не работает
        8:  "нетмагии",       // Магия не работает
        9:  "узкая",          // Только один персонаж может быть здесь одновременно
        //10: "*",              // (не используется)
        11: "секрет",         // -Секретная комната
        12: "опасность",      // Не может быть точкой прибытия "слова возвращения"
        //13: "*",              // (не используется)
        //14: "*",              // (не используется)
        15: "свет",           // -Всегда светлая
        //16: "*",              // (не используется)
        17: "нетездовых",     // Ездовые существа не могут зайти
        18: "отдых",          // Комната отдыха
        19: "туман",          // Не видно соседних комнат, даже если там светло
        20: "нетперемещения", // Магические способы перемещения не работают
        21: "лаборатория",    // Ускоренное заучивание для магов
        22: "алтарь",         // Ускоренное заучивание для священников
        23: "вращение",       // Любой выход ведет в случайный
        24: "свалка",         // Любой упавший предмет пропадает
        25: "природа",        // Дикая природа, ВРАЩЕНИЕ без ориентирования
        26: "добро",          // ЛАБОРАТОРИЯ и АЛТАРЬ для добрых
        27: "нейтральность",  // ЛАБОРАТОРИЯ и АЛТАРЬ для нейтральных
        28: "зло",            // ЛАБОРАТОРИЯ и АЛТАРЬ для злых
        29: "шум",            // В комнате не заучиваются заклинания
    ]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: names)
    }
}

extension RoomFlags: CustomStringConvertible {
    var description: String {
        let result = T.names
            .filter { k, v in contains(T(rawValue: 1 << (UInt32(k) - 1))) }
            .map { (k, v) in v }
            .joined(separator: ", ")
        return !result.isEmpty ? result : "нет"
    }
}
