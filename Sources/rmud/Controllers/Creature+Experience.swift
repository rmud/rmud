import Foundation

extension Creature {
    func awardExperienceToAttackers() {
        guard let mobile else { return }
        guard let inRoom else { return }
        let gainers = inRoom.creatures.filter { creature in
            lastBattleParticipants.contains(creature.uid)
        }
        
        let minLevel = gainers.min { creature1, creature2 in
            creature1.level < creature2.level
        }?.level ?? 1
        
        let coefs = gainers.map { gainer in
            gainer.experienceGainCoef(gainersMinLevel: Int(minLevel))
        }
        
        let totalCoef = coefs.reduce(0, +)
        
        for gainer in gainers {
            guard let gainerPlayer = gainer.player else { continue }
            
            let coef = gainer.experienceGainCoef(gainersMinLevel: Int(minLevel))
            let gain = Int(
                (
                    Double(experience * coef) / Double(totalCoef)
                ).rounded()
            )
            let limitedGain = gainer.expLimitedForRepeatedKills(gain: gain, vnum: mobile.vnum)
            gainer.gainExperience(limitedGain, withSafetyLimits: true)
            
            gainerPlayer.killedMobVnumsAtTimestamps[
                mobile.vnum, default: []
            ].append(gameTime.gamePulse)
        }
    }
    
    func gainExperience(_ initialGain: Int, withSafetyLimits: Bool) {
        var gain = initialGain

        if withSafetyLimits {
            if gain > 0 {
                gain = expCappedByLevel(gain: gain)
            } else if gain < 0 {
                gain = expPreventLosingMultipleLevels(gain: gain)
            }
        }
        
        guard gain != 0 else {
            send("Вы не получили никакого опыта.")
            return
        }
        if gain > 0 {
            act("Вы получили # очк#(о,а,ов) опыта.",
                .toSleeping, .to(self), .number(gain))
        } else {
            act("Вы потеряли # очк#(о,а,ов) опыта.",
                .toSleeping, .to(self), .number(-gain))
        }

        experience = max(experience + gain, 0)
        adjustLevel()
        
        player?.scheduleForSaving()
    }
    
    private func expLimitedForRepeatedKills(gain: Int, vnum: Int) -> Int {
        guard gain > 0 else { return gain }
        guard let player else { return gain }
        
        let kills = player.killedMobVnumsAtTimestamps[vnum] ?? []
        let recentKills = kills.filter { gainGamePulse in
            let pulsesAgo = gameTime.gamePulse - gainGamePulse
            return pulsesAgo <= Constants.expForRepeatedKillsUnmaxPeriodPulses
        }
        
        let recentKillsCount = recentKills.count
        
        if kills.count != recentKillsCount {
            if recentKills.isEmpty {
                player.killedMobVnumsAtTimestamps.removeValue(forKey: vnum)
            } else {
                player.killedMobVnumsAtTimestamps[vnum] = recentKills
            }
        }
        
        let adjustedGain = Double(gain) * pow(0.9, Double(recentKillsCount))
        return Int(adjustedGain.rounded())
    }
    
    private func expPreventLosingMultipleLevels(gain: Int) -> Int {
        let expFromPreviousToCurrentLevel: Int
        if level > 1 {
            let currentLevelExp = classId.info.experienceForLevel(Int(level))
            let previousLevelExp = classId.info.experienceForLevel(Int(level) - 1)
            expFromPreviousToCurrentLevel = currentLevelExp - previousLevelExp
        } else {
            expFromPreviousToCurrentLevel = 0
        }
        return max(-expFromPreviousToCurrentLevel, gain)
    }
    
    private func expCappedByLevel(gain: Int) -> Int {
        let maxGain = balance.mobileExperience(level: Int(level))
        return min(gain, maxGain)
    }

    private func experienceGainCoef(gainersMinLevel: Int) -> Int {
        return Int(level) - Int(gainersMinLevel) + 3
    }
}
