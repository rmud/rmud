import Foundation

class Mobile {
    unowned var creature: Creature

    var vnum = 0
    var prototype: MobilePrototype
    var flags: MobileFlags = []
    var synonyms: [String] = []
    var groundDescription = "" // For "look at room"
    var extraDescriptions: [ExtraDescription] = [] // Optional
    // FIXME: make array of them:
    var damage1: Dice<Int8> = Dice<Int8>()
    var hitType1: HitType = .hit
    var attacks1: UInt8 = 1
    var damage2: Dice<Int8> = Dice<Int8>()
    var hitType2: HitType = .hit
    var attacks2: UInt8 = 0
    var grip: UInt8 = 0 // Interferes with rescuing and fleeing, 0..100
    var corpsePoisonLevel: UInt8 = 0 // Uneatable mobs with poison in blood
    var movementType: MovementType = .walk
    var pathName = ""
    var defaultPosition: Position = .standing
    //var maximumCountInWorld: UInt8 = 0
    //var loadChancePercentage: UInt8 = 0
    //var loadCommand: String? // FIXME: deprecated
    //var loadEquipmentWhereByVnum: [Int: EquipWhere] = [:] // Equip mob with this stuff on load
    //var loadInventoryCountByVnum: [Int: Int] = [:]
    //var loadItemsOnDeathCountByVnum: [Int: Int] = [:] // Put this stuff into corpse
    //var loadMoney: Dice<Int> = Dice<Int>() // Money dice
    var procedures: Set<Int> = []
    var weaponImmunityPercentage: UInt8 = 0
    var affects: Set<AffectType> = []
    var eventOverrides: [Event<MobileEventId>] = []

    
    weak var homeArea: Area?
    var homeRoom: Int? // В какой комнате монстр был загружен
   

    var ticsTillDisappearance: Int? // Life backtimer - for charmies
    var willDisappearEventually: Bool { return ticsTillDisappearance != nil }
    
    var shopkeeper: Shopkeeper?
    var isShopkeeper: Bool { return shopkeeper != nil }
    var stablemanNoteVnum: Int?

    init?(prototype: MobilePrototype, creature: Creature) {
        self.creature = creature

        vnum = prototype.vnum
        self.prototype = prototype
        flags = prototype.flags
        synonyms = prototype.synonyms.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        groundDescription = prototype.groundDescription
        extraDescriptions = prototype.extraDescriptions
        damage1 = prototype.damage1
        if let hitType1 = prototype.hitType1 {
            self.hitType1 = hitType1
        }
        if let attacks1 = prototype.attacks1 {
            self.attacks1 = attacks1
        }
        if let damage2 = prototype.damage2 {
            self.damage2 = damage2
        }
        if let hitType2 = prototype.hitType2 {
            self.hitType2 = hitType2
        }
        if let attacks2 = prototype.attacks2 {
            self.attacks2 = attacks2
        }
        if let grip = prototype.grip {
            self.grip = grip
        }
        if let corpsePoisonLevel = prototype.corpsePoisonLevel {
            self.corpsePoisonLevel = corpsePoisonLevel
        }
        if let movementType = prototype.movementType {
            self.movementType = movementType
        }
        self.pathName = prototype.path
        if let defaultPosition = prototype.defaultPosition {
            self.defaultPosition = defaultPosition
        }
        procedures = prototype.procedures
        if let weaponImmunityPercentage = prototype.weaponImmunityPercentage {
            self.weaponImmunityPercentage = weaponImmunityPercentage
        }
        affects = prototype.affects
        eventOverrides = prototype.eventOverrides
        shopkeeper = prototype.shopkeeper
        stablemanNoteVnum = prototype.stablemanNoteVnum
    }
    
    func isAcceptableReceipt(item: Item) -> Bool {
        guard let receipt = item.asReceipt() else { return false }
        // FIXME: Not sure if this is a good default:
        guard !receipt.stablemanVnums.isEmpty else { return true }
        return receipt.stablemanVnums.contains(vnum) || item.vnum == stablemanNoteVnum
    }
}
