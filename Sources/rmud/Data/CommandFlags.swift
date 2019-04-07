import Foundation

struct CommandFlags: OptionSet {
    typealias T = CommandFlags
    
    let rawValue: UInt8
    
    // Commands that don't reveal a hiding character and work while held (informational commands mostly)
    static let informational    = T(rawValue: 1 << 0)
    
    // Commands that can NOT be performed while char is fighting
    static let noFight          = T(rawValue: 1 << 1)
    
    // Commands that can be used even if mobile is lagged (DG Scripts)
    static let ignoreLag        = T(rawValue: 1 << 2)
    
    // Commands that cap;ln't be performed while mounted
    static let noMount          = T(rawValue: 1 << 3)
    
    // Commands that have the highest priority
    static let highPriority     = T(rawValue: 1 << 4)
    
    // Commands that will not be executed by mobs
    //static let playerOnly       = T(rawValue: 1 << 5)
    
    // Команды-направления движения, не использовать сокращения при PRF_FULL_DIRS
    static let directionCommand = T(rawValue: 1 << 6)

    // Hide from help output
    static let hidden = T(rawValue: 1 << 7)
}
