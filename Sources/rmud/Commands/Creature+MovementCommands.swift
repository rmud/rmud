//import Foundation

// MARK: - doMove

extension Creature {
    enum MovementMode {
        case normal
        case flee
        case maneuvre
        case fall
    }
    
    enum MovementResult {
        case success
        case failure
        case death
    }
    
    func doMove(context: CommandContext) {
        let direction: Direction
        switch context.subcommand {
        case .north: direction = .north
        case .east: direction = .east
        case .south: direction = .south
        case .west: direction = .west
        case .up: direction = .up
        case .down: direction = .down
        default:
            assertionFailure()
            return
        }
        
        let finalDirection = checkSpins(direction: direction)
        performMove(direction: finalDirection)
        
        handlePostponedMovement(interactive: true)
    }

    func performMove(direction: Direction) {
        if movementPath.isEmpty {
            movementPathInitialRoom = inRoom?.vnum
        }
        movementPath.append(direction)
    }

    /*
    func performMove(direction: Direction, mode: MovementMode) -> MovementResult {
        let (movementResult, warnRooms) = mode == .normal ?
            moveWithMountOrRiderAndFollowers(who: self, leader: self, direction: direction) :
            moveWithMountOrRiderOnly(who: self, leader: self, direction: direction, mode: mode)
        warnRooms.forEach { $0.warnMobiles() }
        return movementResult
    }
    */
    
    private func checkSpins(direction: Direction) -> Direction {
        if !isGodMode() && canGo(direction) {
            guard let room = inRoom else { return direction }
        
            if room.flags.contains(.spin) {
                return pickRandomDirection(fallback: direction)
            } /* else if room.flags.contains(.wilderness) && !orienting() {
                return pickRandomDirection(fallback: direction, constrainedTo: Direction.horizontalDirections)
            } */
        }
        return direction
    }
   
    private func pickRandomDirection(fallback: Direction, constrainedTo: Set<Direction> = Direction.allDirections) -> Direction {
        var chosen: Direction?
        for (index, direction) in constrainedTo.enumerated() {
            guard canGo(direction) else { continue }
            if Random.uniformInt(0...index) == 0 {
                chosen = direction
            }
        }
        return chosen ?? fallback
    }
    
    /*
    // Try to move the character and his mount or rider if any
    private func moveWithMountOrRiderOnly(who: Creature, leader: Creature, direction: Direction, mode: MovementMode) -> (result: MovementResult, warnRooms: [Room]) {
        guard let needMovement = movementPointsNeededToMove(in: direction, mode: mode) else {
            return (result: .failure, warnRooms: [])
        }
        
        if let riding = riding, riding.position != .standing {
            riding.stand()
        }

        guard let oldRoom = inRoom else {
            return (result: .failure, warnRooms: [])
            
        }
        guard let newRoom = oldRoom.exits[direction]?.toRoom() else {
            return (result: .failure, warnRooms: [])
        }
        
//        if (!entry_mtrigger(ch) ||
//            !enter_wtrigger(new_room, ch, dir, mode) ||
//            !leave_mtrigger(ch, old_room, dir, mode))
//        return WENT_FAILURE;

        if oldRoom !== inRoom {
            return (result: .failure, warnRooms: [])
        }

        if level < Level.hero && isPlayer {
            movement = movement - needMovement
        }

        unhide(informRoom: false)
        
        //Тут, до реального перемещения, будут вызваны триггеры
        //с установленным MTRIG_BEFORE, и если возвращается 0, то перемещения не будет!
        //if (!greet_mtrigger(ch, new_room, dir))
        //return WENT_FAILURE;
        
        showLeaveMessage(leader: leader, direction: direction, mode: mode)
        teleportTo(room: newRoom)
        lookAtRoom(ignoreBrief: false)
        if isPlayer ||
            (isRiding && riding!.isPlayer) ||
            (isRiddenBy && riddenBy!.isPlayer) {
            return ( result: .success, warnRooms: inRoom != nil ? [inRoom!] : [] )
        }
        
        return ( result: .success, warnRooms: [] )
    }

    private func moveWithMountOrRiderAndFollowers(who: Creature, leader: Creature, direction: Direction) -> (result: MovementResult, warnRooms: [Room]) {
        guard let oldRoom = inRoom else { return (result: .failure, warnRooms: []) }
        let (result, initialWarnRooms) = moveWithMountOrRiderOnly(who: who, leader: leader, direction: direction, mode: .normal)
        var warnRooms = initialWarnRooms
        
        if result == .success {
            warnRooms += moveFollowers(who: who, leader: leader, direction: direction, oldRoom: oldRoom)
        
            if let riding = who.riding {
                warnRooms += moveFollowers(who: riding, leader: leader, direction: direction, oldRoom: oldRoom)
            }
            if let riddenBy = who.riddenBy {
                warnRooms += moveFollowers(who: riddenBy, leader: leader, direction: direction, oldRoom: oldRoom)
            }
            // FIXME
            //if who.isPlayer && who.isHunting() {
            //    do_track(ch, CMDARG_SKIP6, "", 0, SCMD_TCONT, "", "", "");
            //}
        }
        
        return (result: result, warnRooms: warnRooms)
    }
    
    // Returns warnRoom
    private func moveFollowers(who: Creature, leader: Creature, direction: Direction, oldRoom: Room) -> [Room] {
        return []
    }
    
    private func movementPointsNeededToMove(in direction: Direction, mode: MovementMode) -> Int? {
        verifyRiderAndMountInSameRoom()
        
        // В случае падения все проверки должны быть сделаны в вызывающей функци
        if mode == .fall {
            return nil
        }
        
        // 1 - проверка возможности покинуть текущую комнату
        
        /* TODO
         * когда буду делать заклинание entangle, проверка на него
         * должна быть до падения и в случае mode == MOVE_FALL может быть
         * стоит выдавать специальное сообщение
         * ? а может быть, и его проверять в вызывающей функции ? */
        
