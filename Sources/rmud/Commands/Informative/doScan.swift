extension Creature {
    func doScan(context: CommandContext) {
        guard !isAffected(by: .blindness) else {
            act(spells.message(.blindness, "СЛЕП"), .to(self))
            return
        }
        
        guard let room = inRoom else {
            send(messages.noRoom)
            return
        }

        let holylight = { self.preferenceFlags?.contains(.holylight) ?? false }

        var found = false
        for direction in Direction.allDirectionsOrdered {
            guard let exit = room.exits[direction] else { continue }
            
            let isHiddenExit = exit.flags.contains(.hidden) && !holylight()
            if (isHiddenExit || exit.toRoom() == nil) && exit.description.isEmpty {
                continue
            }
            
            found = true
            // FIXME: spins
            look(inDirection: direction)
        }
        if !found {
            send("Вы не обнаружили ничего особенного.")
        }
    }
}
