import Foundation

// Player flags: used by char_data.plr.flags
struct PlayerFlags: OptionSet {
    let rawValue: UInt32
    
    static let group      = PlayerFlags(rawValue: 1 << 0)  // Player is a member of a group      
    static let died       = PlayerFlags(rawValue: 1 << 1)  // Player died and haven't got training EQ yet
    static let frozen     = PlayerFlags(rawValue: 1 << 2)  // Player is frozen
    static let tester     = PlayerFlags(rawValue: 1 << 3)  // Player is a tester - more debug to log
    static let writing    = PlayerFlags(rawValue: 1 << 4)  // Player writing on board
    static let mailing    = PlayerFlags(rawValue: 1 << 5)  // Player is writing mail
    static let saveme     = PlayerFlags(rawValue: 1 << 6)  // Player needs to be saved
    static let siteok     = PlayerFlags(rawValue: 1 << 7)  // Player has been site-cleared
    static let unusedNosh = PlayerFlags(rawValue: 1 << 8)
    static let notitle    = PlayerFlags(rawValue: 1 << 9)  // Player may not request titles
    static let unusedDele = PlayerFlags(rawValue: 1 << 10)
    static let unusedLoad = PlayerFlags(rawValue: 1 << 11)
    static let unusedWizl = PlayerFlags(rawValue: 1 << 12)
    static let unusedNodl = PlayerFlags(rawValue: 1 << 13)
    static let invisibleStart
                          = PlayerFlags(rawValue: 1 << 14) // Player enters game wizinvis (fixme)
    static let unusedCryo = PlayerFlags(rawValue: 1 << 15)
    static let logged     = PlayerFlags(rawValue: 1 << 16) // Player's actions are logged to file
    static let rolled     = PlayerFlags(rawValue: 1 << 17) // Player's stats are finally rolled
    static let nozap      = PlayerFlags(rawValue: 1 << 18) // Player can get misaligned items
    static let unusedSavm = PlayerFlags(rawValue: 1 << 19)
    static let restoreme  = PlayerFlags(rawValue: 1 << 20) // Restore hits and moves on entry
}
