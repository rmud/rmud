import Foundation

extension Room {
    // Warns agro mobiles about chars approaching and makes them attack

    func warnMobiles() {
        for creature in creatures {
            if creature.isPlayer || creature.isLagged || creature.isFighting || !creature.isAwake || creature.isHeld() || creature.isAffected(by: .blindness) {
                continue
            }
            
            // If ch is resting, get up and wait until his time
            if let mobile = creature.mobile,
                    creature.position == .resting && creature.position != mobile.defaultPosition
            {
                for victim in creatures {
                    guard !victim.isMobile else { continue }
                    if creature.canSee(victim) &&
                        (!victim.runtimeFlags.contains(.hiding) || creature.isAffected(by: .senseLife) ||
                            victim.hasDetectableItems()) {
                        //TODO добавить бы ещё проверку на то, что без игрока света нет,
                        //а с ним стало светло.
                        creature.stand()
                        break
                    }
                }
                continue
            }
            
            if !creature.isCharmed() {
                creature.mobile?.checkForTargets()
            }
        }
    }
}
