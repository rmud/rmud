import Foundation

extension Creature {
    func equip(item: Item, position: EquipmentPosition) {
        guard !item.isCarried else {
            logError("equip(item:): item is carried when equipping")
            return
        }
        guard !item.isInRoom else {
            logError("equip(item:): item is in room when equipping")
            return
        }
        
        guard equipment[position] == nil else {
            logError("equip(item:): creature is already equipped: \(nameNominative): \(item.nameNominative)")
            return
        }
        
        equipment[position] = item
        item.wornBy = self
        item.wornPosition = position
        
        guard !zapOnAlignmentMismatch(with: item) else { return }
        
        // FIXME: update to new affects system
        //affbit_update(NULL, ch, true);
        
        // Usually before equipping an item it is given to creature first
        // (thus triggering saving to disk), but this is for cases
        // where it's equipped directly by some strange (magical?) way
        // without going to inventory first:
        if let player = player {
            player.flags.insert(.saveme)
        }
        if isPlayer || (isFollowing && isCharmed()) {
            item.setDecayTimerRecursively(activate: true)
        }
    }
    
    func unequip(position: EquipmentPosition) -> Item? {
        guard let item = equipment[position] else { return nil }
        
        item.wornBy = nil
        item.wornPosition = nil
        
        equipment[position] = nil
        
        // FIXME: is it really needed? It's being activated when giving/dropping item too
        item.setDecayTimerRecursively(activate: true)
        
        return item
    }

    // FIXME: inconsistency in wear condition checks
    // with equip(), but both are used in Mobile.loadEquipment()
    func wear(item: Item, isSilent: Bool) {
        var wearFlags = item.wearFlags
        wearFlags.remove(.take)
        wearFlags.remove(.hold)
        
        guard !wearFlags.isEmpty && !item.hasType(.weapon) else {
            if !isSilent {
                act("@1и никуда не надевается.", .to(self), .item(item))
            }
            return
        }

        guard !item.isWorn else {
            if !isSilent {
                act("@1и уже надет.", .to(self), .item(item))
            }
            return
        }
        
        let flagsAndPositions: [(flag: ItemWearFlags, positions: [EquipmentPosition])] = [
            (.finger, [.fingerRight, .fingerLeft]),
            (.neck, [.neck]),
            (.neckAbout, [.neckAbout]),
            (.body, [.body]),
            (.head, [.head]),
            (.face, [.face]),
            (.legs, [.legs]),
            (.feet, [.feet]),
            (.hands, [.hands]),
            (.arms, [.arms]),
            (.shield, [.shield]),
            (.about, [.about]),
            (.back, [.back]),
            (.waist, [.waist]),
            (.ears, [.ears]),
            (.wrist, [.wristRight, .wristLeft])
        ]

        for (flag, positions) in flagsAndPositions {
            guard item.wearFlags.contains(flag) else { continue }
            performWear(item: item, positions: positions, isSilent: isSilent)
            if item.isWorn { break }
        }
    }
    
