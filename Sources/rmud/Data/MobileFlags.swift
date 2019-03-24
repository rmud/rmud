import Foundation

// Mobile flags: used by char_data.mob.flags
struct MobileFlags: OptionSet {
    typealias T = MobileFlags
    
    let rawValue: UInt32
    
    static let returning    = T(rawValue: 1 << 0)  // При сбросе, если жив, возвращается в начальную комнату
    static let sentinel     = T(rawValue: 1 << 1)  // Will not move or flee               
    static let scavenger    = T(rawValue: 1 << 2)  // Mob picks up stuff on the ground    
    static let maniac       = T(rawValue: 1 << 3)  // - still unused really                 
    static let weaponbreak  = T(rawValue: 1 << 4)  // Damage weapon severely (statue etc) 
    static let aggressive   = T(rawValue: 1 << 5)  // Mob hits players in the room        
    static let agroSlow     = T(rawValue: 1 << 6)  // Атакует не сразу при входе персонажа, а в боевой пульс 
    static let tethered     = T(rawValue: 1 << 7)  // Mob is a tethered mount             
    static let aggrEvil     = T(rawValue: 1 << 8)  // Attack evil players                 
    static let aggrGood     = T(rawValue: 1 << 9)  // Attack good players                 
    static let aggrNeutral  = T(rawValue: 1 << 10) // Attack neutral players              
    static let revenge      = T(rawValue: 1 << 11) // Revenge attackers                   
    static let helper       = T(rawValue: 1 << 12) // Attack players fighting mobs        
    static let magical      = T(rawValue: 1 << 13) // волшебный, страдает от диспелов...
    static let holy         = T(rawValue: 1 << 14) // Mob is holy (FIXME)                 
    static let unholy       = T(rawValue: 1 << 15) // Mob is unholy (FIXME)               
    static let incorporeal  = T(rawValue: 1 << 16) // Mob is incorporeal, no corpse (FIXME не должно быть связано с бестелесностью
    static let guildmaster  = T(rawValue: 1 << 17) // Mob is a guildmaster                
    static let waterOnly    = T(rawValue: 1 << 18) // Mob can live only in water (FIXME)  
    static let mountable    = T(rawValue: 1 << 19) // Mob is mountable                    
    static let peacekeeper  = T(rawValue: 1 << 20) // Mob will assist to kflagged chars   
    static let xenophobiac  = T(rawValue: 1 << 21) // Attacks players and mobs            
    static let canWield     = T(rawValue: 1 << 22) // может вооружаться - для животных и прочих, кто в норме не могут 
    static let hunter       = T(rawValue: 1 << 23) // Hunts everyone matching in zone     
    static let help_align   = T(rawValue: 1 << 24) // Помогает только монстрам с теми же наклонностями
    static let paranoid     = T(rawValue: 1 << 25) // Leaves room when someone enters in  
    static let eatable      = T(rawValue: 1 << 26) // Mob's meat is edible if monster race
    static let beacon       = T(rawValue: 1 << 27) // Players can teleport to it          
    static let receptionist = T(rawValue: 1 << 28) // Mob is receptionist                 
    static let banker       = T(rawValue: 1 << 29) // Mob is banker                       
    static let postmaster   = T(rawValue: 1 << 30) // Mob is postmaster, currently unused
    static let inanimate    = T(rawValue: 1 << 31) // If mobile is inanimate
    static let switchTarget = T(rawValue: 1 << 32) // Switches targets during battle

    static let allMobAgro: T = [.aggressive, .aggrEvil, .aggrGood, .aggrNeutral]
    
    static let aliases = ["мсвойства"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            1:  "возвращение",      // при сбросе области возвращается на стартовую позицию
            2:  "неподвижный",      // Нахождение в одной комнате
            3:  "дворник",          // Подбирание предметов с земли
            4:  "маньяк",           // Действие каждый раунд
            5:  "твердый",          // Поломка оружия с каждым ударом
            6:  "агрессор",         // Нападение на персонажей
            7:  "задержка",         // -Задержка агрессии
            //8:  "*                // (не используется - в игре проставляется привязанным животьным)
            9:  "агрзло",           // Нападение на злых персонажей
            10: "агрдобро",         // Нападение на добрых персонажей
            11: "агрнейтральность", // Нападение на нейтральных персонажей
            12: "память",           // Нападение на агрессоров
            13: "помощник",         // Вступление в любой бой на стороне монстра
            14: "волшебный",        // -Уязвим для "рассеяния магии" + еще некоторые свойства
            15: "святой",           // -Уязвимость к ИЗГНАТЬ злых и нечистым заклинаниям
            16: "нечистый",         // -Уязвимость к ИЗГНАТЬ добрых и святым заклинаниям
            17: "бестелесный",      // Смерть без образования трупа
            18: "учитель",          // Учитель
            19: "водный",           // -Запрет для выхода из МЕЛКОВОДЬЕ и ГЛУБОКОВОДЬЕ
            20: "ездовой",          // Пригодность для верховой езды
            21: "защитник",         // Вступление в любой бой против агрессора
            22: "ксенофоб",         // Нападение на всех подряд
            23: "вооружение",       // Может использовать оружие (для тех, кто в норме не может, например, обезьянам такой флаг нужен)
            24: "охотник",          // -Поиск вошедших в область персонажей
            25: "помощник_своим",   // Вступление в бой на стороге монстра таких же наклонностей
            26: "параноик",         // Выход из комнаты при входе персонажей
            27: "съедобен",         // Труп *монстра* (по типу существа) пригоден в пищу
            28: "маяк",             // На монстра можно телепортироваться (назначается ТОЛЬКО старшими богами!)
            29: "хозяин",           // Хозяин
            30: "банкир",           // Банкир
            31: "почтальон",        // -Почтальон
            32: "неодушевленный",   // Склоняется по правилам неодушевленных существительных"
            33: "переключение"
        ])
    }
    
}
