import Foundation

extension Creature {
    // Will be multilingual in future depending on Creature's chosen language
    func onOff(_ value: Bool) -> String {
        return value ? "ВКЛ" : "ВЫКЛ"
    }
    
    private func pointColor(currentValue: Int, maximumValue: Int) -> String {
        let percent = maximumValue > 0 ? (100 * currentValue) / maximumValue : 0
        
        return percentageColor(percent)
    }

    func percentageColor(_ percent: Int) -> String {
        return percent >= 75 ? nGrn() :
            percent >= 25 ? bYel() :
            nRed()
    }
    
    func arrivalVerb(actIndex index: Int) -> String {
        guard !isFlying() else {
            return "прилетел\(index)(,а,о,и)"
        }
        let movementType = mobile?.movementType ?? .walk
        return movementType.arrivalVerb(actIndex: index)
    }

    func leavingVerb(actIndex index: Int) -> String {
        guard !isFlying() else {
            return "улетел\(index)(,а,о,и)"
        }
        let movementType = mobile?.movementType ?? .walk
        return movementType.leavingVerb(actIndex: index)
    }
    
    func statusHitPointsColor() -> String {
        return pointColor(currentValue: hitPoints, maximumValue: affectedMaximumHitPoints())
    }
    
    func statusMovementColor() -> String {
        return pointColor(currentValue: movement, maximumValue: affectedMaximumMovement())
    }
    
    func areaName(fromArgument arg: String) -> String {
        return arg == "." ? (inRoom?.area?.lowercasedName ?? arg) : arg
    }
    
    func roomVnum(fromArgument arg: String) -> Int? {
        return arg == "." ? (inRoom?.vnum ?? nil) : Int(arg)
    }

    // Shows a creature to a creature
    func describe(creature: Creature) -> String {
        let isCreatureRiddenByMe: ()->Bool = {
            if let creatureRiddenBy = creature.riddenBy,
                    creatureRiddenBy.inRoom == creature.inRoom &&
                    creatureRiddenBy == self {
                return true
            }
            return false
        }
        // FIXME: по логике мне кажется здесь должно быть еще creature.riding == self
        let isCreatureRidingSomeone: ()->Bool = {
            if let creatureRiding = creature.riding,
                    creatureRiding.inRoom == creature.inRoom {
                return true
            }
            return false
        }
        
        let autostat = preferenceFlags?.contains(.autostat) ?? false
        var autostatString = ""
        var formatString = "&1" // for autostatString, which will be first text argument to act()
        if autostat {
            if let mobile = creature.mobile {
                let vnumString = Format.leftPaddedVnum(mobile.vnum)
                autostatString = "[\(vnumString)] "
            } else {
                let levelString = String(creature.level).leftExpandingTo(2, with: "0")
                let classAbbreviation = creature.classId.info.abbreviation.leftExpandingTo(3)
                autostatString = "[\(levelString) \(classAbbreviation)] "
            }
        }

        let holylight = { self.preferenceFlags?.contains(.holylight) ?? false }
        let isCreatureHiding = {
            creature.runtimeFlags.contains(.hiding) && !self.isAffected(by: .senseLife)
        }
        
        // FIXME: check mounts logic here
        // FIXME: also canSee likely checks hiding state too?
        if !isCreatureRiddenByMe() && !isCreatureRidingSomeone() && !holylight() &&
            (!canSee(creature) || isCreatureHiding()) {
            if hasLitOrGlowingItems() {
                formatString += "Блики света выдают присутствие здесь кого-то постороннего."
            } else if isCarryingOrWearingItem(withAnyOf: .hum) {
                formatString += "Краем уха Вы уловили какой-то шум."
            } else if isCarryingOrWearingItem(withAnyOf: .stink) {
                formatString += "Откуда-то исходит неприятный запах."
            } else if isCarryingOrWearingItem(withAnyOf: .fragrant) {
                formatString += "Откуда-то исходит приятный запах."
            } else {
                formatString += "Вы чувствуете здесь чье-то незримое присутствие."
            }
        } else {
            if let mobile = creature.mobile,
                !mobile.groundDescription.isEmpty && !isCreatureRiddenByMe() && !isCreatureRidingSomeone() && creature.position == mobile.defaultPosition && !creature.isFighting && !creature.isCharmed() {
                formatString += mobile.groundDescription.capitalizingFirstLetter()
            } else {
                if creature.isMobile || isCreatureRidingSomeone() || creature.isFighting {
                    formatString += "2^и"
                } else if canSee(creature), let creaturePlayer = creature.player {
                    let title = creaturePlayer.titleWithFallbackToRace(order: .raceThenName)
                    formatString += title.capitalizingFirstLetter()
                    if title.contains(",") {
                        formatString += ","
                    }
                } else {
                    formatString += "Кто-то"
                }
                
                if isCreatureRidingSomeone() {
                    formatString += " сидит здесь верхом на "
                    formatString += creature.riding == self ? "Вас." : "3п."
                } else if isCreatureRiddenByMe() {
                    formatString += " держит Вас на себе."
                } else if let creatureFighting = creature.fighting {
                    formatString += " сражается здесь с "
                    if creatureFighting == self {
                        formatString += "ВАМИ!"
                    } else if creature.inRoom == creatureFighting.inRoom {
                        formatString += "4т!"
                    } else {
                        formatString += "тем, кто уже ушел!"
                    }
                } else {
                    formatString += " \(creature.position.groundDescription)."
                }
            }
            
            if creature.isPlayer {
                if !creature.descriptors.isEmpty {
                    if isGodMode() {
                        formatString += " (неуязвим)"
                    }
                } else {
                    formatString += " (потерял2(,а,о,и) связь)"
                }
            }
            if let mobile = creature.mobile, mobile.flags.contains(.tethered) {
                formatString += " (привязан2(,а,о,ы))"
            }
            if creature.isAffected(by: .invisible) {
                formatString += " (невидим2(ый,ая,ое,ые))"
            }
            if creature.runtimeFlags.contains(.hiding) {
                formatString += " (пряч2(е,е,е,у)тся)"
            }
            
            let creatureAlignment = creature.affectedAlignment()
            if isAffected(by: .detectEvil) && creatureAlignment.isEvil {
                formatString += " (красная аура)"
            }
            if isAffected(by: .detectGood) && creatureAlignment.isGood {
                formatString += " (белая аура)"
            }
            if isAffected(by: .detectPoison) && creature.isAffected(by: .poison) {
                formatString += " (зеленая аура)"
            }
            if creature.isAffected(by: .fly) && creature.position == .standing {
                formatString += " (лета2(е,е,е,ю)т)"
            }
        }
        
        var actArguments: [ActArgument] = [.to(self),
                                           .excluding(creature)]
        if let creatureRiding = creature.riding {
            actArguments.append(.excluding(creatureRiding))
        }
        if let creatureFighting = creature.fighting {
            actArguments.append(.excluding(creatureFighting))
        }
        actArguments.append(.text(autostatString))
        var result = ""
        act(formatString, .toSleeping, actArguments) { target, output in
            assert(result.isEmpty) // should be only one target
            result = output
        }
        return result
    }
    
