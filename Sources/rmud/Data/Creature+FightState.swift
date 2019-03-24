import Foundation

extension Creature {
    // Одна "команда" - либо одна группа (same_group()),
    // либо одино из существ очаровано и его хозяин в одной
    // команде с другим сушеством.
    func isSameTeam(with victim: Creature) -> Bool {
        return areWalkingTogether(with: victim) ||
            isMobsFriendship(with: victim) ||
            isSameEnemy(with: victim)
    }
    
    // два существа - в одной группе
    // два монстра, если они не очарованы,
    // всегда считаются в одной группе
    // FIXME: а как же лошади?
    func isSameGroup(with victim: Creature) -> Bool {
        guard self != victim else { return true }
        // монсры В ПРИНЦИПЕ не бывают в одной группе - пока что
        //  if (ch->isMob() || vict->isMob()) // && !ch->master && !vict->master)
        //    return false;
        if let player = player, player.flags.contains(.group),
                let victimPlayer = victim.player, victimPlayer.flags.contains(.group) {
            return victim.master == self || master == victim || (master != nil && master == victim.master)
        }
    
        return (victim == master && isCharmed()) || (self == victim.master && victim.isCharmed())
    }
    
    // Это same_group() + те, кто за ними следуют (в т.ч. чармисы).
    func areWalkingTogether(with victim: Creature) -> Bool {
        return isSameGroup(with: victim) ||
            // arilou: в проверках ниже вызываю walk_together(), а не same_group()
            // чтобы обработался случай двух очарованных существ с РАЗНЫМИ хозяевами
            (victim.master != nil && victim.master!.areWalkingTogether(with: self)) ||
            (master != nil && master!.areWalkingTogether(with: victim))
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
}
