import Foundation

extension Creature {
    enum ExtractMode {
        case leaveItemsOnGround
        case keepItems
        //case destroyItemsPreservingMaximums
        //case deprecated_destroyItemsModifyingMaximums
    }
    
    /// Extract a creature completely from the world
    func extract(mode: ExtractMode) {
        if isPlayer && descriptor == nil {
            // If snooping, return immediately
            for descriptor in networking.descriptors {
                if descriptor.original == self {
                    descriptor.creature?.returnToOriginalCreature()
                }
            }
        }
        
        if self.inRoom == nil {
            logError("extract(mode:): creature \(nameNominative) is not in any rooms")
            guard let fallbackRoom = areaManager.areasInResetOrder.first?.rooms.first else {
                fatalError("No rooms in game")
            }
            teleportTo(room: fallbackRoom)
            inRoom = self.inRoom!
        }

        if let player = player, player.flags.contains(.group) &&
            (!isFollowing || following!.isMobile || !following!.player!.flags.contains(.group)) {
            let _ = selectNewLeader(allowAnyone: true)
        }
        
        while let follower = followers.first {
            follower.stopFollowing()
        }
        
        if isFollowing {
            stopFollowing()
        }

        dismount() // она сама проверяет riding и ridden_by

        // Forget snooping, if applicable
        if let descriptor = descriptor {
            if let snooping = descriptor.snooping {
                snooping.snoopedBy = nil
                descriptor.snooping = nil
            }
            if let snoopedBy = descriptor.snoopedBy {
                snoopedBy.send("Ваша жертва покинула игру.")
                snoopedBy.snooping = nil
                descriptor.snoopedBy = nil
            }
        }

        // Get rid of equipment and inventory
        switch mode {
        case .leaveItemsOnGround:
            dropAllEquipment()
            dropAllInventory()
        case .keepItems:
            break
        }

        removeFromRoom()
        
        db.creaturesInGame = db.creaturesInGame.filter { $0 != self }
        
        if let descriptor = descriptor, descriptor.original != nil {
            returnToOriginalCreature()
        }
        
        if isPlayer, let descriptor = descriptor {
            descriptor.state = .creatureMenu
            sendStatePrompt(descriptor)
        }
    }
    
    func putToLinkDeadState() -> Bool {
        guard let player = player else { return false }
        if !isFighting && !player.isNoQuit && !isCharmed() &&
                !position.isDyingOrDead && !isAffected(by: .poison) &&
                level < Level.hero {
            if let master = following, !isSameGroup(with: master) {
                stopFollowing()
            }
            return true
        }
        return false
    }
    
//    func restoreFromLinkDeadState() -> Bool {
//        guard let player = player else { return false }
//        guard player.isMortalAndLinkDead else { return false }
//
//        return true
//    }
    
    func returnToOriginalCreature() {
        // FIXME: port do_return
    }

    func send(_ text: String, terminator: String = "\n") {
        descriptor?.send(text, terminator: terminator)
    }
    
    func removeFromRoom() {
        if isFighting || position.isStunnedOrWorse {
            redirectAttentions() // make opponents find another victims
        }
        if isFighting {
            stopFighting()
        }
        
        if let previousRoom = inRoom {
            previousRoom.creatures =
                previousRoom.creatures.filter { $0 !== self }
        }
        inRoom = nil
    }
    
    func put(in room: Room) {
        assert(inRoom == nil)
        room.creatures.insert(self, at: 0)
        inRoom = room
        
        if let player = player {
            player.exploredRooms.insert(room.vnum)
        }
        
        arrivedAtGamePulse = gameTime.gamePulse
    }
    
    func teleportTo(room: Room) {
        removeFromRoom()
        put(in: room)
    }

