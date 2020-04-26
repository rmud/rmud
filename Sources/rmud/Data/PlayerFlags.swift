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
    static let restoreme  = PlayerFlags(rawValue: 1 << 20) // Restore hits and moves on entry
}
