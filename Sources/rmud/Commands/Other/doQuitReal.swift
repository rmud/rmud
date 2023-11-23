extension Creature {
    func doQuitReal(context: CommandContext) {
        guard !descriptors.isEmpty else { return }

        guard let player else {
            send("Вы не можете покинуть игру.")
            return
        }
        
        if player.noQuitTicsLeft > 0 && !isGodMode() {
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
