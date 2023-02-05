import Foundation

extension Creature {
    func handlePostponedMovement() {
        handlePostponedMovement(interactive: false)
    }

    func handlePostponedMovement(interactive: Bool) {
        guard let direction = movementPath.first else { return }
        guard let inRoom = inRoom else { return }
        guard let toRoom = inRoom.exits[direction]?.toRoom() else {
            sendCantGoThereMessage()
            movementPath.removeAll()
            return
        }
        // Unexplored areas can be travelled into only interactively.
        // Exception is when player attempts to travel without
        // waiting for timer expiration.
        // In both cases there should be no pre-planned path.
        if (!interactive && movementPathInitialRoom != inRoom.vnum) || movementPath.count >= 2 {
            if let player = controllingPlayer {
                guard player.preferenceFlags.contains(.goIntoUnknownRooms) || player.exploredRooms.contains(toRoom.vnum) else {
                    send("Дальше путь Вам незнаком.")
                    movementPath.removeAll()
                    return
                }
            }
        }
        let pulsesNeeded = (inRoom.terrain.gamePulsesNeeded + toRoom.terrain.gamePulsesNeeded) / 2
        let pulsesPassed = gameTime.gamePulse - arrivedAtGamePulse
        guard pulsesPassed >= pulsesNeeded else {
            scheduler.schedule(
                afterGamePulses: pulsesNeeded - pulsesPassed,
                handlerType: .movement,
                target: self,
                action: Creature.handlePostponedMovement)
            return
        }
        
        movementPath.removeFirst()
        
        let fromRoom = inRoom
        showLeaveMessage(direction: direction)
        teleportTo(room: toRoom)
        showArrivalMessage(fromRoom: fromRoom, fromDirection: direction.opposite)
        
        lookAtRoom(ignoreBrief: false)
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