    //static const bitv32 wear_bitvectors[] = {
    //    ITEM_WEAR_TAKE, ITEM_WEAR_FINGER, ITEM_WEAR_FINGER, ITEM_WEAR_NECK,
    //    ITEM_WEAR_NECK_ABOUT, ITEM_WEAR_BODY, ITEM_WEAR_HEAD, ITEM_WEAR_FACE,
    //    ITEM_WEAR_LEGS, ITEM_WEAR_FEET, ITEM_WEAR_HANDS, ITEM_WEAR_ARMS,
    //    ITEM_WEAR_SHIELD, ITEM_WEAR_ABOUT, ITEM_WEAR_BACK, ITEM_WEAR_WAIST,
    //  ITEM_WEAR_WRIST, ITEM_WEAR_WRIST, ITEM_WEAR_EARS, ITEM_WEAR_WIELD,
    //  ITEM_WEAR_TAKE /* ITEM_WEAR_HOLD */, ITEM_WEAR_TWOHAND
    //};
    //FIXME arilou:
    // Тут у нас большая фигня с тем, что свиткам, бутылкам и проч. мы не ставим явную
    // возможность держать их, а потом при использовании, чтобы их можно было взять во
    // вторую руку, нам нужно в этом векторе на позиции WEAR_HOLD ставить ITEM_WEAR_TAKE
    // надо либо явно требовать ставить это держание таким предметам, либо просто в
    // парcере автоматически добавлять его.
    func performWear(item: Item, positions: [EquipmentPosition], isSilent: Bool) {
        let sendCantWear = {
            if isSilent { return }
            act("@1в надеть на эту часть тела нельзя.",
                .to(self), .item(item))
        }
        
        // first, make sure that the wear position is valid
        for position in positions {
            guard let bodypart = bodypartInfoByEquipmentPosition[position] else {
                logError("performWear(): invalid bodypart \(position.rawValue)")
                sendCantWear()
                return
            }
            if !item.wearFlags.contains(bodypart.itemWearFlags) {
                if let mobile = mobile {
                    logError("Mobile \(mobile.vnum) (\(nameNominative)) is trying to wear item  \(item.vnum) (\(item.nameNominative)) in position \(position.rawValue)")
                }
                sendCantWear()
                return
            }
        }
        
        // For neck, finger, and wrist, try pos 2 if pos 1 is already full
        let position = positions.first(where: { position in
            equipment[position] == nil
        }) ?? positions.first
        
        guard let position else {
            logError("performWear(): invalid positions \(positions)")
            sendCantWear()
            return
        }
        
        guard equipment[position] == nil else {
            act(position.alreadyWearing, .to(self), .item(item))
            return
        }
        
        let useTake = position == .twoHand ||
            position == .wield ||
            position == .hold ||
            position == .light ||
            position == .shield
        if useTake && !canWear(item: item, at: position) {
            switch position {
            case .twoHand, .wield:
                act("1т нельзя вооружиться, поскольку у Вас заняты руки.", .to(self), .item(item))
            case .hold, .light:
                act("1в нельзя взять во вторую руку, поскольку она занята.", .to(self), .item(item))
            case .shield:
                act("1в нельзя пристегнуть на руку, поскольку она занята.", .to(self), .item(item))
            default:
                send("У Вас заняты руки.")
            }
            return
        }

        if !isSilent {
            var shouldCancelAction: Bool = false
            sendWearMessage(item: item, position: position, shouldCancelAction: &shouldCancelAction)
            guard !shouldCancelAction else { return }
        }

        if isUncomfortableRace(item: item) {
            act("Увы, @1и сделан@1(,а,о,ы) явно не под Ваши размеры.", .to(self), .item(item))
            act("1*и недовольно поерзал1(,а,о,и) и прекратил1(,а,о,и) пользоваться @1т.", .excluding(self), .item(item))
            return
        } else if isUncomfortableClass(item: item) {
            act("Увы, @1и для Вас неудоб@1(ен,на,но,ны).",
                .to(self), .item(item))
            act("1*и к своему разочарованию убедил1(ся,ась,ось,ись), что @1и для 1(него,нее,него,них) неудоб@1(ен,на,но,ны).",
                .toRoom, .excluding(self), .item(item))
            return
        } else {
            if item.isCarried {
                item.removeFromCreature()
            }
            equip(item: item, position: position)
            if item.hasType(.weapon) && weaponEfficiencyPercents(for: item, in: position) < 100 {
                act("Вы почувствовали, что @1и слишком тяжел@1(,а,о,ы) для Вас.", .to(self), .item(item))
            }
            if item.extraFlags.contains(.stringed) {
                // FIXME: check that removing/wearing bow can't be used to shot faster
                item.stateFlags.remove(.bow)
            }
        }
    }
    
    func performRemove(position: EquipmentPosition)
    {
        guard let item = equipment[position] else {
            send("У Вас ничего не надето в этой позиции.")
            return
        }

        if !isGodMode() {
            if item.isCursed {
                act("Вы попытались снять с себя @1в, но не смогли!",
                    .to(self), .item(item))
                return
            } else if !canCarryOneMoreItem() {
                act("У Вас в руках слишком много предметов, Вы не можете удержать @1в.",
                    .to(self), .item(item))
                return
            } else if !canLift(item: item) {
                act("Вы не смогли поднять @1в.", .to(self), .item(item))
                return
            }
        }

        if item.hasType(.armor) ||
                item.hasType(.worn) ||
                item.hasType(.container) ||
                item.hasType(.vessel) ||
                item.hasType(.key) {
            act("Вы сняли @1в.", .to(self), .item(item))
            act("1*и снял1(,а,о,и) @1в.", .toRoom, .excluding(self), .item(item))
        } else {
            act("Вы прекратили использовать @1в.", .to(self), .item(item))
            act("1*и прекратил1(,а,о,и) использовать @1в.",
                .toRoom, .excluding(self), .item(item))
        }
        item.extraFlags.remove(.uncursed)

        if let item = unequip(position: position) {
            item.give(to: self)
        }
    }

