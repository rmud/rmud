import Foundation

struct SpecialAttack {
    var type: SpecialAttackType
    var frag: Frag = .magic
    var level: UInt8? = nil // if nil, user's level will be used
    var usageFlags: SpecialAttackUsageFlags = []
    var damage: Dice<Int8> = Dice()
    var spell: Spell? = nil
    var toVictim: String?
    var toRoom: String?
    var toFriends: String?
    var toFoes: String?
    
    init(type: SpecialAttackType) {
        self.type = type
    }
}
