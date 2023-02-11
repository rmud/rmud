extension Creature {
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
}

