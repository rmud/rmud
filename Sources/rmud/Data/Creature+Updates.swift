import Foundation

extension Creature {
    func hitPointsGain() -> Int {
        var gain = 0
        if isMobile {
            gain += mobileHitPointsGain()
        } else {
            let health = 100
            let bonus = 0
            gain += classId.info.maxHitPerLevel * health * (100 + bonus) / 10000
        }

        if let room = inRoom, room.flags.contains(.recuperate) {
            gain *= 2
        }

        if isPlayer {
            // make it less pain from any one of it, but cumulative
            if hunger == 0 { gain /= 2 }
            if thirst == 0 { gain /= 2 }
        }
        
        return max(1, gain)
    }
    
    private func mobileHitPointsGain() -> Int {
        let maxHit = affectedMaximumHitPoints()
        if isFighting {
            return max((maxHit * 2) / 100, Int(level))
        } else if position == .standing || position == .sitting {
            return max((maxHit * 5) / 100, Int(level) * 2)
        } else if position == .resting {
            return max((maxHit * 10) / 100, Int(level) * 3)
        } else if position == .sleeping {
            return max((maxHit * 20) / 100, Int(level) * 4)
        }
        return min(maxHit, Int(level))
    }
}