        guard !cantLeaveRoom(isMount: false, fear: mode == .flee) else {
            return nil
        }

        guard let inRoom = inRoom,
                let exit = inRoom.exits[direction],
                let toRoom = exit.toRoom() else {
            sendCantGoThereMessage()
            return nil
        }
        
        if handleClosedDoor(exit: exit) {
            return nil
        }
        
        if exit.flags.contains(.barOut) {
            send("Что-то препятствует Вашему движению в этом направлении.")
            return nil
        }
        
        let inTerrain = inRoom.terrain
        let toTerrain = toRoom.terrain
        let isFlying = isAffected(by: .fly)
        let isWaterOnlyMobile = mobile?.flags.contains(.waterOnly) ?? false
        
        // 2 - проверка наличия прохода и возможности туда пройти
        
        if !isFlying && isWaterOnlyMobile && !toTerrain.isWater {
            send("Вы можете перемещаться только в воде.")
            return nil
        }
        
        if toTerrain == .waterNoSwim {
            if let riding = riding, !riding.isAffected(by: .fly) && !riding.hasBoat() {
                act("2и не может везти Вас в этом направлении.", .toCreature(self), .excludingCreature(riding))
                return nil
            }
            else if !isRiding && !isFlying && !hasBoat() {
                send("Чтобы передвигаться в этом направлении, Вам необходимо иметь лодку.")
                return nil
            }
        }
        
        //arilou: внимание! для ухода под воду мобу не достаточно флага MOB_WATER_ONLY,
        //надо ещё и подводное дыхание - и это правильно, это позоляет делать надводных
        //мобов, коорые не выходят на сушу.
        if toTerrain == .underwater && !isAffected(by: .waterbreath) && level < Level.lesserGod {
            send("Чтобы передвигаться в этом направлении, Вам необходимо уметь дышать под водой.")
            return nil
        }
        
        if direction == .up && toTerrain == .air {
            if let riding = riding, !riding.isAffected(by: .fly) {
                act("2и не умеет летать.", .toCreature(self), .excludingCreature(riding))
                return nil
            }
            if !isRiding && !isFlying {
                send("Чтобы передвигаться в этом направлении, Вы должны уметь летать.")
                return nil
            }
        }
        
        let isMountable = mobile?.flags.contains(.mountable) ?? false
        
