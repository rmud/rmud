import Foundation

extension Creature {
    func doStand(context: CommandContext) {
        stand()
    }
    
    func stand() {
        guard position != .standing else {
            send("Вы уже стоите.")
            return
        }
        
        guard position == .sitting || position == .resting else {
            logError("stand(): \(nameNominative) is trying to stand from position \(position.rawValue)")
            return
        }

        let toActorDefaultMessage = { (isAllowed: Bool) -> String in
            switch self.position {
            case .resting:
                return isAllowed ?
                    "Вы прекратили отдыхать и поднялись на ноги." :
                    "Вы не смогли подняться на ноги."
            default:
                return isAllowed ?
                    "Вы встали на ноги." :
                    "Вы не смогли встать на ноги."
            }
        }
        
        let toRoomDefaultMessage = { (isAllowed: Bool) -> String in
            switch self.position {
            case .resting:
                return isAllowed ?
                    "1*и прекратил1(,а,о,и) отдыхать и поднял1(ся,ась,ось,ись) на ноги." :
                    "1*и не смог1(,ла,ло,ли) подняться на ноги."
            default:
                return isAllowed ?
                    "1*и встал1(,а,о,и) на ноги." :
                    "1*и не смог1(,ла,ло,ли) встать на ноги."
            }
        }

        let event = inRoom!.override(eventId: .stand)
        let toActor = event.toActor ?? toActorDefaultMessage(event.isAllowed)
        let toRoom = event.toRoomExcludingActor ??
            toRoomDefaultMessage(event.isAllowed)
        act(toActor, .to(self))
        act(toRoom, .toRoom, .excluding(self))
        guard event.isAllowed else { return }
        
        position = .standing
    }

    func doSleep(context: CommandContext) {
        if position == .standing {
            send("Вы легли и заснули.")
            act("1*и лег1(,ла,ло,ли) и заснул1(,а,о,и).",
                .toRoom, .excluding(self))
        } else {
            send("Вы заснули.")
            act("1*и заснул1(,а,о,и).",
                .toRoom, .excluding(self))
        }
        position = .sleeping
    }

    func doWake(context: CommandContext) {
        guard !isAffected(by: .sleep) else {
            act(spells.message(.sleep, "ПРОСНУТЬСЯ"), .toSleeping, .to(self))
            return
        }
        
        guard !isAwake else {
            send("Вы уже бодрствуете.")
            return
        }

        let event = inRoom!.override(eventId: .wake)
        let toActor = event.toActor ??
            (event.isAllowed ? "Вы проснулись." : "Вы не смогли проснуться.")
        let toRoom = event.toRoomExcludingActor ??
            (event.isAllowed ? "1*и проснул1(ся,ась,ось,ись)." : "")
        act(toActor, .toSleeping, .to(self))
        act(toRoom, .toRoom, .excluding(self))
        guard event.isAllowed else { return }
        
        position = .sitting
    }
    
    func doQuit(context: CommandContext) {
        guard !descriptors.isEmpty else { return }

        guard let player = player else {
            send("Вы не можете покинуть игру.")
            return
        }
        
        if context.subcommand != .quit {
            send("Чтобы выбросить всё и выйти из игры, наберите команду \"конец!\" полностью.\n" +
                "Чтобы сохранить вещи, Вам нужно уйти на \"постой\" в ближайшей таверне.")
        } else if player.noQuitTicsLeft > 0 && !isGodMode() {
            send("Вы слишком взволнованы и не можете покинуть игру!")
        } else if isAffected(by: .poison) && !isGodMode() {
            send("Вы отравлены и не можете покинуть игру!")
        } else {
            // perform_quit(ch);
            players.quitting.insert(self)
            runtimeFlags.insert(.suppressPrompt)
        }
    }
    
    func performQuit() {
        let player = self.player!

        let keepItems = isGodMode()
        
        send(keepItems
            ? "Вы покинули игру."
            : "Вы выбросили все, что у Вас было, и покинули игру.")
        act("1*и выш1(ел,ла,ло,ли) из игры.", .toRoom, .excluding(self))
        
        log("\(nameNominative) has left the game")
        logToMud("\(nameNominative) выходит из игры.", verbosity: .normal)
        
        
        for descriptor in networking.descriptors {
            if descriptor.creature == self {
                descriptor.state = .close
            }
        }
        
        extract(mode: keepItems ? .keepItems : .leaveItemsOnGround)
        player.scheduleForSaving()
        players.save()
    }
}
