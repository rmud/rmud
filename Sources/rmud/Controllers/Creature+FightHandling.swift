import Foundation

extension Creature {
    func startFighting(victim: Creature) -> Bool {
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
            
    func stopFighting() {
        guard isFighting else { return }
        fighting = nil

        guard let index = db.creaturesFighting
            .lastIndex(where: { creature in creature == self })
            else { return }
        db.creaturesFighting.remove(at: index)
    }
    
    func performViolence() {
        guard let fighting else { return }
        
        if position == .sitting && !isHeld() {
            send("\(bCyn())Вам следует встать на ноги!\(nNrm())")
        }
        
        attack(victim: fighting)
    }
    
    private func attack(victim: Creature) {
        hitOnce(victim: victim)
    }
    
    // (0%: will always miss) ... (100%: no strength penalty)
    func weaponEfficiencyPercent(for weapon: Item) -> Int {
        let strength = affectedStrength()
        let weaponWeight = weapon.weightWithContents()
        
        var actualStrength: Int
        
        switch weapon.wornPosition {
        case .wield:
            actualStrength = strength
        case .twoHand:
            actualStrength = strength * 2
        case .hold:
            actualStrength = strength / 2 + 2
        default:
            logError("ОШИБКА: weaponEfficiencyPercent: unknown weapon position")
            actualStrength = strength
        }

        let excessWeight = weaponWeight - actualStrength
        let penaltyPercents = excessWeight * 10
        
        return clamping(100 - penaltyPercents, to: 0...100)
    }
    
    private func hasLandedHit(with weapon: Item?) -> Bool {
        let attack = 0
        let defense = 0
        
        // 1...50 = miss, 51...100 = hit. 50% chance
        let isAttackThrowSuccesful =
            attack + Int.random(in: 1...100) > defense + 50
        
        let isWeaponThrowSuccesful = if let weapon {
            weaponEfficiencyPercent(for: weapon) >= Int.random(in: 1...100)
        } else { true }
        
        return isAttackThrowSuccesful && isWeaponThrowSuccesful
    }
    
    func hitOnce(victim: Creature) {
        let weaponItem = primaryWeapon()
        let hitType: HitType = if let weapon = weaponItem?.asWeapon() {
            weapon.weaponType.hitType
        } else { .hit }
        
        guard hasLandedHit(with: weaponItem) else {
            sendMissMessage(victim: victim, hitType: hitType)
            return
        }
        
        var damage = 0
        
        if isPlayer {
            damage += Int.random(in: 1...2)
        }
        
        damage += victim.damagePositionBonus(damage: damage)
        damage = max(1, damage)

        damage += 50
        
        performDamage(victim: victim, damage: damage)
    }
    
    private func performDamage(victim: Creature, damage: Int) {

        if damage > 0 && victim.position == .sleeping {
            victim.position = .sitting
            victim.send("Вы проснулись.")
            act("1*и проснул1(ся,ась,ось,ись).", .toRoom, .excluding(victim))
        }

        sendHitMessage(victim: victim, hitType: .hit, damage: damage)
        
        victim.hitPoints -= damage
        victim.updatePosition()
        
        if victim.isFighting && victim.position.isStunnedOrWorse {
            victim.stopFighting()
        }
    }
    
    func updatePosition() {
        guard position != .dead else { return }
        
        if hitPoints > 0 {
            if position.isStunnedOrWorse {
                send("Вы пришли в себя.")
                act("1*и приш1(ёл,ла,ло,ли) в себя.", .toRoom, .excluding(self))
            }
            return
        }
        
        if hitPoints < -10 {
            position = .dead
            act("1и мертв1(,а,о,ы)! R.I.P.", .toRoom, .excluding(self))
            send("Вы мертвы! R.I.P.")
            db.creaturesDying.append(self)
        } else if hitPoints < -3 {
            position = .dying
            send("Вы смертельно ранены и скоро умрете, если никто не поможет.")
            act("1*и смертельно ранен1(,а,о,ы) и скоро умр1(ет,ет,ет,ут), если 1(ему,ей,ему,им) не помогут.", .toRoom, .excluding(self))

        } else {
            position = .stunned
            send("Вы оглушены, но, вероятно, скоро придете в себя.")
            act("1*и оглушен1(,а,о,ы), но, вероятно, скоро прид1(ет,ет,ет,ут) в себя.", .toRoom, .excluding(self))
        }
    }
    
    func redirectAttentions() {
        guard let inRoom else { return }
        for creature in inRoom.creatures {
            guard creature.fighting == self else { continue }

            creature.stopFighting()
            
            guard let creatureRoom = creature.inRoom else { continue }
            for target in creatureRoom.creatures {
                guard target != self && target.fighting == creature else { continue }
                act("Вы переключили свое внимание на 2в.",
                    .toSleeping, .to(creature), .excluding(target)
                )
                guard creature.startFighting(victim: target) else { continue }
                break
            }
        }
    }
    
    func sendMissMessage(victim: Creature, hitType: HitType) {
        act("Вы попытались &1 2в, но промахнулись.", .toSleeping, .to(self), .excluding(victim), .text(hitType.indefinite), .text(hitType.past))

        act("1и попытал1(ся,ась,ось,ись) &1 ВАС, но промахнул1(ся,ась,ось,ись).", .toSleeping, .excluding(self), .to(victim), .text(hitType.indefinite), .text(hitType.past))

        act("1и попытал1(ся,ась,ось,ись) &1 2в, но промахнул1(ся,ась,ось,ись).", .toRoom, .excluding(self), .excluding(victim), .text(hitType.indefinite), .text(hitType.past))
    }
    
    func sendHitMessage(victim: Creature, hitType: HitType, damage: Int) {
        let hitForce = HitForce(damage: damage)
        
        act("\(bYel())\(hitForce.attacker)\(nNrm())", .toSleeping, .to(self), .excluding(victim), .text(hitType.indefinite), .text(hitType.past))

        act("\(victim.bRed())\(hitForce.victim)\(victim.nNrm())", .toSleeping, .excluding(self), .to(victim), .text(hitType.indefinite), .text(hitType.past))

        act(hitForce.room, .toRoom, .excluding(self), .excluding(victim), .text(hitType.indefinite), .text(hitType.past))

        let victimMaxHit = victim.affectedMaximumHitPoints()
        if damage > victimMaxHit / 4 {
            victim.send("\(victim.bRed())ЭТО БЫЛО ОЧЕНЬ БОЛЬНО!\(victim.nNrm())")
        }
        if damage > 0 && victim.hitPoints - damage < victimMaxHit / 5 {
            victim.send("\(victim.bRed())ВЫ ИСТЕКАЕТЕ КРОВЬЮ!\(victim.nNrm())")
        }
    }
}
