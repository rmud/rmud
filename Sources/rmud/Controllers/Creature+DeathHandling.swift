import Foundation

extension Creature {
    func actionsAfterDeath() {
        if race.canCry {
            informNearestRooms(
                "Ваша кровь застыла в жилах от предсмертного крика, донесшегося &."
            )
        }
        
        makeCorpse()
        
        extract(mode: .leaveItemsOnGround)
        player?.scheduleForSaving()
        players.save()
    }
    
    private func makeCorpse() {
        guard let corpsePrototype = db.corpsePrototype else {
            logError("Unable to find item prototype for corpse")
            return
        }
        let item = Item(prototype: corpsePrototype, uid: nil, db: db)
        
        let isPerson = race.isPerson
        let bodyName = isPerson ? "тел(о)" : "труп()"
        item.setNames("\(bodyName) \(nameGenitive)", isAnimate: false)
        if isPerson {
            item.synonyms.append("труп")
            item.synonyms.append("трупа")
            item.gender = .neuter
        }
        
        let itemNameNominative = item.nameNominative.full.capitalizingFirstLetter()
        item.groundDescription = "\(itemNameNominative) лежит здесь."
        item.material = .organic
        item.maxCondition = item.material.maxCondition
        item.condition = item.maxCondition
        item.weight = Int(weight)

        guard let container = item.asContainer() else {
            logError("Item used for corpse is not a container")
            item.extract(mode: .purgeAllContents)
            return
        }
        container.flags.insert(isPerson ? .personCorpse : .corpse)
        container.corpseSize = UInt8(affectedSize())
        let isEdibleMobile = mobile?.flags.contains(.edible) ?? false
        container.corpseIsEdible = isPerson || race == .animal || isEdibleMobile
        container.corpseOfVnum = mobile?.prototype.vnum
        
        guard let room = inRoom else {
            logError("Unable to create corpse for creature not in room")
            item.extract(mode: .purgeAllContents)
            return
        }

        item.put(in: room, activateDecayTimer: true, activateGroundTimer: true)
        item.decayTimerTicsLeft = isMobile ? 5 : 60
        
        putItemsToCorpse(corpse: item)
    }
    
    private func putItemsToCorpse(corpse: Item) {
        let isContainer = corpse.isContainer()

        if gold > 0 {
            defer { gold = 0 }
            
            if let coinsItem = Item(coins: gold) {
                if isContainer {
                    coinsItem.put(into: corpse)
                } else if let inRoom {
                    coinsItem.put(in: inRoom, activateDecayTimer: true, activateGroundTimer: true)
                } else {
                    logError("Trying to put coins into corpse of '\(nameNominative)' not in room")
                    coinsItem.extract(mode: .purgeAllContents)
                }
            }
        }
        
        for position in EquipmentPosition.allCases {
            guard let item = unequip(position: position) else { continue }
            if isContainer {
                item.put(into: corpse)
            } else if let inRoom {
                item.put(in: inRoom, activateDecayTimer: true, activateGroundTimer: true)
            } else {
                logError("Trying to put items into corpse of '\(nameNominative)' not in room")
                item.extract(mode: .purgeAllContents)
            }
        }
        
        while let item = carrying.first {
            item.removeFromCreature()
            if isContainer {
                item.put(into: corpse)
            } else if let inRoom {
                item.put(in: inRoom, activateDecayTimer: true, activateGroundTimer: true)
            } else {
                logError("Trying to put items into corpse of '\(nameNominative)' not in room")
                item.extract(mode: .purgeAllContents)
            }
        }
    }
}