    // Call this to stop following or charm spells
    // FIXME: this function is doing too much unrelated things
    func stopFollowing() {
        guard let master = following else {
            logError("stopFollowing: \(nameNominative) has no leader")
            return
        }
        
        if isCharmed() {
            // FIXME
        } else if let player = player, player.flags.contains(.group) {
            act("Вы прекратили следовать за 2т и покинули 2ер группу.",
                .toSleeping, .toCreature(self), .excludingCreature(master))
            act("1*и прекратил1(,а,о,и) следовать за Вами и покинул1(,а,о,и) Вашу группу.",
                .toSleeping, .excludingCreature(self), .toCreature(master))
            act("1+и прекратил1(,а,о,и) следовать за 2+т и покинул1(,а,о,и) 2ер группу.",
                .toRoom, .excludingCreature(self), .excludingCreature(master))
        } else {
            act("Вы прекратили следовать за 2т.",
                .toSleeping, .toCreature(self), .excludingCreature(master))
            act("1*и прекратил1(,а,о,и) следовать за Вами.",
                .toSleeping, .excludingCreature(self), .toCreature(master))
            act("1+и прекратил1(,а,о,и) следовать за 2+т.",
                .toRoom, .excludingCreature(self), .excludingCreature(master))
        }

        if let player = master.player, player.flags.contains(.group) &&
            (master.following == nil || master.following!.isMobile || !master.following!.player!.flags.contains(.group)) {
            // проверяем, остались ли кроме этого еще последователи-групписы
            var hasGroupedFollowers = false
            for follower in master.followers {
                if let player = follower.player, player.flags.contains(.group) && follower != self {
                    hasGroupedFollowers = true
                    break
                }
            }
            if !hasGroupedFollowers {
                player.flags.remove(.group)
            }
        }
        
        removeFollower()
        
        if let player = player {
            player.flags.remove(.group)
        }
    }
    
    // Start following leader
    func follow(leader: Creature, silent: Bool) {
        leader.followers.insert(self, at: 0)
        following = leader
        if !silent {
            act("Теперь Вы будете следовать за 2т.", .toSleeping,
                .toCreature(self), .excludingCreature(leader))
            act("1*и начал1(,а,о,и) следовать за Вами.",
                .excludingCreature(self), .toCreature(leader))
            act("1+и начал1(,а,о,и) следовать за 2+т.", .toRoom,
                .excludingCreature(self), .excludingCreature(leader))
        }
    }
    
    // Remove the follower from his master's follower list and null his master
    private func removeFollower() {
        if let master = following {
            master.followers = master.followers.filter { $0 != self }
        }
        following = nil
    }
    
    // Set group to follow leader instead of self
    func passLeadership(to newLeader: Creature, isLeaving: Bool) {
        if newLeader.following != self {
            logError("passLeadership: new leader is not following the old one")
            return
        }
        
        newLeader.removeFollower()
        if isFollowing {
            stopFollowing()
        }
        if !isLeaving {
            // если он не "уходит насовсем" (например, умер)
            follow(leader: newLeader, silent: true)
            if let player = player {
                player.flags.insert(.group)
            }
        }
        
        followers = followers.filter { follower in
            guard let followerPlayer = follower.player, followerPlayer.flags.contains(.group) else {
                // Keep this follower
                return true
            }
            // Switch to new leader
            follower.follow(leader: newLeader, silent: true)
            act("Вы прекратили следовать за 2*т и начали следовать за 3*т.",
                .toSleeping, .toCreature(follower), .excludingCreature(self), .excludingCreature(newLeader))
            act("1*и прекратил1(,а,о,и) следовать за Вами и начал1(,а,о,и) следовать за 3*т.",
                .toSleeping, .excludingCreature(follower), .toCreature(self), .excludingCreature(newLeader))
            act("1*и прекратил1(,а,о,и) следовать за 2*т и начал1(,а,о,и) следовать за Вами.",
                .toSleeping, .excludingCreature(follower), .excludingCreature(self), .toCreature(newLeader))
            //          act("1+и прекратил1(,а,о,и) следовать за 2*и и начал1(,а,о,и) следовать за 3*т.",
            //              "Кммм", follower, ch, leader);
            return false
        }
    }
    
