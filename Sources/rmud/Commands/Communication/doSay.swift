extension Creature {
    func doSay(context: CommandContext) {
        guard !context.argument1.isEmpty else {
            send("Что Вы хотите произнести?")
            return
        }
        guard race.canTalk else {
            send("Вы не умеете разговаривать.")
            return
        }
        guard !isAffected(by: .silence) else {
            act(spells.message(.silence, "МОЛЧАНИЕ"),
                .to(self))
            act("1*и беззвучно пошевелил1(,а,о,и) губами.", .toRoom,
                .excluding(self))
            return
        }
        act("1и произнес1(,ла,ло,ли): \"&\"", .toRoom,
            .excluding(self), .text(context.argument1))
        act("Вы произнесли: \"&\"",
            .to(self), .text(context.argument1))
    }
}
