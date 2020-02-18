import Foundation

extension Creature {
    func handlePostponedMovement() {
        guard let direction = movementPath.first else { return }
        guard let inRoom = inRoom else { return }
        guard let toRoom = inRoom.exits[direction]?.toRoom() else {
            sendCantGoThereMessage()
            movementPath.removeAll()
            return
        }
        let pulsesNeeded = (inRoom.terrain.gamePulsesNeeded + toRoom.terrain.gamePulsesNeeded) / 2
        let pulsesPassed = gameTime.gamePulse - arrivedAtGamePulse
        guard pulsesPassed >= pulsesNeeded else {
            Scheduler.sharedInstance.schedule(
                afterGamePulses: pulsesNeeded - pulsesPassed,
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