    func dismount() {
        if let riding = riding {
            riding.riddenBy = nil
            self.riding = nil
        }
        if let riddenBy = riddenBy {
            riddenBy.riding = nil
            self.riddenBy = nil
        }
    }
    
    
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
        item.wornOn = position
        
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
        item.wornOn = .nowhere
        
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
                act("@1и никуда не надевается.", .toCreature(self), .item(item))
            }
            return
        }

        guard !item.isWorn else {
            if !isSilent {
                act("@1и уже надет.", .toCreature(self), .item(item))
            }
            return
        }
        
        let flagsAndPositions: [(flag: ItemWearFlags, position: EquipmentPosition)] = [
            (.finger, .fingerRight),
            (.neck, .neck),
            (.neckAbout, .neckAbout),
            (.body, .body),
            (.head, .head),
            (.face, .face),
            (.legs, .legs),
            (.feet, .feet),
            (.hands, .hands),
            (.arms, .arms),
            (.shield, .shield),
            (.about, .about),
            (.back, .back),
            (.waist, .waist),
            (.ears, .ears),
            (.wrist, .wristRight)
        ]

        for (flag, position) in flagsAndPositions {
            guard item.wearFlags.contains(flag) else { continue }
            performWear(item: item, position: position, isSilent: isSilent)
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
    func performWear(item: Item, position: EquipmentPosition, isSilent: Bool) {
        let sendCantWear = {
            act("@1в надеть на эту часть тела нельзя.",
                .toCreature(self), .item(item))
        }
        
        // first, make sure that the wear position is valid
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
        
        // For neck, finger, and wrist, try pos 2 if pos 1 is already full
        var position = position
        if equipment[position] != nil {
            if position == .fingerRight {
                position = .fingerLeft
            } else if position == .wristRight {
                position = .wristLeft
            }
        }
        
        guard equipment[position] == nil else {
            send(position.alreadyWearing)
            return
        }
        
        let useTake = position == .twoHand ||
            position == .wield ||
            position == .hold ||
            position == .light ||
            position == .shield
        if useTake && !canWear(item: item, at: position) {
            send("У Вас заняты руки.")
            return
        }

        if !isSilent {
            var shouldCancelAction: Bool = false
            sendWearMessage(item: item, position: position, shouldCancelAction: &shouldCancelAction)
            guard !shouldCancelAction else { return }
        }

        if isUncomfortableRace(item: item) {
            act("Увы, @1и сделан@1(,а,о,ы) явно не под Ваши размеры.", .toCreature(self), .item(item))
            act("1*и недовольно поерзал1(,а,о,и) и прекратил1(,а,о,и) пользоваться @1т.", .excludingCreature(self), .item(item))
            return
        } else if isUncomfortableClass(item: item) {
            act("Увы, @1и для Вас неудоб@1(ен,на,но,ны).",
                .toCreature(self), .item(item))
            act("1*и к своему разочарованию убедил1(ся,ась,ось,ись), что @1и для н1ев неудоб@1(ен,на,но,ны).",
                .toRoom, .excludingCreature(self), .item(item))
            return
        } else {
            if item.isCarried {
                item.removeFromCreature()
            }
            equip(item: item, position: position)
            if item.hasType(.weapon) && weaponEfficiencyPercents(for: item, in: position) < 100 {
                act("Вы почувствовали, что @1и слишком тяжел@1(,а,о,ы) для Вас.", .toCreature(self), .item(item))
            }
            if item.extraFlags.contains(.stringed) {
                // FIXME: check that removing/wearing bow can't be used to shot faster
                item.stateFlags.remove(.bow)
            }
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
        
        if let wornBy = item.wornBy {
            if wornBy.unequip(position: item.wornOn) != item {
                logError("dropAccidentally: inconsistent wornBy and wornOn")
            }
        } else if item.isCarried {
            item.removeFromCreature()
        }
        
        act("Не удержав в руках, Вы уронили @1в на землю!", .toSleeping, .toCreature(self), .item(item))
        act("Не удержав в руках, 1+и уронил1(,а,о,и) @1+в на землю!", .toRoom, .excludingCreature(self), .item(item))
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
        
        act("Вас ударило током, и Вы выпустили @1в из рук.", .toSleeping, .toCreature(self), .item(item))
        act("1+в ударило током, и 1еи выпустил1(,а,о,и) @1+в из рук.", .toRoom, .excludingCreature(self), .item(item))
        
        if let wornBy = item.wornBy {
            if wornBy.unequip(position: item.wornOn) != item {
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
    
    func rollStartAbilities() {
        realStrength = 13
        realDexterity = 13
        realConstitution = 13
        realIntelligence = 13
        realWisdom = 13
        realCharisma = 13

        let raceInfo = race.info
        let classInfo = classId.info
        
        size = raceInfo.size
        realMaximumMovement = raceInfo.movement
        
        switch gender {
        case .masculine:
            height = raceInfo.heightMale
            weight = raceInfo.weightMale
        case .feminine:
            height = raceInfo.heightFemale
            weight = raceInfo.weightFemale
        default:
            assertionFailure()
            break
        }
        
        height += UInt(Dice(number: raceInfo.heightDiceNum, size: raceInfo.heightDiceSize).roll())
        weight += UInt(Dice(number: raceInfo.weightDiceNum, size: raceInfo.weightDiceSize).roll())
        
        realStrength = UInt8(Int(realStrength) + raceInfo.strength + classInfo.strength)
        realDexterity = UInt8(Int(realDexterity) + raceInfo.dexterity + classInfo.dexterity)
        realConstitution = UInt8(Int(realConstitution) + raceInfo.constitution + classInfo.constitution)
        realIntelligence = UInt8(Int(realIntelligence) + raceInfo.intelligence + classInfo.intelligence)
        realWisdom = UInt8(Int(realWisdom) + raceInfo.wisdom + classInfo.wisdom)
        realCharisma = UInt8(Int(realCharisma) + raceInfo.charisma /* + classInfo.charisma */)
    }

    // FIXME: move to data/classes
    private static let abilityWeightsPerClass: [ClassId: [UInt8]] = {
        var result: [ClassId: [UInt8]] = [:]
        //                     S  D  C  I  W
        result[.mage]       = [2, 4, 5, 8, 5] // 24
        result[.mishakal]   = [2, 4, 3, 7, 8] // 24
        result[.thief]      = [6, 8, 3, 3, 4] // 24
        result[.fighter]    = [7, 6, 7, 2, 2] // 24
        result[.assassin]   = [7, 7, 4, 3, 3] // 24
        result[.ranger]     = [7, 7, 6, 2, 2] // 24
        result[.solamnic]   = [7, 5, 6, 3, 4] // 25
        result[.morgion]    = [2, 5, 2, 7, 8] // 24
        result[.chislev]    = [2, 4, 3, 7, 8] // 24
        result[.sargonnas]  = [2, 4, 3, 7, 8] // 24
        result[.kiriJolith] = [2, 4, 3, 7, 8] // 24
        return result
    }()

    func rollRealAbilities() {
        guard level >= 3 else { return }
        let rollBasicAbility = {
            UInt8(
                Dice(number: 4, size: 4).roll() + Random.uniformInt(2...4)
            )
        }
        
        let areAbilitiesPlayable: ()->Bool = {
            guard let abilityWeights = Creature.abilityWeightsPerClass[self.classId] else {
                fatalError("Ability weights not defined for class \(self.classId.rawValue)")
            }
            var abilities: [UInt8] = []
            abilities.append(self.realStrength)
            abilities.append(self.realDexterity)
            abilities.append(self.realConstitution)
            abilities.append(self.realIntelligence)
            abilities.append(self.realWisdom)
            assert(abilities.count == abilityWeights.count)

            var sum = 0
            for i in 0 ..< abilities.count {
                // проверка на минимальное значение характеристики
                // оно равно 5 + (abil_weight[class][stat]-2)*2,
                // что даёт нам 5 для тех,у кого в таблице 2, 9 - для 4,
                // 13 - для 6, 15 для 7 и 17 для 8
                guard abilities[i] - 5 >= (abilityWeights[i] - 2) * 2 else { return false }
                sum += (Int(abilities[i]) - 13) * Int(abilityWeights[i])
            }
            
            return sum >= 58;
        }
        
        let raceInfo = race.info
        let classInfo = classId.info

        repeat {
            realStrength = rollBasicAbility()
            realDexterity = rollBasicAbility()
            realConstitution = rollBasicAbility()
            realIntelligence = rollBasicAbility()
            realWisdom = rollBasicAbility()
            
            realStrength = UInt8(Int(realStrength) + raceInfo.strength + classInfo.strength)
            realDexterity = UInt8(Int(realDexterity) + raceInfo.dexterity + classInfo.dexterity)
            realConstitution = UInt8(Int(realConstitution) + raceInfo.constitution + classInfo.constitution)
            realIntelligence = UInt8(Int(realIntelligence) + raceInfo.intelligence + classInfo.intelligence)
            realWisdom = UInt8(Int(realWisdom) + raceInfo.wisdom + classInfo.wisdom)
            
            realStrength = realStrength.clamped(to: 1...30)
            realDexterity = realDexterity.clamped(to: 1...30)
            realConstitution = realConstitution.clamped(to: 1...30)
            realIntelligence = realIntelligence.clamped(to: 1...30)
            realWisdom = realWisdom.clamped(to: 1...30)
        } while !areAbilitiesPlayable()
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
        act(toActor, .toCreature(self), .item(item))
        act(toRoom, .toRoom, .excludingCreature(self), .item(item))
        shouldCancelAction = !event.isAllowed
    }
    
    func sendDescriptions(of items: [Item], withGroundDescriptionsOnly: Bool, bigOnly: Bool) {
        let shouldStack = preferenceFlags?.contains(.stackItems) ?? false
        var stackedItemsCount = 0
        var lastItem: Item?
        var lastItemDescription = ""
        
        let showLastDescriptionIfAny = {
            guard stackedItemsCount > 0 else { return } // nothing to show
            if stackedItemsCount > 1 {
                self.send("\(lastItemDescription) [\(stackedItemsCount)]")
            } else {
                self.send(lastItemDescription)
            }
        }
        defer { showLastDescriptionIfAny() }
        
        for item in items {
            guard !bigOnly || item.extraFlags.contains(.big) else { continue }
            guard !withGroundDescriptionsOnly || !item.groundDescription.isEmpty else { continue }
            guard canSee(item) else { continue }
            
            let description = describe(item: item)
            
            guard shouldStack else {
                send(description)
                continue
            }
            
            if stackedItemsCount > 0,
                    let lastItem = lastItem,
                    item.vnum == lastItem.vnum &&
                        description == lastItemDescription {
                stackedItemsCount += 1
            } else {
                showLastDescriptionIfAny()
                lastItem = item
                lastItemDescription = description
                stackedItemsCount = 1
            }
        }
    }
    
    // Lists chars in room, with char stacking routine
    func sendDescriptions(of people: [Creature]) {
        let shouldShow: (_ creature: Creature)->Bool = { creature in
            let holylight = { self.preferenceFlags?.contains(.holylight) ?? false }
            let canSeeCreatureAndItsNotHiding: (_ creature: Creature)->Bool = { creature in
                self.canSee(creature) &&
                (!creature.runtimeFlags.contains(.hiding) || self.isAffected(by: .senseLife) || holylight()) }
            let creatureIsRidingAndCanSeeWhomItsRiding: (_ creature: Creature)->Bool = { creature in
                if let riding = creature.riding, self.canSee(riding) {
                    return true
                }
                return false
            }
            let isVisibleIfAdmin: (_ creature: Creature)->Bool = { creature in
                guard let player = creature.player else {
                    // Skip mobiles, they're visible
                    return true
                    
                }
                if player.adminInvisibilityLevel <= self.level {
                    return true
                }
                return false
            }
            let isRiddenBySomeoneExceptMe: (_ creature: Creature)->Bool = { creature in
                if let creatureRiddenBy = creature.riddenBy,
                        creatureRiddenBy.inRoom == creature.inRoom,
                        creatureRiddenBy != self {
                    return true
                }
                return false
            }
            return (
                canSeeCreatureAndItsNotHiding(creature) ||
                self.riding == creature ||
                (creature.hasDetectableItems() && isVisibleIfAdmin(creature)) ||
                creatureIsRidingAndCanSeeWhomItsRiding(creature)
            ) && !isRiddenBySomeoneExceptMe(creature)
        }
        
        let shouldStack = preferenceFlags?.contains(.stackMobiles) ?? false
        var stackedCreaturesCount = 0
        var lastCreature: Creature?
        var lastCreatureDescription = ""

        let showLastDescriptionIfAny = {
            guard stackedCreaturesCount > 0 else { return } // nothing to show
            if stackedCreaturesCount > 1 {
                self.send("\(lastCreatureDescription) [\(stackedCreaturesCount)]")
            } else {
                self.send(lastCreatureDescription)
            }
        }
        defer { showLastDescriptionIfAny() }

        for creature in people {
            guard self != creature && shouldShow(creature) else { continue }

            let creatureMirrorImagesCount = creature.isAffected(by: .mirrorImage) ? creature.mirrorImagesCount() : 0
            
            let description = describe(creature: creature)
            
            guard shouldStack else {
                for _ in 0..<(1 + creatureMirrorImagesCount) {
                    send(description)
                }
                continue
            }

            if stackedCreaturesCount > 0,
                    let lastCreature = lastCreature,
                    let creatureMobile = creature.mobile,
                    let lastCreatureMobile = lastCreature.mobile,
                    creatureMobile.vnum == lastCreatureMobile.vnum &&
                    description == lastCreatureDescription {
                stackedCreaturesCount += (1 + creatureMirrorImagesCount)
            } else {
                showLastDescriptionIfAny()
                lastCreature = creature
                lastCreatureDescription = description
                stackedCreaturesCount = 1 + creatureMirrorImagesCount
            }
        }
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
                let vnumString = String(mobile.vnum).leftExpandingTo(minimumLength: 6)
                autostatString = "[\(vnumString)] "
            } else {
                let levelString = String(creature.level).leftExpandingTo(minimumLength: 2, with: "0")
                let classAbbreviation = creature.classId.info.abbreviation.leftExpandingTo(minimumLength: 3)
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
                formatString += mobile.groundDescription
            } else {
                if creature.isMobile || isCreatureRidingSomeone() || creature.isFighting {
                    formatString += "2^и"
                } else if canSee(creature), let creaturePlayer = creature.player {
                    let title = creaturePlayer.titleWithFallbackToRace(order: .raceThenName)
                    formatString += title
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
            
            if let player = creature.player {
                if creature.descriptor != nil {
                    if player.adminInvisibilityLevel > 0 {
                        formatString += " (н#1)"
                    }
                } else {
                    formatString += " (потерял2(,а,о,и) связь)"
                }
                if player.flags.contains(.writing) {
                    formatString += " (пиш2(е,е,е,у)т)"
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
        
        let adminInvisibilityLevel = creature.isPlayer ? Int(creature.player!.adminInvisibilityLevel) : 0
        
        var actArguments: [ActArgument] = [.toCreature(self),
                                           .excludingCreature(creature)]
        if let creatureRiding = creature.riding {
            actArguments.append(.excludingCreature(creatureRiding))
        }
        if let creatureFighting = creature.fighting {
            actArguments.append(.excludingCreature(creatureFighting))
        }
        actArguments.append(.text(autostatString))
        actArguments.append(.number(adminInvisibilityLevel))
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
            vnumString = "[\(String(item.vnum).leftExpandingTo(minimumLength: 6))] "
        }
        var formatString = "&1" // placeholder for vnumString

        if item.inRoom != nil {
            formatString.append(item.groundDescription)
        } else {
            formatString += "@1и"
            if let vessel: ItemExtraData.Vessel = item.extraData(),
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
            let isPoisonedVessel = {
                (item.extraData() as ItemExtraData.Vessel?)?.isPoisoned ?? false
            }
            let isPoisonedFountain = {
                (item.extraData() as ItemExtraData.Fountain?)?.isPoisoned ?? false
            }
            let isPoisonedFood = {
                (item.extraData() as ItemExtraData.Food?)?.isPoisoned ?? false
            }
            let isPoisonedWeapon = {
                (item.extraData() as ItemExtraData.Weapon?)?.isPoisoned ?? false
            }
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
            .toSleeping, .toCreature(self),
            .item(item), .text(vnumString)) { target, output in
                assert(result.isEmpty) // should be only one target
                result = output
        }
        return result
    }
}
