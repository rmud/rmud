import Foundation

extension Creature {
    func handlePostponedMovement() {
        handlePostponedMovement(interactive: false)
    }

    func handlePostponedMovement(interactive: Bool) {
        guard let direction = movementPath.first else { return }
        guard let inRoom = inRoom else { return }
        guard let toRoom = inRoom.exits[direction]?.toRoom() else {
            sendCantGoThereMessage()
            movementPath.removeAll()
            return
        }
        // Unexplored areas can be travelled into only interactively.
        // Exception is when player attempts to travel without
        // waiting for timer expiration.
        // In both cases there should be no pre-planned path.
        if (!interactive && movementPathInitialRoom != inRoom.vnum) || movementPath.count >= 2 {
            if let player = controllingPlayer {
                guard player.preferenceFlags.contains(.goIntoUnknownRooms) || player.exploredRooms.contains(toRoom.vnum) else {
                    send("Дальше путь Вам незнаком.")
                    movementPath.removeAll()
                    return
                }
            }
        }
        let pulsesNeeded = (inRoom.terrain.gamePulsesNeeded + toRoom.terrain.gamePulsesNeeded) / 2
        let pulsesPassed = gameTime.gamePulse - arrivedAtGamePulse
        guard pulsesPassed >= pulsesNeeded else {
            scheduler.schedule(
                afterGamePulses: pulsesNeeded - pulsesPassed,
                handlerType: .movement,
                target: self,
                action: Creature.handlePostponedMovement)
            return
        }
        
        movementPath.removeFirst()
        teleportTo(room: toRoom)
        lookAtRoom(ignoreBrief: false)
    }

    private func sendCantGoThereMessage() {
        send("Увы, Вы не можете идти в этом направлении.")
    }
}
