import Foundation

// Heartbeat is the main game pulse.
// Other pulses are being initiated from it.
// It's called each game pulse.
func heartbeat() throws {
    if (gameTime.gamePulse + UInt64(pulseMobileOffset)) % UInt64(pulseMobile) == 0 {
        for creature in db.creaturesInGame {
            creature.mobile?.mobileActivity()
        }
    }
    
    if gameTime.gamePulse % UInt64(pulseViolence) == 0 {
        for creature in db.creaturesFighting {
            creature.performViolence()
        }
    }
    
    if !players.quitting.isEmpty {
        players.quitting.forEach {
            $0.runtimeFlags.remove(.suppressPrompt)
            $0.performQuit()
        }
        players.quitting.removeAll(keepingCapacity: true)
    }
    if gameTime.gamePulse % GameTime.pulses(inSeconds: 60) == 0 { // each minute
        try gameTime.saveToDisk()
        accounts.save()
        players.save()
        
        checkDescriptorIdling()
    }
}

// Marks for disconnection idle descriptors except the ones
// in game (there's a different mechanism in place for handling them).
// Called once per minute!
private func checkDescriptorIdling() {
    for d in networking.descriptors {
        guard d.state != .playing && d.state != .close else {
            continue
        }
        d.idleTicsAtPrompt += 1
        let shouldDisconnect: Bool
        switch d.state {
        case .getCharset:
            shouldDisconnect = d.idleTicsAtPrompt > 1
        case .getAccountName, .accountPassword:
            shouldDisconnect = d.idleTicsAtPrompt > 3
        default:
            shouldDisconnect = d.idleTicsAtPrompt > 10
        }
        guard shouldDisconnect else { continue }
        d.echoOn()
        if d.state == .getCharset {
            d.send("Time is out, closing connection.")
        } else {
            d.send("Время истекло, соединение разорвано.")
        }
        d.state = .close
    }
}
