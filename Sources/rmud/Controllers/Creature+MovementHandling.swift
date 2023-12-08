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
        if self.inRoom == nil {
            logError("extract(mode:): creature \(nameNominative) is not in any rooms")
            guard let fallbackRoom = areaManager.areasInResetOrder.first?.rooms.first else {
                fatalError("No rooms in game")
            }
            teleportTo(room: fallbackRoom)
            inRoom = self.inRoom!
        }
        
        while let follower = followers.first {
            follower.stopFollowing()
        }
        
        if isFollowing {
            stopFollowing()
        }

        dismount() // она сама проверяет riding и ridden_by

        // Get rid of equipment and inventory
        switch mode {
        case .leaveItemsOnGround:
            dropAllEquipment()
            dropAllInventory()
        case .keepItems:
            break
        }
        
        attackedByAtGamePulse.removeAll()
        lastBattleParticipants.removeAll()

        scheduler.cancelAllEvents(target: self)
        removeFromRoom()
        
        db.creaturesInGame = db.creaturesInGame.filter { $0 != self }
        db.creaturesInGameByUid.removeValue(forKey: self.uid)
        
        if isPlayer {
            descriptors.forEach { descriptor in
                descriptor.state = .creatureMenu
                sendStatePrompt(descriptor)
            }
        }
    }
    
    func removeFromRoom() {
        switchToOtherTargets() // make opponents find another victims
        stopFighting()
        
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
    
    func goto(room: Room) {
        sendPoofOut()
        teleportTo(room: room)
        sendPoofIn()
        lookAtRoom(ignoreBrief: false)
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
        } else {
            act("Вы прекратили следовать за 2т.",
                .toSleeping, .to(self), .excluding(master))
            act("1*и прекратил1(,а,о,и) следовать за Вами.",
                .toSleeping, .excluding(self), .to(master))
            act("1+и прекратил1(,а,о,и) следовать за 2+т.",
                .toRoom, .excluding(self), .excluding(master))
        }
        
        removeFollower()
    }
    
    // Start following leader
    func follow(leader: Creature, silent: Bool) {
        leader.followers.insert(self, at: 0)
        following = leader
        if !silent {
            act("Теперь Вы будете следовать за 2т.", .toSleeping,
                .to(self), .excluding(leader))
            act("1*и начал1(,а,о,и) следовать за Вами.",
                .excluding(self), .to(leader))
            act("1+и начал1(,а,о,и) следовать за 2+т.", .toRoom,
                .excluding(self), .excluding(leader))
        }
    }
    
    // Remove the follower from his master's follower list and null his master
    private func removeFollower() {
        if let master = following {
            master.followers = master.followers.filter { $0 != self }
        }
        following = nil
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

    func handlePostponedMovement() {
        handlePostponedMovement(intoUnknown: false)
    }

    func handlePostponedMovement(intoUnknown: Bool) {
        guard let pathEntry = movementPath.first else { return }
        guard let inRoom = inRoom else { return }
        guard let toRoom = inRoom.exits[pathEntry.direction]?.toRoom() else {
            sendCantGoThereMessage()
            movementPath.removeAll()
            return
        }
        // Unexplored areas can be travelled into only interactively.
        // Exception is when player attempts to travel without
        // waiting for timer expiration.
        // In both cases there should be no pre-planned path.
        if (!intoUnknown && movementPathInitialRoom != inRoom.vnum) || movementPath.count >= 2 {
            if let player = controllingPlayer {
                guard player.preferenceFlags.contains(.goIntoUnknownRooms) || player.exploredRooms.contains(toRoom.vnum) else {
                    send("Дальше путь Вам незнаком.")
                    movementPath.removeAll()
                    return
                }
            }
        }
        let terrainPulsesNeeded = (inRoom.terrain.gamePulsesNeeded + toRoom.terrain.gamePulsesNeeded) / 2
        let dexterityBonus = affectedDexterity() - 16
        let pulsesNeeded = max(0, Int(terrainPulsesNeeded) - dexterityBonus)
        let pulsesPassed = gameTime.gamePulse - arrivedAtGamePulse
        guard pulsesPassed >= pulsesNeeded else {
            scheduler.schedule(
                afterGamePulses: UInt64(pulsesNeeded) - pulsesPassed,
                handlerType: .movement,
                target: self,
                action: Creature.handlePostponedMovement)
            return
        }

        movementPath.removeFirst()
        
        let fromRoom = inRoom
        if pathEntry.reason == .follow, let following {
            act("Вы последовали за 2т &.", .to(self), .excluding(following),
                .text(pathEntry.direction.whereTo))
        }
        showLeaveMessage(direction: pathEntry.direction)
        teleportTo(room: toRoom)
        showArrivalMessage(
            fromRoom: fromRoom, fromDirection: pathEntry.direction.opposite
        )
        
        lookAtRoom(ignoreBrief: false)
        
        for follower in followers {
            guard follower.inRoom == fromRoom else { continue }
            guard follower.movementPath.isEmpty else { continue }
            follower.performMove(direction: pathEntry.direction, reason: .follow)
            follower.handlePostponedMovement(intoUnknown: true)
        }
    }

    private func sendCantGoThereMessage() {
        send("Увы, Вы не можете идти в этом направлении.")
    }
    
    private func showArrivalMessage(fromRoom: Room, fromDirection: Direction) {
        guard let inRoom = inRoom else { return }
        
        let arrivalDirection: Direction
        
        if let exit = inRoom.exits[fromDirection], let fromVnum = exit.toVnum, fromRoom.vnum == fromVnum {
            arrivalDirection = fromDirection
        } else if let possibleArrivalDirection = Direction.allDirections.first(where: { direction in
                guard let exit = inRoom.exits[direction] else { return false }
                return fromRoom.vnum == exit.toVnum
        }) {
            arrivalDirection = possibleArrivalDirection
        } else {
            arrivalDirection = fromDirection
        }
        
        let verb = arrivalVerb(actIndex: 1)
        act("1*и \(verb) &.", .toRoom, .excluding(self), .text(arrivalDirection.whereFrom))
    }
    
    private func showLeaveMessage(direction: Direction) {
        let verb = leavingVerb(actIndex: 1)
        act("1*и \(verb) &.", .toRoom, .excluding(self), .text(direction.whereTo))
    }
    
    /*
    private func showLeaveMessage(leader: Creature, direction: Direction, mode: MovementMode) {
        var rider = self
        var mount = self
        let isMounted = isRiding || isRiddenBy

        if let riding = riding {
            mount = riding
        }
        if let riddenBy = riddenBy {
            rider = riddenBy
        }
    
        guard mode != .fall else {
            send("Вы упали вниз!")
            act("1и упал1(,а,о,и) вниз.", .toRoom, .excluding(self))
            return
        }
    
        guard mode == .normal else {
            if isMounted {
                act("1и с 2т на спине убежал1(,а,о,и) &.", .toRoom, .excluding(rider), .excluding(mount), .text(direction.whereTo))
                if let riding = riding {
                    act("2и быстро убежал2(,а,о,и), унося Вас подальше от боя.", .to(self), .excluding(riding))
                } else if let riddenBy = riddenBy {
                    act("Вы быстро убежали, унося 2в подальше от боя.", .to(self), .excluding(riddenBy))
                }
            } else if mode == .maneuvre {
                // FIXME: isAllowed not checked
                let event = inRoom!.override(eventId: .maneuvre)
                let toActor = event.toActor ??
                    "Вы выполнили обманный маневр и убежали &."
                let toRoom = event.toRoomExcludingActor ??
                    "1и выполнил1(,а,о,и) обманный маневр и убежал1(,а,о,и) &."
                act(toActor, .to(self), .text(direction.whereTo))
                act(toRoom, .toRoom, .excluding(self), .text(direction.whereTo))
            } else {
                act("1и запаниковал1(,а,о,и) и убежал1(,а,о,и) &.", .toRoom, .excluding(self), .text(direction.whereTo))
                send("Вы быстро убежали из боя.")
            }
            return
        }
        
        guard let peopleInRoom = inRoom?.creatures else { return }

        // It is possible to merge these two cycles into one, but since this
        // function is called very often, it is better to keep them separate.
        if isMounted {
            let message = "2+и с 3+т на спине \(mount.leavingVerb(2)) &."
            for creature in peopleInRoom {
                let masterIsMountOrRider = creature.following == mount || creature.following == rider
                guard creature.canSee(mount) || creature.canSee(rider) else {
                    if masterIsMountOrRider {
                        creature.runtimeFlags.remove(.follow)
                    }
                    continue
                }
                if masterIsMountOrRider {
                    creature.runtimeFlags.insert(.follow)
                }
                guard creature != mount && creature != rider else { continue }
                let (success, _) = mount.sneakSuccessful(victim: creature)
                if !success {
                    if mount.shouldShowMovement(to: creature, leader: leader) {
                        act(message, .to(creature), .excluding(mount), .excluding(rider), .text(direction.whereTo))
                    }
                } else if masterIsMountOrRider {
                    creature.runtimeFlags.remove(.follow)
                }
            }
        } else {
            let message = "2*и \(leavingVerb(2)) &."
            for creature in peopleInRoom {
                let masterIsMountOrRider = creature.following == self
                guard creature.canSee(self) else {
                    if masterIsMountOrRider {
                        creature.runtimeFlags.remove(.follow)
                    }
                    continue
                }
                if masterIsMountOrRider {
                    creature.runtimeFlags.insert(.follow)
                }
                guard creature != self else { continue }

                let (success, _) = mount.sneakSuccessful(victim: creature)
                if !success {
                    if shouldShowMovement(to: creature, leader: leader) {
                        act(message, .to(creature), .excluding(self), .text(direction.whereTo))
                    } else if masterIsMountOrRider {
                        creature.runtimeFlags.remove(.follow)
                    }
                }
            }
        }
    }
    */
}
