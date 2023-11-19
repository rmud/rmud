import Foundation

protocol ItemExtraDataType: AnyObject {
    init()
    static var itemType: ItemType { get }
    //static var defaults: Self { get }
}

struct ItemExtraData {
    private init() {
        // Never instantiate, it's just a namespace
    }
    
    let defaultLight = Light()
    
    final class Light: ItemExtraDataType {
        static let itemType: ItemType = .light
        static let defaults = Light()
        
        var ticsLeft: Int = 0 // СВЕТ (ЗНАЧ2)
    }
    
    final class Scroll: ItemExtraDataType {
        static let itemType: ItemType = .scroll
        static let defaults = Scroll()
        
        // Used to be УРОВЕНЬ (ЗНАЧ0) and ЗАКЛ1 ЗАКЛ2 ЗАКЛ3 (ЗНАЧ1, ЗНАЧ2, ЗНАЧ3)
        var spellsAndLevels: [Spell: UInt8] = [:]
    }
    
    final class Wand: ItemExtraDataType {
        static let itemType: ItemType = .wand
        static let defaults = Wand()
        
        // Used to be УРОВЕНЬ (ЗНАЧ0) and ЗАКЛИНАНИЕ (ЗНАЧ3)
        var spellsAndLevels: [Spell: UInt8] = [:]
        var chargesLeft: UInt8 = 0 // ЗАРЯДЫ (ЗНАЧ1)
        var maximumCharges: UInt8 = 0 // ЗАРЯДЫ (ЗНАЧ2)
    }
    
    final class Staff: ItemExtraDataType {
        static let itemType: ItemType = .staff
        static let defaults = Staff()

        // Used to be УРОВЕНЬ (ЗНАЧ0) and ЗАКЛИНАНИЕ (ЗНАЧ3)
        var spellsAndLevels: [Spell: UInt8] = [:]
        var chargesLeft: UInt8 = 0 // ЗАРЯДЫ (ЗНАЧ1)
        var maximumCharges: UInt8 = 0 // ЗАРЯДЫ (ЗНАЧ2)
    }
    
    final class Weapon: ItemExtraDataType {
        static let itemType: ItemType = .weapon
        static let defaults = Weapon()
        
        // Уровень магичности. +1, +2 и т.п. Предполагалось, что могут быть монстры, которых бьёт только магическое оружие.
        var damage: Dice<Int> = Dice(number: 0, size: 0, add: 0) // ВРЕД (ЗНАЧ1 d ЗНАЧ2 + ЗНАЧ4)
        var weaponType: WeaponType = .bareHand // УДАР (ЗНАЧ3)
        var poisonLevel: UInt8 = 0 // ЯД
        var magicalityLevel: UInt8 = 0 // ВОЛШЕБСТВО (ЗНАЧ0) - не используется

        var isPoisoned: Bool { return poisonLevel != 0 }
    }

    //final class Ranged: ItemExtraDataType {
    //    static let itemType: ItemType = .ranged
    //}
    
    //final class Missile: ItemExtraDataType {
    //    static let itemType: ItemType = .missile
    //}
    
    final class Treasure: ItemExtraDataType {
        static let itemType: ItemType = .treasure
        static let defaults = Treasure()
    }
    
    final class Armor: ItemExtraDataType {
        static let itemType: ItemType = .armor
        static let defaults = Armor()

        var armorClass: Int = 0 // ПРОЧНОСТЬ (ЗНАЧ0)
        //var armor: Int // ДОСПЕХ (ЗНАЧ1) - unused
    }
    
    final class Potion: ItemExtraDataType {
        static let itemType: ItemType = .potion
        static let defaults = Potion()

        // Used to be УРОВЕНЬ (ЗНАЧ0) and ЗАКЛ1 ЗАКЛ2 ЗАКЛ3 (ЗНАЧ1, ЗНАЧ2, ЗНАЧ3)
        var spellsAndLevels: [Spell: UInt8] = [:]
    }

    final class Worn: ItemExtraDataType {
        static let itemType: ItemType = .worn
    }
    
    final class Other: ItemExtraDataType {
        static let itemType: ItemType = .other
    }
    
    //final class Trash: ItemExtraDataType { // UNUSED
    //}
    
    //final class Trap: ItemExtraDataType { // UNUSED
    //}
    
    final class Container: ItemExtraDataType {
        static let itemType: ItemType = .container
        static let defaults = Container()
        
