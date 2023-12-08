import Foundation

struct Attacker {
    let gamePulse: UInt64
    let uid: UInt64
    
    func creature() -> Creature? {
        db.creaturesByUid[uid]
    }
}
