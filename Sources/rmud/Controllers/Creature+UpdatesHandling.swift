import Foundation

extension Creature {
    func updateOnTick() {
        if position.isStunnedOrBetter {
            if isMobile || isConnected {
                hitPoints = min(
                    hitPoints + hitPointsGain(), affectedMaximumHitPoints()
                )
            }
            if position == .stunned {
                updatePosition()
            }
        } else if position == .dying {
            if isPlayer || isAttacked() {
                hitPoints -= 1
                updatePosition()
            }
        }
    }
}
