import Foundation

// Restriction flags: used by obj_data.restrict_flags
// Zmey: depending on context used both for restricting and allowing something
struct ItemAccessFlags: OptionSet {
    typealias T = ItemAccessFlags
    
    let rawValue: UInt32
    
    static let good          = T(rawValue: 1 << 0) // Will zap good people
    static let evil          = T(rawValue: 1 << 1) // Will zap evil people
    static let neutral       = T(rawValue: 1 << 2) // Will zap neutral people
    static let alignments: [T] = [.good, .evil, .neutral]
    static let alignmentMask: T = alignments.reduce([]) { $0.union($1) }
    static let alignmentTotalBitsCount: Int = alignments.count
    func alignmentSetBitsCount() -> Int {
        return T.alignments.reduce(0) { $0 + (contains($1) ? 1 : 0) }
    }
    
    static let wizard        = T(rawValue: 1 << 3)  // Will zap wizards
    static let cleric        = T(rawValue: 1 << 4)  // Will zap clerics
    static let thief         = T(rawValue: 1 << 5)  // Will zap thieves
    static let warrior       = T(rawValue: 1 << 6)  // Will zap warriors
    static let classGroups: [T] = [.wizard, cleric, thief, warrior]
    static let classGroupMask: T = classGroups.reduce([]) { $0.union($1) }
    static let classGroupTotalBitsCount: Int = classGroups.count
    func classGroupSetBitsCount() -> Int {
        return T.classGroups.reduce(0) { $0 + (contains($1) ? 1 : 0) }
    }

    // FIXME
    //static let male          = T(rawValue: 1 << 14) // Uncomfortable for males
    //static let female        = T(rawValue: 1 << 15) // Uncomfortable for females
    //static let genderMask: T = [.male, .female]
    
    static let human         = T(rawValue: 1 << 16) // Uncomfortable to humans
    static let highElf       = T(rawValue: 1 << 17) // Uncomfortable to high elves
    static let wildElf       = T(rawValue: 1 << 18) // Uncomfortable to hild elves
    static let halfElf       = T(rawValue: 1 << 19) // Uncomfortable to half elves
    static let gnome         = T(rawValue: 1 << 20) // Uncomfortable to gnomes
    static let dwarf         = T(rawValue: 1 << 21) // Uncomfortable to dwarves
    static let kender        = T(rawValue: 1 << 22) // Uncomfortable to kender
    static let minotaur      = T(rawValue: 1 << 23) // Uncomfortable to minotaurs
    static let barbarian     = T(rawValue: 1 << 24) // Uncomfortable to barbarians
    static let goblin        = T(rawValue: 1 << 25) // Uncomfortable to goblins
    static let races: [T] = [.human, .highElf, .wildElf, .halfElf, .gnome, .dwarf, .kender, .minotaur, .barbarian, .goblin]
    static let raceMask: T = races.reduce([]) { $0.union($1) }
    static let raceTotalBitsCount: Int = races.count
    func raceSetBitsCount() -> Int {
        return T.races.reduce(0) { $0 + (contains($1) ? 1 : 0) }
    }

    static let all: T        = [.alignmentMask, .classGroupMask, /* .genderMask, */ .raceMask]
    
    static let aliases = ["запрет", "разрешение", "магазин.запрет"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            1: "добро",         // Добрые
            2: "зло",           // Злые
            3: "нейтральность", // Нейтральные
            4: "маг",           // Маги
            5: "жрец",          // Жрецы
            6: "плут",          // Плуты
            7: "воин",          // Воины
            //8: "*",             // (не используется)
            //9: "*",             // (не используется)
            //10: "*",            // (не используется)
            //11: "*",            // (не используется)
            //12: "*",            // (не используется)
            //13: "*",            // (не используется)
            //14: "*",            // (не используется)
            15: "мужчина",      // Мужчины // UNIMPLEMENTED
            16: "женщина",      // Женщины // UNIMPLEMENTED
            17: "человек",      // Люди
            18: "высокийэльф",  // Высокие эльфы
            19: "дикийэльф",    // Дикие эльфы
            20: "полуэльф",     // Полуэльфы
            21: "гноммеханик",  // Гномы-механики
            22: "гном",         // Гномы
            23: "кендер",       // Кендеры
            24: "минотавр",     // Минотавры
            25: "варвар",       // Варвары
            26: "гоблин",       // Гоблины
        ])
    }
}

