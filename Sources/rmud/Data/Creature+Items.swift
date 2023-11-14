import Foundation

extension Creature {
    // Returns a rogue skill percentage modified by items
    // TODO учитывать тут и противника - условия видимости
    func rogueCarryingSkillModifier(baseSkill: Int) -> Int {
        var base = baseSkill
        
        if isCarryingMetallic() {
            base -= Int.random(in: 1...10)  // -1к10
        }
        if isCarryingOrWearingItem(withAnyOf: .glow) {
            base = (base * 3) / 4 // 75%
        }
        if isCarryingOrWearingItem(withAnyOf: .hum) {
            base = base / 2 // 50%
        }
        if isCarryingOrWearingItem(withAnyOf: [.stink, .fragrant]) {
            base = (base * 3) / 4 // 75%
        }
        
        return base
    }
    
    func isCarryingOrWearingItem(where condition: (_ item: Item)->Bool) -> Bool {
        for (_, item) in equipment {
            if condition(item) {
                return true
            }
        }
        
        for item in carrying {
            if condition(item) {
                return true
            }
        }
        
        return false
    }
    
    func isCarryingOrWearingItem(withAnyOf flags: ItemExtraFlags) -> Bool {
        return isCarryingOrWearingItem(where: { item in
            item.extraFlags.contains(anyOf: flags)
        })
    }
    
    /* Returns true if char has metallic items in his eq/inv */
    func isCarryingMetallic() -> Bool {
        // do not count weapons,light,finger,neck,ears
        for position in EquipmentPosition.wearBody {
            guard let item = equipment[position] else { continue }
            if item.hasType(.light) && item.material.isMetallic {
                return true
            }
        }
    
        for item in carrying {
            // не уверен, что тут не нужно считать оружие
            // с другой стороны, не стоит и тут считать всякие кольца
            //      if (OBJ_TYPE(obj) != ITEM_LIGHT && OBJ_TYPE(obj) != ITEM_WEAPON)
            if item.material.isMetallic {
                return true
            }
        }
    
        return false
    }
    
    func canCarryCount() -> Int {
        return 5 + (affectedDexterity() / 2) + (Int(level) / 2)
    }
    
    func canCarryOneMoreItem() -> Bool {
        return carrying.count < canCarryCount()
    }

    func canCarryWeight() -> Int {
        return Int(affectedStrength()) * 15
    }
    
    func carryingWeight() -> Int {
        var totalWeight = 0
        for item in carrying {
            totalWeight += item.weightWithContents()
        }
        return totalWeight
    }

    // FIXME: вес вещей в надеваемых контейнерах совсем не учитывается!
    // Ограничен только весовой вместимостью самого контейнера.
    func canLift(item: Item) -> Bool {
        return carryingWeight() + item.weightWithContents() <= canCarryWeight()
    }

    func canTake(item: Item, isSilent: Bool) -> Bool {
        if isGodMode() { return true }

        if item.extraFlags.contains(.privateItem) && uid == item.ownerUid {
            if !isSilent {
                act("Неведомая сила не позволила Вам взять @1в.", .to(self), .item(item))
            }
            return false
        }
        
        if item.wearFlags.contains(.take),
                let money: ItemExtraData.Money = item.extraData(),
                money.amount > 0 {
            return true
        }
        
        if !canCarryOneMoreItem() {
            if !isSilent {
                act("У Вас в руках слишком много предметов, Вы не можете удержать @1в.", .to(self), .item(item))
            }
            return false;
        }
        
        let isMyItemAlready: ()->Bool = {
            if let container = item.inContainer,
                (container.carriedBy == self || container.wornBy == self) {
                return true
            }
            return false
        }
        if !canLift(item: item) && !isMyItemAlready() {
            if !isSilent {
                act("Вы не смогли поднять @1в.", .to(self), .item(item))
            }
            return false
        } else if !item.wearFlags.contains(.take) {
            if !isSilent {
                act("@1в взять нельзя.", .to(self), .item(item))
            }
            return false
        }
        return true
    }
    
    func canWear(item: Item, at position: EquipmentPosition) -> Bool {
        guard equipment[position] == nil else {
            return false
        }
        
        switch position {
        case .twoHand:
            if equipment[.wield] != nil ||
                    equipment[.hold] != nil ||
                    equipment[.shield] != nil ||
                    equipment[.light] != nil {
                return false
            }
            return true
        case .wield:
            if equipment[.twoHand] != nil {
                return false
            }
            return true
        case .hold:
            if equipment[.twoHand] != nil ||
                    equipment[.light] != nil ||
                    (item.hasType(.weapon) && equipment[.shield] != nil) {
                return false
            }
            return true
        case .shield:
            if equipment[.twoHand] != nil ||
                    (equipment[.hold]?.hasType(.weapon) ?? false) {
                return false
            }
            return true
        case .light:
            if equipment[.twoHand] != nil || equipment[.hold] != nil {
                return false
            }
            return true
        default:
            return true
        }
    }
    
    var canUseWeapons: Bool {
        if race == .animal || race == .insect || race == .amorphous {
            guard mobile?.flags.contains(.canWield) ?? false else { return false }
        }
        return true
    }
    
    func isAlignmentMismatched(with item: Item) -> Bool {
        if isGodMode() { return false }
        
        let alignment = affectedAlignment()
        let restrictFlags = item.restrictFlags
        
        if (restrictFlags.contains(.evil) && alignment.isEvil) ||
            (restrictFlags.contains(.good) && alignment.isGood) ||
            (restrictFlags.contains(.neutral) && alignment.isNeutral) {
            return true
        }
        
        return false
    }
    
    func isUncomfortableRace(item: Item) -> Bool {
        if isGodMode() { return false }

        let restrictFlags = item.restrictFlags
        
        switch race {
        case .human:     return restrictFlags.contains(.human)
        case .highElf:   return restrictFlags.contains(.highElf)
        case .wildElf:   return restrictFlags.contains(.wildElf)
        case .halfElf:   return restrictFlags.contains(.halfElf)
        case .gnome:     return restrictFlags.contains(.gnome)
        case .dwarf:     return restrictFlags.contains(.dwarf)
        case .kender:    return restrictFlags.contains(.kender)
        case .minotaur:  return restrictFlags.contains(.minotaur)
        case .barbarian: return restrictFlags.contains(.barbarian)
        case .goblin:    return restrictFlags.contains(.goblin)
        
        case .person:    return false
        case .monster:   return false
        case .animal:    return !item.extraFlags.contains(.animal)
        case .undead:    return false
        case .dragon:    return false
        case .insect:    return false
        case .plant:     return false
        case .amorphous: return false
        case .construct: return false
        case .giant:     return false
        }
    }
    
    func isUncomfortableClass(item: Item) -> Bool {
        if isGodMode() { return false }

        let restrictFlags = item.restrictFlags

        switch classId.info.classGroup {
        case .none:    return false // FIXME: is this for mobiles?
        case .wizard:  return restrictFlags.contains(.wizard)
        case .cleric:  return restrictFlags.contains(.cleric)
        case .warrior: return restrictFlags.contains(.warrior)
        case .rogue:   return restrictFlags.contains(.thief)
        }
    }
}