        if let riding = riding {   // вообще-то in_sect должен проверяться в другом месте...
            if toTerrain == .jungle {
                sendNoRideInJungleMessage()
                return nil
            }
            if toTerrain == .tree && !riding.isAffected(by: .fly) {
                act("Чтобы везти Вас туда, 2и долж2(ен,на,но) уметь летать.", .toCreature(self), .excludingCreature(riding))
                return nil
            }
        } else if isMountable && toTerrain == .tree && !isFlying {
            send("Вы не можете идти в этом направлении.")
            return nil
        }
        
        if toRoom.flags.contains(.nomount) || toRoom.flags.contains(.indoors) {
            if let mobile = mobile, mobile.flags.contains(.mountable) {
                send("Вам не разрешено передвигаться в этом направлении.")
                return nil
            } else if let riding = riding, let ridingMobile = riding.mobile, ridingMobile.flags.contains(.mountable) && level < Level.hero {
                act("2и отказывается передвигаться в этом направлении.", .toCreature(self), .excludingCreature(riding))
                return nil
            }
        }
        
        if toRoom.flags.contains(.tunnel) {
            if (isRiding || isRiddenBy) && !toRoom.creatures.isEmpty {
                act("Вы не помещаетесь туда вместе с 2т.", .toCreature(self), .excludingCreature(isRiding ? riding! : riddenBy!))
                return nil
            }
            
            let count: Int
            if isCharmed() {
                count = toRoom.creatures.count(where: { $0 != following })
            } else if isPlayer {
                count = toRoom.creatures.count(where: { $0.isPlayer })
            } else {
                count = toRoom.creatures.count
            }
            if count > 0 {
                send("Там не хватает места для двоих.")
                return nil
            }
        }

        if let riding = riding, riding.isFighting {
            act("2и не может Вас везти, пока не закончит бой!", .toCreature(self), .excludingCreature(riding))
            return nil
        }
        
        // 3 - подсчёт расхода бодрости
        var needMovement = (inTerrain.movementLoss + toTerrain.movementLoss) / 2
        
        if mode == .normal && runtimeFlags.contains(.orienting) {
            needMovement += 1
        }
        if runtimeFlags.contains(.sneaking) || runtimeFlags.contains(.doublecrossing) {
            needMovement *= 2
        }
        
        switch mode {
        case .flee:
            needMovement = 3 * needMovement / 2
        case .maneuvre:
            needMovement = 2 * needMovement
        default:
            break
        }
        
        // arilou:
        // при выходе из вроды на поверхность полёт облегчает движение,
        // поэтому проверяю только, чтобы подводной не была точка прибытия
        if isFlying && toTerrain != .underwater {
            let nm = needMovement
            needMovement = max(1, needMovement / 3)
            if nm > 3 && (nm % 3) != 0 && (nm % 3) > Random.uniformInt(0...2) {
                needMovement += 1
            }
        } else if isRiding {
            // arilou: проверка && riding.inRoom == inRoom нам не нужна -
            // мы проверяем это в самом начале
            needMovement = max(1, needMovement / 2)
        }
        
        //FIXME
        //arilou: вот тут мы не проверяем специфику того, кто несет,
        if let riding = riding, riding.isPlayer && riding.movement < needMovement {
            act("2и сильно устал2(,а,о,и), и не может везти Вас дальше.", .toCreature(self), .excludingCreature(riding))
            return nil
        }
        
        // чтобы "усталость" действовала на мобов - проверяем и у них
        if /* isPlayer && */ movement < needMovement {
            switch mode {
            case .normal:
                send("Вы слишком устали.")
            case .flee:
                send("Вы слишком устали, и не смогли убежать!")
            case .maneuvre:
                send("Вы слишком устали, и не смогли выполнить маневр!")
            default:
                break
            }
            return nil
        }
        