    func dropAllEquipment() {
        guard let inRoom = inRoom else {
            logError("dropAllEquipment(): not in a room")
            return
        }
        for (position, _) in equipment {
            let item = unequip(position: position)
            item?.put(in: inRoom, activateDecayTimer: true)
        }
    }
    
    func dropAllInventory() {
        guard let inRoom = inRoom else {
            logError("dropAllInventory(): not in a room")
            return
        }
        for item in carrying {
            item.removeFromCreature()
            item.put(in: inRoom, activateDecayTimer: true)
        }
    }
    
    func extractAllEquipment() {
        for (_, item) in equipment {
            item.extract(mode: .purgeAllContents)
        }
    }
    
    func extractAllInventory() {
        for item in carrying {
            item.extract(mode: .purgeAllContents)
        }
    }
    
    func dropAccidentally(item: Item) -> Bool {
        guard let inRoom = inRoom else {
            logError("dropAccidentally(item): not in a room")
            return false
        }
        
        if let wornBy = item.wornBy, let position = item.wornPosition {
            if wornBy.unequip(position: position) != item {
                logError("dropAccidentally: inconsistent wornBy and wornOn")
            }
        } else if item.isCarried {
            item.removeFromCreature()
        }
        
        act("Не удержав в руках, Вы уронили @1в на землю!", .toSleeping, .to(self), .item(item))
        act("Не удержав в руках, 1+и уронил1(,а,о,и) @1+в на землю!", .toRoom, .excluding(self), .item(item))
        item.put(in: inRoom, activateDecayTimer: true)
        
        return true
    }
    
    func zapOnAlignmentMismatch(with item: Item) -> Bool {
        guard let mobile = mobile, mobile.isShopkeeper else {
            // Don't zap shopkeepers
            return false
        }
        
        if item.isInContainer {
            // Items inside items can't zap
            return false
        }
        
        guard isAlignmentMismatched(with: item) else { return false }
        guard let inRoom = inRoom else {
            logError("zapOnAlignmentMismatch: creature is not in a room without nozap flag set");
            return false
        }
        
        act("Вас ударило током, и Вы выпустили @1в из рук.", .toSleeping, .to(self), .item(item))
        act("1+в ударило током, и 1еи выпустил1(,а,о,и) @1+в из рук.", .toRoom, .excluding(self), .item(item))
        
        if let wornBy = item.wornBy, let position = item.wornPosition {
            if wornBy.unequip(position: position) != item {
                logError("zapOnAlignmentMismatch: inconsistent wornBy and wornOn")
            }
        } else if item.isCarried {
            item.removeFromCreature()
        }
        
        if let player = player {
            player.flags.insert(.saveme) // Probably unnecessary, but...
        }
        
        item.put(in: inRoom, activateDecayTimer: true)
        
        return true
    }
    
    func sendWearMessage(item: Item, position: EquipmentPosition, shouldCancelAction: inout Bool) {
        shouldCancelAction = false
        
        let eventIds: [ItemEventId]
        switch position {
        case .wield, .twoHand:
            eventIds = [.wield, .wear]
        case .hold:
            eventIds = [.hold, .wear]
        default:
            eventIds = [.wear]
        }
        let event = item.override(eventIds: eventIds)

        let toActor = event.toActor ??
            (event.isAllowed ? position.wearToActor : position.unableToWearToActor)
        let toRoom = event.toRoomExcludingActor ??
            (event.isAllowed ? position.wearToRoom : position.unableToWearToRoom)
        act(toActor, .to(self), .item(item))
        act(toRoom, .toRoom, .excluding(self), .item(item))
        shouldCancelAction = !event.isAllowed
    }
}
