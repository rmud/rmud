import Foundation

// MARK: - doSay

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
                .toCreature(self))
            act("1*и беззвучно пошевелил1(,а,о,и) губами.", .toRoom,
                .excludingCreature(self))
            return
        }
        act("1и произнес1(,ла,ло,ли): \"&\"", .toRoom,
            .excludingCreature(self), .text(context.argument1))
        act("Вы произнесли: \"&\"",
            .toCreature(self), .text(context.argument1))
    }
}

// MARK: - doOrder

extension Creature {
    func doOrder(context: CommandContext) {
        let creatures = context.creatures1
        let command = context.argument2

        guard !creatures.isEmpty && !command.isEmpty else {
            send("Кому Вы хотите приказать и что?")
            return
        }
        
        guard !isAffected(by: .silence) else {
            act(spells.message(.silence, "МОЛЧАНИЕ"), .toCreature(self))
            return
        }

        //let shallAbide: (Creature) -> Bool = { creature in
        //    return creature.master == self && creature.isCharmed()
        //}
        
        if creatures.count == 1, let creature = creatures.first {
            guard creature != self else {
                send("Здесь, вероятно, следует засмеяться?")
                return
            }
            act("Вы приказали 2д: \"&\"",
                .toCreature(self), .excludingCreature(creature), .text(command))
            act("1и приказал1(,а,о,и) Вам: \"&\"", .toSleeping,
                .excludingCreature(self), .toCreature(creature), .text(command))
            act("1и отдал1(,а,о,и) 2д приказ.", .toRoom,
                .excludingCreature(self), .excludingCreature(creature))
            //guard shallAbide(creature) else {
            //    act("1и проигнорировал1(,а,о,и) приказ.", .toRoom,
            //        .excludingCreature(creature))
            //    return
            //}
            creature.interpretCommand(command)
        } else {
            act("Вы приказали: \"&\"",
                .toCreature(self), .text(command))
            act("1и отдал1(,а,о,и) приказ.", .toRoom,
                .excludingCreature(self), .text(command))
            
            creatures.forEach { creature in
                guard creature != self else { return }
                //guard shallAbide(creature) else { return }
                creature.interpretCommand(command)
            }
        }
    }
}
