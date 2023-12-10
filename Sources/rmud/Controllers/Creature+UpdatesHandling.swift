import Foundation

extension Creature {
    func updateOnTick() {
        if position.isStunnedOrBetter {
            if isMobile || isConnected {
                let maximumHitPoints = affectedMaximumHitPoints()
                if hitPoints < maximumHitPoints {
                    hitPoints = min(hitPoints + hitPointsGain(), maximumHitPoints)
                }
                if !isFighting && hitPoints == maximumHitPoints {
                    lastBattleParticipants.removeAll()
                }
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
