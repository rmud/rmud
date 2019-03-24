import Foundation

class ClassInfo {
    typealias SlotsPerCircle = [Int: Int]
    typealias EquipmentSlot = (vn: Int, pos: EquipmentPosition)
    
    var abbreviation = ""
    var namesByGender: [Gender: String] = [:]
    var classGroup: ClassGroup = .none
    var startingHitPoints = 0
    var experienceMultiplier = 0
    
    var hitPointGain = Dice<Int>()
    var maxHitPerLevel = 0
    
    var hitPointUpdates = 0
    var movementUpdates = 0
    
    var skillPercent = 0
    var spellbookType = ""
    var spellbookHimHerAccusative = ""
    var memorizationProcessName = ""
    var racesAllowed = Set<Race>()
    var alignment = 0...0
    
    var strength = 0
    var dexterity = 0
    var constitution = 0
    var intelligence = 0
    var wisdom = 0
    
    var minimumLevelForSkill = [Skill: UInt8]()
    var slotsPerCirclePerLevel = [Int: SlotsPerCircle]()
    var newbieEquipment = [EquipmentSlot]()
    
    func experience(forLevel level: UInt8) -> Int {
        guard let baseValue = baseLevelExperience[validating: Int(level)] else {
            fatalError("Requested experience for invalid level \(level)")
        }
        return baseValue * experienceMultiplier
    }
}


