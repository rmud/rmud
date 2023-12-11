extension Creature {
    func adjustLevel() {
        guard isPlayer else { return }
        
        while level < maximumMortalLevel && experience >= classId.info.experienceForLevel(Int(level) + 1) {
            advanceLevel()
            act("&1Вы получили уровень!&2", .toSleeping, .to(self), .text(bWht()), .text(nNrm()))
        }
        while level > 1 && experience < classId.info.experienceForLevel(Int(level)) - levelLossBuffer() {
            loseLevel()
            act("&1Вы потеряли уровень!&2", .toSleeping, .to(self), .text(bWht()), .text(nNrm()))
        }
    }
    
    private func advanceLevel() {
        guard let player = player else { return }
        
        if level >= 1 {
            if let gain = player.hitPointGains[validating: Int(level)] {
                realMaximumHitPoints += Int(gain)
            } else {
                while player.hitPointGains.count < level {
                    fatalError("Player missed some gains before level \(level)")
                    //assertionFailure()
                    //player.hitPointGains.append(0)
                }
                let gain = classId.info.hitPointGain.roll()
                player.hitPointGains.append(UInt8(gain))
                realMaximumHitPoints += gain
            }
        }

        level += 1
        
        log("\(nameNominative) advances to level \(level)")
        logToMud("\(nameNominative) получает уровень \(level).", verbosity: .brief)

        if level == 3 && !player.flags.contains(.rolled) {
            rollRealAbilities()
            player.flags.insert(.rolled)
            log("New statistics: strength \(realStrength), dexterity \(realDexterity), constitution \(realConstitution), intelligence: \(realIntelligence), wisdom: \(realWisdom), charisma: \(realCharisma)")
            logToMud("Статистики: сила \(realStrength), ловкость \(realDexterity), телосложение (\(realConstitution), разум: \(realIntelligence), мудрость: \(realWisdom), обаяние: \(realCharisma)", verbosity: .brief)
        }
        
        //save_char_safe(ch, RENT_CRASH);
        player.scheduleForSaving()
        players.save()
    }
    
    private func levelLossBuffer() -> Int {
        guard level > 1 else { return 0 }
        return (classId.info.experienceForLevel(Int(level)) -
            classId.info.experienceForLevel(Int(level) - 1)) / 10
    }
    
    private func loseLevel() {
        guard let player = player else { return }

        let hitpointsLoss: Int
        if let loss = player.hitPointGains[validating: Int(level - 1)] {
            hitpointsLoss = Int(loss)
        } else {
            hitpointsLoss = classId.info.maxHitPerLevel
            log("\(nameNominative) hasn't got hitpoint gains logged")
            logToMud("У персонажа \(nameNominative) не запомнены значения жизни для уровней", verbosity: .brief)
        }

        level -= 1
        
        realMaximumHitPoints -= hitpointsLoss
        if realMaximumHitPoints < 1 {
            realMaximumHitPoints = 1
        }
        let affectedHitPoints = affectedMaximumHitPoints()
        if hitPoints > affectedHitPoints {
            hitPoints = affectedHitPoints
        }
        
        // FIXME
        //for (circle = max_circle(ch); circle >= 1; --circle)
        //for (slot = CH_SLOT_AVAIL(ch, circle) + 1; slot <= 18; ++slot) {
        //    CH_SLOT(ch, circle, slot) = 0;
        //    REMOVE_BIT_AR(CH_SLOTSTATE(ch), 18 * (circle - 1) + slot);
        //}
        
        log("\(nameNominative) descends to level \(level)")
        logToMud("Персонаж \(nameNominative) спускается на уровень \(level).", verbosity: .brief)
        
        //save_char_safe(ch, RENT_CRASH);
        player.scheduleForSaving()
        players.save()
    }
}
