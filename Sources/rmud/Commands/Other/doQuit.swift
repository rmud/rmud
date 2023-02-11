extension Creature {
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
