import Foundation

extension Creature {
    
    func stopFighting() {
        
    }
    
    func redirectAttentions() {
        
    }

    func updatePosition() {
        guard position != .dead else {
            // No way back: victim's experience already given away
            return
        }
    
        if hitPoints > 0 {
            if position.isUnconscious {
                send("Вы пришли в себя.")
                act("1*и приш1(ел,ла,ло,ли) в себя.", .toRoom, .excludingCreature(self))
                position = .sitting
            }
            return
        }
    
        if let player = player, !position.isUnconscious {
            // Was conscious until now
            let _ = player.stopWatching()
        }
    
        let deadAtHitpoints: Int
        if isAffected(by: .delayDeath) {
            deadAtHitpoints = (2 * affectedMaximumHitPoints()) / 3 - 1
        } else {
            deadAtHitpoints = -10
        }
        if hitPoints <= deadAtHitpoints {
            position = .dead
        } else if hitPoints < -3 {
            position = .dying
        } else {
            position = .stunned
        }
    }
}
