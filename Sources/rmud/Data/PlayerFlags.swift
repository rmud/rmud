import Foundation

// Player flags: used by char_data.plr.flags
struct PlayerFlags: OptionSet {
    let rawValue: UInt32
    
    static let died       = PlayerFlags(rawValue: 1 << 1)  // Player died and haven't got training EQ yet
    static let frozen     = PlayerFlags(rawValue: 1 << 2)  // Player is frozen
    static let tester     = PlayerFlags(rawValue: 1 << 3)  // Player is a tester - more debug to log
    static let saveme     = PlayerFlags(rawValue: 1 << 6)  // Player needs to be saved
    static let siteok     = PlayerFlags(rawValue: 1 << 7)  // Player has been site-cleared
    static let notitle    = PlayerFlags(rawValue: 1 << 9)  // Player may not request titles
    static let invisibleStart
                          = PlayerFlags(rawValue: 1 << 14) // Player enters game wizinvis (fixme)
    static let logged     = PlayerFlags(rawValue: 1 << 16) // Player's actions are logged to file
    static let rolled     = PlayerFlags(rawValue: 1 << 17) // Player's stats are finally rolled
    static let deprecated_unused_restoreme = PlayerFlags(rawValue: 1 << 20) // Restore hits and moves on entry
    static let reequip    = PlayerFlags(rawValue: 1 << 21) // Restore training equipment when entering game
    static let newPlayer  = PlayerFlags(rawValue: 1 << 22) // Just created

    static let aliases = ["исвойства"]
    
    static func registerDefinitions(in e: Enumerations) {
        e.add(aliases: aliases, namesByValue: [
            1: "группа",
            2: "умер",
            3: "заморожен",
            4: "тестер",
            5: "пишет",
            6: "почта",
            7: "сохранить",
            8: "разрешен",
            9: "(глюк9)",
            10: "безтитула",
            11: "(глюк11)",
            12: "(глюк12)",
            13: "(глюк13)",
            14: "(глюк14)",
            15: "незаметный",
            16: "(глюк16)",
            17: "протокол",
            18: "рассчитан",
            19: "безограничений",
            20: "(глюк19)",
            21: "восстановить"
        ])
    }
}
