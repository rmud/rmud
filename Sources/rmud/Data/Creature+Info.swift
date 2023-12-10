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
        var formatString = ""

        let holylight = { self.preferenceFlags?.contains(.holylight) ?? false }
        let isCreatureHiding = {
            creature.runtimeFlags.contains(.hiding) && !self.isAffected(by: .senseLife)
        }
        
        // FIXME: check mounts logic here
        // FIXME: also canSee likely checks hiding state too?
        if creature.riddenBy != self && !creature.isRiding && !holylight() &&
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
               !mobile.groundDescription.isEmpty && creature.riddenBy != self && !creature.isRiding && creature.position == mobile.defaultPosition && !creature.isFighting && !creature.isCharmed() {
                formatString += mobile.groundDescription
            } else {
                if creature.isMobile || creature.isRiding || creature.isFighting {
                    formatString += "2и"
                } else if canSee(creature), let creaturePlayer = creature.player {
                    let title = creaturePlayer.titleWithFallbackToRace(order: .raceThenName)
                    formatString += title
                    if title.contains(",") {
                        formatString += ","
                    }
                } else {
                    formatString += "Кто-то"
                }
                
                if creature.isRiding {
                    formatString += " сидит здесь верхом на "
                    formatString += creature.riding == self ? "Вас." : "3п."
                } else if creature.riddenBy == self {
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
            
            let flagsString = formatFlagsForAct(creature: creature, creatureIndex: 2)
            if !flagsString.isEmpty {
                formatString += " \(flagsString)"
            }
        }
        
        var result = ""
        act(formatString,
            .toSleeping,
            .to(self),
            .excluding(creature),
            .excluding(creature.riding ?? creature),
            .excluding(creature.fighting ?? creature)
        ) { target, output in
            assert(result.isEmpty) // should be only one target

            if preferenceFlags?.contains(.autostat) ?? false {
                var autostatString: String
                if let mobile = creature.mobile {
                    let vnumString = Format.leftPaddedVnum(mobile.vnum)
                    autostatString = "\(cMobileVnum())[\(vnumString)] \(bRed())"
                } else {
                    let levelString = String(creature.level).leftExpandingTo(2, with: "0")
                    let classAbbreviation = creature.classId.info.abbreviation.leftExpandingTo(3)
                    autostatString = "\(cMobileVnum())[\(levelString) \(classAbbreviation)] \(bRed())"
                }
                result = "\(autostatString) \(output)"
            } else {
                result = output
            }
        }   
        return result
    }
    
    // Describes the item from viewpoint of the creature
    func describe(item: Item) -> String {
        var formatString = ""

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
        
        let flagsString = formatFlagsForAct(item: item, itemIndex: 1)
        if !flagsString.isEmpty {
            formatString += " \(flagsString)"
        }

        var result = ""
        act(formatString,
            [.toSleeping, .dontCapitalize], .to(self), .item(item)
        ) { target, output in
            assert(result.isEmpty) // should be only one target
            
            if preferenceFlags?.contains(.autostat) ?? false {
                let vnumString = "\(cItemVnum())[\(Format.leftPaddedVnum(item.vnum))] \(bYel())"
                result = "\(vnumString) \(output)"
            } else {
                result = output
            }
        }
        return result
    }
    
    private func formatFlagsForAct(creature: Creature, creatureIndex: Int) -> String {
        var flags: [String] = []
        if creature.isPlayer {
            if !creature.descriptors.isEmpty {
                if isGodMode() {
                    flags.append("(неуязвим)")
                }
            } else {
                flags.append("(потерял\(creatureIndex)(,а,о,и) связь)")
            }
        }
        if let mobile = creature.mobile, mobile.flags.contains(.tethered) {
            flags.append("(привязан\(creatureIndex)(,а,о,ы))")
        }
        if creature.isAffected(by: .invisible) {
            flags.append("(невидим\(creatureIndex)(ый,ая,ое,ые))")
        }
        if creature.runtimeFlags.contains(.hiding) {
            flags.append("(пряч\(creatureIndex)(е,е,е,у)тся)")
        }
        
        let creatureAlignment = creature.affectedAlignment()
        if isAffected(by: .detectEvil) && creatureAlignment.isEvil {
            flags.append("(красная аура)")
        }
        if isAffected(by: .detectGood) && creatureAlignment.isGood {
            flags.append("(белая аура)")
        }
        if isAffected(by: .detectPoison) && creature.isAffected(by: .poison) {
            flags.append("(зеленая аура)")
        }
        if creature.isAffected(by: .fly) && creature.position == .standing {
            flags.append("(лета\(creatureIndex)(е,е,е,ю)т)")
        }
        return flags.joined(separator: " ")
    }
    
    private func formatFlagsForAct(item: Item, itemIndex: Int) -> String {
        var flags: [String] = []
        if item.extraFlags.contains(.buried) {
            flags.append("(закопан@\(itemIndex)(,а,о,ы))")
        }
        if item.extraFlags.contains(.invisible) {
            flags.append("(невидим@\(itemIndex)(ый,ая,ое,ые))")
        }
        if item.extraFlags.contains(.bless) && isAffected(by: .detectMagic) {
            flags.append(" (светлая аура)")
        }
        if item.extraFlags.contains(.cursed) && isAffected(by: .detectMagic) {
            flags.append(" (темная аура)")
        }
        if item.extraFlags.contains(.magic) && isAffected(by: .detectMagic) {
            flags.append(" (голубая аура)")
        }
        if isAffected(by: .detectPoison) {
            let isPoisonedVessel = { item.asVessel()?.isPoisoned ?? false }
            let isPoisonedFountain = { item.asFountain()?.isPoisoned ?? false }
            let isPoisonedFood = { item.asFood()?.isPoisoned ?? false }
            let isPoisonedWeapon = { item.asWeapon()?.isPoisoned ?? false }
            if isPoisonedVessel() || isPoisonedFountain() || isPoisonedFood() || isPoisonedWeapon() {
                flags.append("(зеленая аура)")
            }
        }
        if item.extraFlags.contains(.glow) {
            flags.append("(мягко свет@\(itemIndex)(и,и,и,я)тся)")
        }
        if item.extraFlags.contains(.hum) {
            flags.append("(тихо шум@\(itemIndex)(и,и,и,я)т)")
        }
        if item.extraFlags.contains(.stink) {
            flags.append("(неприятно пахн@\(itemIndex)(е,е,е,у)т)")
        }
        if item.extraFlags.contains(.fragrant) {
            flags.append("(благоуха@\(itemIndex)(е,е,е,ю)т)")
        }
        return flags.joined(separator: " ")
    }
}
