extension Creature {
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
}