    // Describes the item from viewpoint of the creature
    func describe(item: Item) -> String {
        var vnumString = ""
        if preferenceFlags?.contains(.autostat) ?? false {
            vnumString = "[\(Format.leftPaddedVnum(item.vnum))] "
        }
        var formatString = "&1" // placeholder for vnumString

        if item.inRoom != nil {
            formatString.append(item.groundDescription)
        } else {
            formatString += "@1и"
            if let vessel = item.asVessel(),
                    !vessel.isEmpty &&
                    (item.carriedBy == self || item.wornBy == self) {
                formatString += " \(vessel.liquid.instrumentalWithPreposition)"
            }
        }
        
        if item.extraFlags.contains(.buried) {
            formatString += " (закопан@1(,а,о,ы))"
        }
        if item.extraFlags.contains(.invisible) {
            formatString += " (невидим@1(ый,ая,ое,ые))"
        }
        if item.extraFlags.contains(.bless) && isAffected(by: .detectMagic) {
            formatString += " (светлая аура)"
        }
        if item.extraFlags.contains(.cursed) && isAffected(by: .detectMagic) {
            formatString += " (темная аура)"
        }
        if item.extraFlags.contains(.magic) && isAffected(by: .detectMagic) {
            formatString += " (голубая аура)"
        }
        if isAffected(by: .detectPoison) {
            let isPoisonedVessel = { item.asVessel()?.isPoisoned ?? false }
            let isPoisonedFountain = { item.asFountain()?.isPoisoned ?? false }
            let isPoisonedFood = { item.asFood()?.isPoisoned ?? false }
            let isPoisonedWeapon = { item.asWeapon()?.isPoisoned ?? false }
            if isPoisonedVessel() || isPoisonedFountain() || isPoisonedFood() || isPoisonedWeapon() {
                formatString += " (зеленая аура)"
            }
        }
        if item.extraFlags.contains(.glow) {
            formatString += " (мягко свет@1(и,и,и,я)тся)"
        }
        if item.extraFlags.contains(.hum) {
            formatString += " (тихо шум@1(и,и,и,я)т)"
        }
        if item.extraFlags.contains(.stink) {
            formatString += " (неприятно пахн@1(е,е,е,у)т)"
        }
        if item.extraFlags.contains(.fragrant) {
            formatString += " (благоуха@1(е,е,е,ю)т)"
        }
   
        var result = ""
        act(formatString,
            .toSleeping, .to(self),
            .item(item), .text(vnumString)) { target, output in
                assert(result.isEmpty) // should be only one target
                result = output
        }
        return result
    }
}
