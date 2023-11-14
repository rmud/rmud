import Foundation

extension Item {
    enum ExtractMode {
        case purgeNothing
        case purgeAllContents
        case purgeOnlyMoney
    }
    
    // Extract an item from the world
    func extract(mode: ExtractMode) {
        while let firstItem = contains.first {
            
            firstItem.removeFromContainer()
            
            if mode == .purgeAllContents ||
                    (mode == .purgeOnlyMoney && firstItem.isMoney()) {
                firstItem.extract(mode: mode)
            } else if let container = inContainer {
                firstItem.put(into: container)
            } else if let carriedBy = carriedBy {
                if carriedBy.canTake(item: firstItem, isSilent: true) {
                    firstItem.give(to: carriedBy)
                } else if !carriedBy.dropAccidentally(item: firstItem) {
                    firstItem.extract(mode: mode)
                }
            } else if let wornBy = wornBy {
                if wornBy.canTake(item: firstItem, isSilent: true) {
                    firstItem.give(to: wornBy)
                } else if !wornBy.dropAccidentally(item: firstItem) {
                    firstItem.extract(mode: mode)
                }
            } else if let inRoom = inRoom {
                if extraFlags.contains(.buried) && inRoom.flags.contains(.dump) {
                    firstItem.extraFlags.insert(.stink)
                    firstItem.extraFlags.insert(.buried)
                }
                firstItem.put(in: inRoom, activateDecayTimer: true)
            } else {
                firstItem.extract(mode: mode)
            }
        }
        
        if let wornBy = wornBy, let position = wornPosition, wornBy.unequip(position: position) != self {
            logError("extract(mode:): inconsistent wornBy and wornOn")
        }

        if isInRoom {
            removeFromRoom()
        } else if isCarried {
            removeFromCreature()
        } else if isInContainer {
            removeFromContainer()
        }

        // FIXME: slow
        if let index = db.itemsInGame.firstIndex(of: self) {
            db.itemsInGame.remove(at: index)
        }
        
        let itemCount = db.itemsCountByVnum[vnum] ?? 0
        db.itemsCountByVnum[vnum] = itemCount - 1
        
        //free(self)
        // TODO: убедиться, что предметы реально деаллоцируются
    }

    func removeFromRoom() {
        guard let inRoom = inRoom else {
            logError("removeFromRoom: not in a room")
            return
        }
        
        if let index = inRoom.items.firstIndex(of: self) {
            inRoom.items.remove(at: index)
        } else {
            logError("removeFromRoom: attempt to remove an object which is not present in room")
        }
        
        // FIXME
        //if isBarricade {
        //    inRoom.collectBarricades()
        //}
        if extraFlags.contains(.buried) {
            extraFlags.remove(.buried)
        }
        
        self.inRoom = nil
    }
    
    func removeFromCreature() {
        guard let carriedBy = carriedBy else {
            logError("removeFromCreature: no one is carrying this item")
            return
        }

        // FIXME: why? this is also done when giving or dropping it
        setDecayTimerRecursively(activate: true)

        if let index = carriedBy.carrying.firstIndex(of: self) {
            carriedBy.carrying.remove(at: index)
        } else {
            logError("removeFromCreature: attempt to remove an object which the creature is not carrying")
        }
        
        // Set flag for crash-save system, but not on mobiles
        if let player = carriedBy.player {
            player.flags.insert(.saveme)
        }
        
        self.carriedBy = nil
    }
    
    func removeFromContainer() {
        guard let container = inContainer else {
            logError("Trying to remove item from container which isn't in any containers")
            return
        }
        
        if let index = container.contains.firstIndex(of: self) {
            container.contains.remove(at: index)
        } else {
            logError("removeFromContainer: inconsistent container and item states")
        }
        self.inContainer = nil
    }

    // Put an item into an item
    func put(into container: Item) {
        guard container !== self else {
            logError("insert(into:): same source and target items passed")
            return
        }
        container.contains.insert(self, at: 0)
        inContainer = container
    }
    
    // Give an object to a char
    func give(to recipient: Creature) {
        assert(inRoom == nil)

        defer {
            if let player = recipient.player {
                player.flags.insert(.saveme)
            }
        }
        
        if let money = asMoney() {
            recipient.gold += money.amount
            if money.amount > 1 {
                act("Там был#(а,и,о) # стальн#(ая,ые,ых) монет#(а,ы,).", .to(recipient), .number(money.amount))
            }
            extract(mode: .purgeAllContents)
            return
        }

        recipient.carrying.insert(self, at: 0)
        carriedBy = recipient

        guard !recipient.zapOnAlignmentMismatch(with: self) else { return }

        if recipient.isPlayer || recipient.isCharmed() {
            setDecayTimerRecursively(activate: true)
        }
    }
    
    func put(in room: Room, activateDecayTimer: Bool /* = false */) {
        assert(carriedBy == nil)

        room.items.insert(self, at: 0)
        inRoom = room
        groundTimerTicsLeft = 60

        if extraFlags.contains(.fragile) {
            if let someoneInRoom = room.creatures.first {
                act("Прикоснувшись к земле, @1*и рассыпал@1(ся,ась,ось,ись) в пыль.", .toRoom, .to(someoneInRoom), .item(self))
            }
            extract(mode: .purgeNothing)
            return
        }
        
        // предмет-БАРРИКАДА передаёт флаги проходам
        // FIXME
        //if isBarricade {
        //    room.setBarricades(from: self)
        //}
        
        if room.flags.contains(.dump) && !extraFlags.contains(.buried) {
            if let someoneInRoom = room.creatures.first {
                act("@1и упал@1(,а,о,и) в кучу мусора.", .toRoom, .to(someoneInRoom), .item(self))
            }
            extraFlags.insert(.stink)
            extraFlags.insert(.buried)
        }
        if activateDecayTimer {
            self.setDecayTimerRecursively(activate: true)
        } else {
            isDecayTimerEnabled = false
        }
    }
    
    func setDecayTimerRecursively(activate: Bool) {
        isDecayTimerEnabled = activate
        
        // For containers:
        for item in contains {
            item.setDecayTimerRecursively(activate: activate)
        }
    }
    
    func unloadNativeItem() {
        for item in contains {
            // вручную рекурсивно удаляем свои предметы
            // если у нас чужой контейнер, то наших предметов в нём быть не может
            if !item.isDecayTimerEnabled {
                item.unloadNativeItem()
            }
        }
        // FIXME: why purge money? If player gives a bag with money
        // to mobile, it will destroy the money without even adding
        // the amount to it's own money.
        extract(mode: .purgeOnlyMoney)
    }
}
