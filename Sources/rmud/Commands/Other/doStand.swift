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
}

