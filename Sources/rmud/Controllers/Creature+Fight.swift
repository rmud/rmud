import Foundation

extension Creature {
    func startFight(victim: Creature) -> Bool {
        guard fighting == nil else { return true }

        guard victim != self else {
            send("Здесь, вероятно, следует засмеяться?")
            return false
        }
        
        guard !victim.isGodMode() else {
            send("Ваше благоразумие подсказало Вам, что лучше этого не делать.")
            return false
        }
        
        if let inRoom = inRoom, inRoom.flags.contains(.peaceful) {
            send("Здесь так тихо и спокойно, что Вам не хочется начинать бой.")
            return false
        }
        
        fighting = victim
        db.creaturesFighting.append(self)
        
        if victim.fighting == nil {
            victim.fighting = self
            db.creaturesFighting.append(victim)
        }
        
        return true
    }
    
    func performViolence() {
        guard let fighting = fighting else {
            logError("performViolence(): creature \(nameNominative) has no enemy")
            return
        }
        
        if position == .sitting && !isHeld() {
            send("\(bCyn())Вам следует встать на ноги!\(nNrm())")
        }
        
        attack(victim: fighting)
    }
    
    private func attack(victim: Creature) {
        hitOnce(victim: victim)
    }
    
    func hitOnce(victim: Creature) {
        let attack = 0
        let defense = 0
        
        let didHit = attack + Random.uniformInt(1...100) > defense + 50
        guard didHit else {
            sendMissMessage(victim: victim, hitType: .hit)
            return
        }
        
        var damage = 0
        
        if isPlayer {
            damage += Random.uniformInt(1...2)
        }
        
        damage += victim.damagePositionBonus(damage: damage)
        damage = max(1, damage)
        
        performDamage(victim: victim, damage: damage)
    }
    
    private func performDamage(victim: Creature, damage: Int) {

        if damage > 0 && victim.position == .sleeping {
            victim.position = .sitting
            victim.send("Вы проснулись.")
            act("1*и проснул1(ся,ась,ось,ись).", .toRoom, .excludingCreature(victim))
        }

        sendHitMessage(victim: victim, hitType: .hit, damage: damage)
        
        victim.hitPoints -= damage
        victim.updatePosition()
    }
    
    func updatePosition() {
        guard position != .dead else { return }
        
        if hitPoints > 0 {
            if position.isStunnedOrWorse {
                send("Вы пришли в себя.")
                act("1*и приш1(ел,ла,ло,ли) в себя.", .toRoom, .excludingCreature(self))
            }
            return
        }
        
        if hitPoints < -10 {
            position = .dead
            act("1и мертв1(,а,о,ы)! R.I.P.", .toRoom, .excludingCreature(self))
            send("Вы мертвы! R.I.P.")
        } else if hitPoints < -3 {
            position = .dying
            send("Вы смертельно ранены и скоро умрете, если никто не поможет.")
            act("1*и смертельно ранен1(,а,о,ы) и скоро умр1(ет,ет,ет,ут), если 1(ему,ей,ему,им) не помогут.", .toRoom, .excludingCreature(self))

        } else {
            position = .stunned
            send("Вы оглушены, но, вероятно, скоро придете в себя.")
            act("1*и оглушен1(,а,о,ы), но, вероятно, скоро прид1(ет,ет,ет,ут) в себя.", .toRoom, .excludingCreature(self))
        }
    }
            
    func stopFighting() {
        
    }
    
    func redirectAttentions() {
        
    }
    
    func sendMissMessage(victim: Creature, hitType: HitType) {
        act("Вы попытались &1 2в, но промахнулись.", .toSleeping, .toCreature(self), .excludingCreature(victim), .text(hitType.indefinite), .text(hitType.past))

        act("1и попытал1(ся,ась,ось,ись) &1 ВАС, но промахнул1(ся,ась,ось,ись).", .toSleeping, .excludingCreature(self), .toCreature(victim), .text(hitType.indefinite), .text(hitType.past))

        act("1и попытал1(ся,ась,ось,ись) &1 2в, но промахнул1(ся,ась,ось,ись).", .toRoom, .excludingCreature(self), .excludingCreature(victim), .text(hitType.indefinite), .text(hitType.past))
    }
    
    func sendHitMessage(victim: Creature, hitType: HitType, damage: Int) {
        let hitForce = HitForce(damage: damage)
        
        act("\(bYel())\(hitForce.attacker)\(nNrm())", .toSleeping, .toCreature(self), .excludingCreature(victim), .text(hitType.indefinite), .text(hitType.past))

        act("\(victim.bRed())\(hitForce.victim)\(victim.nNrm())", .toSleeping, .excludingCreature(self), .toCreature(victim), .text(hitType.indefinite), .text(hitType.past))

        act(hitForce.room, .toRoom, .excludingCreature(self), .excludingCreature(victim), .text(hitType.indefinite), .text(hitType.past))

        let victimMaxHit = victim.affectedMaximumHitPoints()
        if damage > victimMaxHit / 4 {
            victim.send("\(victim.bRed())ЭТО БЫЛО ОЧЕНЬ БОЛЬНО!\(victim.nNrm())")
        }
        if damage > 0 && victim.hitPoints - damage < victimMaxHit / 5 {
            victim.send("\(victim.bRed())ВЫ ИСТЕКАЕТЕ КРОВЬЮ!\(victim.nNrm())")
        }
    }
}
