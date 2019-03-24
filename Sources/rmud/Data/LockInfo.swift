class LockInfo {
    var keyVnum: Int
    var level: UInt8 // lock level, 0 .. 100
    //var condition: Condition = .ok(damage: 0) // состояние, см. константы выше
    var condition: LockCondition
    var damage: UInt8
    static let maxDamage: UInt8 = 5
    
    // В предметах-контейнерах ключ был записан value[2],
    // уровень и состояние были вписаны в младшие байты value[4]
    init(prototype: RoomPrototype.ExitPrototype) {
        self.keyVnum = prototype.lockKeyVnum ?? 0
        self.level = prototype.lockLevel ?? 0
        self.condition = prototype.lockCondition ?? .ok
        self.damage = prototype.lockDamage ?? 0
    }
}