        var capacity: Int = 0 // ВМЕСТИМОСТЬ (ЗНАЧ0)
        var flags: ContainerFlags = [] // КОСВОЙСТВА (ЗНАЧ1)
        var keyVnum: Int = 0 // КЛЮЧ (ЗНАЧ2)
        var poisonLevel: UInt8 = 0 // for ContainerFlags.corpse: ЯД (ЗНАЧ3)
        var mobileVnum: Int = 0 // for ContainerFlags.corpse: vnum of the creature (ЗНАЧ4)
        //var convenience: Int = 0 // УДОБСТВО (ЗНАЧ3) - похоже, не используется в коде
        var lockDifficulty: UInt8 = 0 // КОСЛОЖНОСТЬ (0...7 bits of ЗНАЧ4)
        // Состояние: задавалось через старшие биты КОСЛОЖНОСТЬ (8...15  bits of ЗНАЧ4),
        // 0..5 - ok, 6 - заклинен, 7 - взломан, 8 - разрушен
        var lockCondition: LockCondition = .ok
        var lockDamage: UInt8 = 0
        var corpseSize: UInt8?
        var corpseIsEdible: Bool?
        var corpseOfVnum: Int?
    }
    
    final class Note: ItemExtraDataType {
        static let itemType: ItemType = .note
        static let defaults = Note()

        var text: [String] = [] // ТЕКСТ
    }

    final class Vessel: ItemExtraDataType {
        static let itemType: ItemType = .vessel
        static let defaults = Vessel()

        var totalCapacity: UInt8 = 0 // ЕМКОСТЬ (ЗНАЧ0)
        var usedCapacity: UInt8 = 0 // ЕМКОСТЬ (ЗНАЧ1)
        var liquid: Liquid = .water // ЖИДКОСТЬ (ЗНАЧ2)
        var poisonLevel: UInt8 = 0 // ЯД (ЗНАЧ3)
        
        func fillPercentage() -> Int {
            guard totalCapacity > 0 else {
                return usedCapacity > 0 ? 100 : 0
            }
            return 100 * Int(usedCapacity) / Int(totalCapacity)
        }
        var isEmpty: Bool { return usedCapacity == 0 }
        var isFull: Bool { return usedCapacity == totalCapacity }
        var isPoisoned: Bool { return poisonLevel != 0 }
    }

    final class Key: ItemExtraDataType {
        static let itemType: ItemType = .key
        static let defaults = Key()
    }

    final class Food: ItemExtraDataType {
        static let itemType: ItemType = .food
        static let defaults = Food()

        var satiation: UInt8 = 0 // НАСЫЩЕНИЕ (ЗНАЧ0)
        var moisture: UInt8 = 0 // ВЛАЖНОСТЬ (ЗНАЧ2)
        var poisonLevel: UInt8 = 0 // ЯД (ЗНАЧ3)

        var isPoisoned: Bool { return poisonLevel != 0 }
    }

    final class Money: ItemExtraDataType {
        static let itemType: ItemType = .money
        static let defaults = Money()

        var amount: Int = 0 // СУММА (ЗНАЧ0)
    }

    final class Pen: ItemExtraDataType {
        static let itemType: ItemType = .pen
        static let defaults = Pen()
    }

    final class Boat: ItemExtraDataType {
        static let itemType: ItemType = .boat
        static let defaults = Boat()
    }

    final class Fountain: ItemExtraDataType {
        static let itemType: ItemType = .fountain
        static let defaults = Fountain()

        var totalCapacity: UInt8 = 0 // ЕМКОСТЬ (ЗНАЧ0)
        var usedCapacity: UInt8 = 0 // ЕМКОСТЬ (ЗНАЧ1)
        var liquid: Liquid = .water // ЖИДКОСТЬ (ЗНАЧ2)
        var poisonLevel: UInt8 = 0 // ЯД (ЗНАЧ3)
    
        var isEmpty: Bool { return usedCapacity == 0 }
        var isPoisoned: Bool { return poisonLevel != 0 }
    }
    
    final class Spellbook: ItemExtraDataType {
        static let itemType: ItemType = .spellbook
        static let defaults = Spellbook()

        // Was: ЗАКЛ1 ЗАКЛ2 ЗАКЛ3 (ЗНАЧ1, ЗНАЧ2, ЗНАЧ3)
        var spellsAndChances: [Spell: UInt8] = [:]
    }

    final class Board: ItemExtraDataType {
        static let itemType: ItemType = .board
        static let defaults = Board()
        
        var boardTypeIndex: Int = 0 // НОМЕР (ЗНАЧ0)
        var readLevel: UInt8 = 0 // ЧТЕНИЕ (ЗНАЧ1)
        var writeLevel: UInt8 = 0 // ЗАПИСЬ (ЗНАЧ2)
    }

    final class Receipt: ItemExtraDataType {
        static let itemType: ItemType = .receipt
        static let defaults = Receipt()

        var mountVnum: Int = 0 // СКАКУН (ЗНАЧ0)
        var stablemanVnums: Set<Int> = [] // КОНЮХ1 КОНЮХ2 КОНЮХ3 (ЗНАЧ1 ЗНАЧ2 ЗНАЧ3)
        var stableRoomVnum: Int = 0 // КОНЮШНЯ (ЗНАЧ4)
    }

    final class Token: ItemExtraDataType {
        static let itemType: ItemType = .token
        static let defaults = Token()
    }
}
