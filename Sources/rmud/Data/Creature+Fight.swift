import Foundation

extension Creature {
    func attackedBy() -> Creature? {
        return inRoom?.creatures.first { $0.fighting == self }
    }
    
    func isAttacked() -> Bool {
        return attackedBy() != nil
    }
    
    func primaryWeapon() -> Item? {
        for position in EquipmentPosition.primaryWeapon {
            if let item = equipment[position], item.isWeapon() {
                return item
            }
        }
        return nil
    }
    
    // Два свободных монстра всегда за одно, если только
    //они не дерутся друг с другом.
    //FIXME arilou: к сожалению, из-за этого монстры-агрессоры будут считать своими
    // монстров-защитников, которые дерутся на стороне игроков :(
    func isMobsFriendship(with victim: Creature) -> Bool {
        return isMobile && victim.isMobile &&
            fighting != victim && victim.fighting != self && // случай fighting == NULL учтён автоматически :)
            !hasPlayerMaster() && !victim.hasPlayerMaster()
    }
    
    // Общий враг - тоже объединяющий фактор
    func isSameEnemy(with victim: Creature) -> Bool {
        // бьёт того же, кого и ch или ch бьёт того, кто бьёт vict
        return (isFighting &&
                (fighting == victim.fighting || fighting!.fighting == victim)) ||
               (victim.isFighting && victim.fighting!.fighting == self) // бьёт того, кто бьёт self
    }
    
    func damagePositionBonus(damage: Int) -> Int {
        if !position.isAwake { return damage }
        else if position == .resting { return damage / 2 }
        else if position == .sitting { return damage / 4 }
        return 0
    }
    
    func totalAttack(target: Creature) -> Int {
        var attack = affectedAttack()
        
        if target.isHelpless() {
            attack += 40
        } else if target.position == .resting {
            attack += 30
        } else if target.position == .sitting {
            attack += 20
        }
        
        if canSee(target) {
            if !target.canSee(self) {
                if target.fighting == self {
                    attack += 20
                } else {
                    attack += 40
                }
            }
        } else {
            attack -= 40
        }
            
        return attack
    }
    
    func totalDefense(against attacker: Creature) -> Int {
        let defense = affectedDefense()
        
        return defense
    }
}
