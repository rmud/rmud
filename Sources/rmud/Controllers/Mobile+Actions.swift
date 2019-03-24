import Foundation

extension Mobile {
    func checkForTargets() {
//        guard creature.position == .standing || creature.position == defaultPosition else { return }
//
//        // aggressive mobs
//        if !flags.isDisjoint(with: MobileFlags.allMobAgro.union(.xenophobiac)) &&
//                !flags.contains(.agroSlow) { //  !(room->flagged(ROOM_PEACEFUL) && MOB_TIMER(ch)))
//            var foundCount = 0
//            var victim: Creature?
//            for tmp in creature.inRoom.people {
//                if (tmp.isMobile && !tmp.mobile!.flags.contains(.xenophobiac)) ||
//                        creature == tmp || !creature.canSee(tmp) ||
//                        (tmp.isPlayer && tmp.preferenceFlags.contains(.nohassle)) {
//                    continue
//                }
//                if tmp.runtimeFlags.contains(.hiding) && !creature.isAffected(by: .senseLife) {
//                    continue
//                }
//                if creature->mob_aggr_vict(tmp) && can_attack(ch, tmp) {
//                    foundCount += 1
//                    if Random.uniformInt(1...foundCount) == 1 {
//                        victim = tmp
//                    }
//                }
//            }
//            if let victim = victim {
//                creature.mob_attack(victim: victim)
//                return
//            }
//        }
    
//        creature.mob_revenge_check(ch)
    }
}
