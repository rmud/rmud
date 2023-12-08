extension Creature {
    func awardExperienceToAttackers() {
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
            let coef = gainer.experienceGainCoef(gainersMinLevel: Int(minLevel))
            let gain = Int(
                (
                    Double(experience * coef) / Double(totalCoef)
                ).rounded()
            )
            gainer.gainExperience(gain)
        }
    }
    
    func gainExperience(_ gain: Int) {
        guard gain != 0 else {
            send("Вы не получили никакого опыта.")
            return
        }
        experience += gain
        if gain > 0 {
            act("Вы получили # очк#(о,а,ов) опыта.",
                .toSleeping, .to(self), .number(gain))
        } else {
            act("Вы потеряли # очк#(о,а,ов) опыта.",
                .toSleeping, .to(self), .number(-gain))
        }
        adjustLevel()
    }

    private func experienceGainCoef(gainersMinLevel: Int) -> Int {
        return Int(level) - Int(gainersMinLevel) + 3
    }
}