        return needMovement
    }
    
    private func cantLeaveRoom(isMount: Bool = false, fear: Bool = false) -> Bool {
        guard let inRoom = inRoom else { return true }
        
        // Если мы в падении и ничего не изменилось - не ходить никуда
        if runtimeFlags.contains(.falling) {
            if willFallHere() {
                return true
            } else {
                runtimeFlags.remove(.falling)
            }
        }
    
        if isHeld() {
            if isMount {
                if let master = following {
                    act(spells.message(.holdPerson, "ПАРАЛИЗОВАН"), .excludingCreature(self), .toCreature(master))
                }
            } else {
                act(spells.message(.holdPerson, "ПАРАЛИЧ"), .toSleeping, .toCreature(self))
            }
            return true
        }
    
        let inTerrain = inRoom.terrain
        let flying = isAffected(by: .fly)
    
        if inTerrain == .waterNoSwim && !flying && !hasBoat() && !isRiding {
            // а если верхом - то достаточно лодки или полёта у mount'а
            if isMount {
                if let master = following {
                    act("2и не может увезти Вас отсюда.", .toCreature(master), .excludingCreature(self))
                }
            } else {
                send("Чтобы уйти отсюда, Вам необходимо иметь лодку.")
            }
            return true
        }
    
        if isMount {
            if inTerrain == .jungle {
                sendNoRideInJungleMessage()
                return true
            }
        } else { // for 'if (mount)'
            if let mobile = mobile, mobile.flags.contains(.tethered) {
                send("Вы привязаны, и не можете сдвинуться с места.")
                return true
            }
            if !fear && isCharmed(),
                    let master = following,
                    let masterInRoom = master.inRoom,
                    inRoom === masterInRoom {
                act(spells.message(.charmPerson, "НЕ_УЙДЕШЬ"), .toCreature(self), .excludingCreature(master))
                if runtimeFlags.contains(.order) {
                    act(spells.message(.charmPerson, "НЕ_УЙДЕТ"), .excludingCreature(self), .toCreature(master))
                    act(spells.message(.charmPerson, "НЕ_УЙДУ"), .toRoom, .excludingCreature(self), .excludingCreature(master))
                }
                return true
            }
            if let riding = riding, riding.cantLeaveRoom(isMount: true) {
                return true
            }
        }
        return false
    }

    private func verifyRiderAndMountInSameRoom() {
        if riding != nil && riding!.inRoom !== inRoom {
            logError("verifyRiderAndMountInSameRoom: rider '\(nameNominative)' and mount '\(riding!.nameNominative)' are in different rooms")
            dismount()
        }
        if riddenBy != nil && riddenBy!.inRoom !== inRoom {
            logError("verifyRiderAndMountInSameRoom: mount '\(nameNominative)' %s and rider '\(riddenBy!.nameNominative)' are in different rooms")
            dismount()
        }
    }
    
    private func unhide(informRoom: Bool) {
        if (runtimeFlags.contains(.hiding) || runtimeFlags.contains(.failedHide)) &&
                !runtimeFlags.contains(.sneaking) {
            runtimeFlags.remove(.hiding)
            runtimeFlags.remove(.failedHide)
            send("Вы прекратили прятаться.")
            if informRoom {
                act("1*и прекратил1(,а,о,и) прятаться.", .toRoom, .excludingCreature(self))
            }
        }
    }
    
    private func sneakSuccessful(victim: Creature) -> (success: Bool, victimIsImmune: Bool) {
        if !runtimeFlags.contains(.sneaking) {
            return (success: false, victimIsImmune: false)
        }
    
        if isAffected(by: .senseLife) || (preferenceFlags?.contains(.holylight) ?? false) {
            return (success: false, victimIsImmune: true)
        }
    
//        let baseSkill = skill_eff_val(ch, SKILL_SNEAK) +
//            dex_app_skill[CH_DEX(ch)].sneak +
//            ch->level
//        let probability = rogueCarryingSkillModifier(baseSkill: baseSkill)
//        let percent = Random.uniformInt(1 ... 101 + victim.level)
//
//        return probability >= percent
        return (success: false, victimIsImmune: false) // FIXME
    }

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
            act("1и упал1(,а,о,и) вниз.", .toRoom, .excludingCreature(self))
            return
        }
    
        guard mode == .normal else {
            if isMounted {
                act("1и с 2т на спине убежал1(,а,о,и) &.", .toRoom, .excludingCreature(rider), .excludingCreature(mount), .text(direction.whereTo))
                if let riding = riding {
                    act("2и быстро убежал2(,а,о,и), унося Вас подальше от боя.", .toCreature(self), .excludingCreature(riding))
                } else if let riddenBy = riddenBy {
                    act("Вы быстро убежали, унося 2в подальше от боя.", .toCreature(self), .excludingCreature(riddenBy))
                }
            } else if mode == .maneuvre {
                // FIXME: isAllowed not checked
                let event = inRoom!.override(eventId: .maneuvre)
                let toActor = event.toActor ??
                    "Вы выполнили обманный маневр и убежали &."
                let toRoom = event.toRoomExcludingActor ??
                    "1и выполнил1(,а,о,и) обманный маневр и убежал1(,а,о,и) &."
                act(toActor, .toCreature(self), .text(direction.whereTo))
                act(toRoom, .toRoom, .excludingCreature(self), .text(direction.whereTo))
            } else {
                act("1и запаниковал1(,а,о,и) и убежал1(,а,о,и) &.", .toRoom, .excludingCreature(self), .text(direction.whereTo))
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
                        act(message, .toCreature(creature), .excludingCreature(mount), .excludingCreature(rider), .text(direction.whereTo))
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
                        act(message, .toCreature(creature), .excludingCreature(self), .text(direction.whereTo))
                    } else if masterIsMountOrRider {
                        creature.runtimeFlags.remove(.follow)
                    }
                }
            }
        }
    }

    private func shouldShowMovement(to creature: Creature, leader: Creature) -> Bool {
        guard let creaturePreferenceFlags = creature.preferenceFlags else {
            // It's mobile not controlled by a player
            return true
        }
        guard creaturePreferenceFlags.contains(.hideTeamMovement) else { return true }
        return !isSameTeam(with: creature) ||
            self == leader ||
            (creature != leader && creature.following != leader)
    }
    
    private func arrivalVerb(_ index: Int) -> String {
        guard !isAffected(by: .fly) else {
            return "прилетел\(index)(,а,о,и)"
        }
        if let mobile = mobile {
            return mobile.movementType.arrivalVerb(index)
        } else {
            return MovementType.walk.arrivalVerb(index)
        }
    }
    
    private func leavingVerb(_ index: Int) -> String {
        guard !isAffected(by: .fly) else {
            return "улетел\(index)(,а,о,и)"
        }
        if let mobile = mobile {
            return mobile.movementType.leavingVerb(index)
        } else {
            return MovementType.walk.leavingVerb(index)
        }
    }
    
    private func sendCantGoThereMessage() {
        send("Увы, Вы не можете идти в этом направлении.")
    }

    private func sendNoRideInJungleMessage() {
        send("Густые заросли не позволяют проехать верхом.")
    }
    
    private func handleClosedDoor(exit: RoomExit) -> Bool {
        if exit.flags.contains(.closed) {
            if exit.flags.contains(.hidden) {
                sendCantGoThereMessage()
            } else {
                act("&1 закрыт&2.", .toCreature(self), .text(exit.type.nominative), .text(exit.type.adjunctiveEnd))
            }
            return true
        }
        return false
    }
    */
}

// MARK: - doFollow

extension Creature {
    func doFollow(context: CommandContext) {
        guard let creature = context.creature1 else {
            if let following = following {
                act("Вы следуете за 2т.", .toSleeping,
                    .toCreature(self), .excludingCreature(following))
            } else {
                send("Вы ни за кем не следуете.")
            }
            return
        }
        
        guard following != creature else {
            act("Вы уже следуете за 2т.", .toSleeping,
                .toCreature(self), .excludingCreature(creature))
            return
        }
        
        //guard !isCharmed() else {
        //    act("Вы хотите следовать только за 2т!", .toSleeping,
        //        .toCreature(self), .excludingCreature(following))
        //    return
        //}

        if creature == self {
            if !isFollowing {
                send("Вы уже ни за кем не следуете.")
            } else {
                stopFollowing()
            }
        } else {
            if isFollowing {
                stopFollowing()
            }
            follow(leader: creature, silent: false)
        }
    }
}
